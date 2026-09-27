import Foundation
import Observation

/// Uma pergunta na fila do check-in, com o ramo a que pertence.
struct Passo: Identifiable, Equatable, Sendable {
    let sintoma: String
    let rotuloDoRamo: String
    let pergunta: Pergunta
    var id: String { pergunta.campo }
}

/// A lógica do check-in, fora da tela: que perguntas aparecem, o rascunho, o envio.
///
/// Regras que moram aqui (docs/BRIEFING-E-DCM.md §2):
/// - a árvore vem do servidor; o app não tem pergunta embarcada;
/// - cada toque vai para o rascunho no disco antes de qualquer coisa (inviolável 5);
/// - a sessão é ABERTA no primeiro toque, com a chave de idempotência do rascunho. Assim,
///   quem começa e não termina aparece para a equipe como "não terminado" pela varredura
///   do servidor — silêncio não é verde (lei 3). O web só abre a sessão no fim, e por isso
///   o abandono nunca chega ao painel; ver docs/CONTORNOS.md, D-01;
/// - "chegou à equipe" só depois de o servidor confirmar.
///
/// Dois modos. O DIÁRIO pergunta os 5 sintomas e é o check-in do dia. O REGISTRO é o
/// relato avulso ("senti febre agora"): a pessoa escolhe os sintomas, a porta de cada um
/// já vale "sim", e só os detalhes aparecem. Os dois viram sessão no servidor, com o
/// mesmo envio, a mesma orientação e o mesmo fechamento.
@MainActor
@Observable
final class CheckinStore {
    typealias Modo = RascunhoDoCheckin.Modo

    enum Fase: Equatable {
        case carregando
        /// Só no registro: "O que você está sentindo?"
        case escolhendo
        case erroAoCarregar(String)
        case respondendo
        case enviando
        case erroAoEnviar(String)
        case concluido(RetornoDoCheckin)
    }

    private(set) var fase: Fase = .carregando
    private(set) var arvore: ArvoreDeTriagem?
    private(set) var rascunho = RascunhoDoCheckin.novo()
    /// Posição na fila de passos visíveis.
    private(set) var indice = 0

    let modo: Modo
    private let api: ClienteAPI
    private var abrindoSessao: Task<String?, Never>?
    /// Avisa quem abriu o check-in (Hoje, widget) que o dia foi respondido.
    var aoConcluir: (@MainActor (RetornoDoCheckin) -> Void)?

    init(modo: Modo = .diario, api: ClienteAPI = .compartilhado) {
        self.modo = modo
        self.api = api
    }

    // MARK: Fila

    var passos: [Passo] {
        guard let arvore else { return [] }
        let fila = Self.passosVisiveis(arvore: arvore, respostas: rascunho.respostas)
        guard modo == .registro else { return fila }
        // Registro: só os sintomas escolhidos, e sem a porta (a escolha já respondeu "sim").
        let escolhidos = Set(rascunho.sintomasEscolhidos ?? [])
        let portas = Set(arvore.sintomas.map(\.porta.campo))
        return fila.filter { escolhidos.contains($0.sintoma) && !portas.contains($0.pergunta.campo) }
    }

    /// Sintomas para a tela de escolha do registro, na ordem da árvore.
    var ramos: [Ramo] { arvore?.sintomas ?? [] }

    var passoAtual: Passo? {
        let p = passos
        return p.indices.contains(indice) ? p[indice] : nil
    }

    var respostaAtual: Valor? {
        passoAtual.flatMap { rascunho.respostas[$0.pergunta.campo] }
    }

    /// A pergunta-porta sempre aparece; o detalhe só se a resposta da qual depende bate.
    nonisolated static func passosVisiveis(arvore: ArvoreDeTriagem, respostas: [String: Valor]) -> [Passo] {
        var fila: [Passo] = []
        for ramo in arvore.sintomas {
            fila.append(Passo(sintoma: ramo.sintoma, rotuloDoRamo: ramo.rotulo, pergunta: ramo.porta))
            for detalhe in ramo.detalhes {
                if let dep = detalhe.dependeDe, respostas[dep.campo] != dep.valor { continue }
                fila.append(Passo(sintoma: ramo.sintoma, rotuloDoRamo: ramo.rotulo, pergunta: detalhe))
            }
        }
        return fila
    }

    /// Respostas de perguntas que deixaram de aparecer (a pessoa voltou e trocou "sim" por
    /// "não") saem do envio. Mandar detalhe de um ramo fechado seria dado falso.
    nonisolated static func podar(respostas: [String: Valor], arvore: ArvoreDeTriagem) -> [String: Valor] {
        var atual = respostas
        while true {
            let visiveis = Set(passosVisiveis(arvore: arvore, respostas: atual).map(\.pergunta.campo))
            let podadas = atual.filter { visiveis.contains($0.key) }
            if podadas.count == atual.count { return podadas }
            atual = podadas
        }
    }

    /// O corpo do envio: respostas visíveis, agrupadas por sintoma, na ordem da árvore.
    nonisolated static func corpoDoEnvio(sessaoId: String, arvore: ArvoreDeTriagem, respostas: [String: Valor]) -> EnvioDeRespostas {
        let fila = passosVisiveis(arvore: arvore, respostas: respostas)
        var porSintoma: [EnvioDeRespostas.PorSintoma] = []
        for ramo in arvore.sintomas {
            let campos = fila.filter { $0.sintoma == ramo.sintoma }.compactMap { passo -> EnvioDeRespostas.RespostaDeCampo? in
                guard let valor = respostas[passo.pergunta.campo] else { return nil }
                return EnvioDeRespostas.RespostaDeCampo(campo: passo.pergunta.campo, valor: valor)
            }
            if !campos.isEmpty { porSintoma.append(.init(sintoma: ramo.sintoma, respostas: campos)) }
        }
        return EnvioDeRespostas(sessaoId: sessaoId, sintomas: porSintoma)
    }

    // MARK: Ciclo

    func carregar() async {
        fase = .carregando
        do {
            let arvore: ArvoreDeTriagem = try await api.obter("/triagem/arvore")
            self.arvore = arvore
            if let guardado = RascunhoDoCheckin.carregar(modo) {
                rascunho = guardado
                rascunho.respostas = Self.podar(respostas: guardado.respostas, arvore: arvore)
            }
            if modo == .registro, (rascunho.sintomasEscolhidos ?? []).isEmpty {
                fase = .escolhendo
                return
            }
            // Retoma na primeira pergunta ainda sem resposta.
            let fila = passos
            indice = fila.firstIndex { rascunho.respostas[$0.pergunta.campo] == nil } ?? max(fila.count - 1, 0)
            fase = fila.isEmpty ? .erroAoCarregar("Nenhuma pergunta disponível agora. Tente de novo em alguns instantes.") : .respondendo
        } catch let e as ErroDaAPI {
            fase = .erroAoCarregar(e.mensagem)
        } catch {
            fase = .erroAoCarregar("As perguntas de hoje não carregaram. Tente de novo em instantes.")
        }
    }

    /// Grava a resposta, poda o que deixou de valer, abre a sessão (uma vez) e avança.
    /// Devolve `true` quando era a última pergunta e o envio começou.
    @discardableResult
    func responder(_ valor: Valor) async -> Bool {
        guard let arvore, let passo = passoAtual else { return false }
        rascunho.respostas[passo.pergunta.campo] = valor
        rascunho.respostas = Self.podar(respostas: rascunho.respostas, arvore: arvore)
        rascunho.guardar(modo)
        garantirSessaoAberta()

        let fila = passos
        let posicao = fila.firstIndex { $0.id == passo.id } ?? indice
        if posicao + 1 < fila.count {
            indice = posicao + 1
            return false
        }
        await enviar()
        return true
    }

    func voltar() -> Bool {
        guard indice > 0 else {
            // No registro, voltar da primeira pergunta é voltar à escolha de sintomas.
            if modo == .registro {
                fase = .escolhendo
                return true
            }
            return false
        }
        indice -= 1
        return true
    }

    // MARK: Registro avulso

    /// "O que você está sentindo?" → a porta de cada sintoma escolhido vale "sim"; a dos
    /// outros sai do rascunho (a pessoa pode ter desmarcado ao voltar).
    func escolher(_ sintomas: [String]) {
        guard let arvore, !sintomas.isEmpty else { return }
        var respostas = rascunho.respostas
        for ramo in arvore.sintomas {
            if sintomas.contains(ramo.sintoma) {
                respostas[ramo.porta.campo] = .booleano(true)
            } else {
                respostas[ramo.porta.campo] = nil
            }
        }
        rascunho.sintomasEscolhidos = sintomas
        rascunho.respostas = Self.podar(respostas: respostas, arvore: arvore)
        rascunho.guardar(modo)
        let fila = passos
        indice = fila.firstIndex { rascunho.respostas[$0.pergunta.campo] == nil } ?? 0
        fase = fila.isEmpty ? .escolhendo : .respondendo
    }

    // MARK: Envio

    /// Abre a sessão em segundo plano, uma vez. Falhar aqui não trava a pessoa: o envio
    /// tenta de novo com a mesma chave.
    private func garantirSessaoAberta() {
        guard rascunho.sessaoId == nil, abrindoSessao == nil else { return }
        let chave = rascunho.chaveDeIdempotencia
        abrindoSessao = Task { [api] in
            struct Corpo: Encodable, Sendable { let chaveDeIdempotencia: String }
            let aberta: SessaoAberta? = try? await api.enviar("/triagem/sessoes", corpo: Corpo(chaveDeIdempotencia: chave))
            return aberta?.sessaoId
        }
        Task {
            let id = await abrindoSessao?.value
            abrindoSessao = nil
            if let id, rascunho.chaveDeIdempotencia == chave {
                rascunho.sessaoId = id
                rascunho.guardar(modo)
            }
        }
    }

    private func sessaoId() async throws -> String {
        if let pendente = abrindoSessao, let id = await pendente.value {
            rascunho.sessaoId = id
        }
        if let id = rascunho.sessaoId { return id }
        struct Corpo: Encodable, Sendable { let chaveDeIdempotencia: String }
        let aberta: SessaoAberta = try await api.enviar("/triagem/sessoes", corpo: Corpo(chaveDeIdempotencia: rascunho.chaveDeIdempotencia))
        rascunho.sessaoId = aberta.sessaoId
        rascunho.guardar(modo)
        return aberta.sessaoId
    }

    func enviar() async {
        guard let arvore else { return }
        fase = .enviando
        do {
            let retorno = try await enviarUmaVez(arvore: arvore)
            concluir(retorno)
        } catch ErroDaAPI.conflito {
            // A sessão não está mais em andamento: ou este mesmo envio já foi aceito (a
            // rede caiu na volta), ou a varredura a encerrou como não terminada.
            await resolverConflito(arvore: arvore)
        } catch let e as ErroDaAPI {
            fase = .erroAoEnviar(e.mensagem)
        } catch {
            fase = .erroAoEnviar("Suas respostas não foram enviadas.")
        }
    }

    private func enviarUmaVez(arvore: ArvoreDeTriagem) async throws -> RetornoDoCheckin {
        let id = try await sessaoId()
        let corpo = Self.corpoDoEnvio(sessaoId: id, arvore: arvore, respostas: rascunho.respostas)
        return try await api.enviar("/triagem/sessoes/\(id)/respostas", corpo: corpo)
    }

    private func resolverConflito(arvore: ArvoreDeTriagem) async {
        do {
            if let id = rascunho.sessaoId {
                let sessao: RetornoDoCheckin = try await api.obter("/triagem/sessoes/\(id)")
                if sessao.estado == .concluida {
                    concluir(sessao)
                    return
                }
            }
            // Encerrada sem as respostas: nova sessão com chave nova, mesmas respostas.
            rascunho.chaveDeIdempotencia = UUID().uuidString.lowercased()
            rascunho.sessaoId = nil
            rascunho.guardar(modo)
            concluir(try await enviarUmaVez(arvore: arvore))
        } catch let e as ErroDaAPI {
            fase = .erroAoEnviar(e.mensagem)
        } catch {
            fase = .erroAoEnviar("Suas respostas não foram enviadas.")
        }
    }

    private func concluir(_ retorno: RetornoDoCheckin) {
        RascunhoDoCheckin.apagar(modo)
        fase = .concluido(retorno)
        aoConcluir?(retorno)
    }
}
