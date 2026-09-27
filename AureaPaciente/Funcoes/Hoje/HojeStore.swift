import Foundation
import Observation

/// O estado da tela Hoje. O "já respondi hoje?" vem do SERVIDOR (inviolável 6): o web
/// guardava em `sessionStorage` e esquecia ao trocar de aparelho ou limpar dados.
@MainActor
@Observable
final class HojeStore {
    enum EstadoDoDia: Equatable {
        case pendente
        /// Começou e não terminou. `local` = há rascunho neste iPhone para continuar.
        case emAndamento(local: Bool)
        case respondido(RetornoDoCheckin)
    }

    enum Carga: Equatable { case carregando, pronto, erro(String) }

    private(set) var carga: Carga = .carregando
    private(set) var estadoDoDia: EstadoDoDia = .pendente
    /// A instrução mais recente de hoje vinda de um REGISTRO avulso ("entre em contato com
    /// o serviço hoje"). Não some porque a pessoa fechou a tela de fechamento.
    private(set) var instrucaoDeRegistro: RetornoDoCheckin?
    /// Quantos sintomas a pessoa registrou hoje fora do check-in.
    private(set) var registrosDeHoje = 0
    private(set) var perfil: PerfilDoPaciente?
    private(set) var proximo: ItemDaAgenda?

    private let api: ClienteAPI

    init(api: ClienteAPI = .compartilhado) { self.api = api }

    func carregar() async {
        if perfil == nil { carga = .carregando }
        do {
            async let perfil: PerfilDoPaciente = api.obter("/paciente/perfil")
            async let historico: Pagina<DiaDoHistorico> = api.obter("/triagem/historico")
            async let agenda: Pagina<ItemDaAgenda> = api.obter("/paciente/agenda")
            let (p, h, a) = try await (perfil, historico, agenda)
            self.perfil = p
            self.proximo = a.itens.min { $0.aconteceEm < $1.aconteceEm }
            self.estadoDoDia = try await estado(de: h.itens)
            carga = .pronto
        } catch ErroDaAPI.sessaoEncerrada {
            carga = .erro(ErroDaAPI.sessaoEncerrada.mensagem)
        } catch let e as ErroDaAPI {
            carga = .erro(e.mensagem)
        } catch {
            carga = .erro("As informações de hoje não carregaram.")
        }
    }

    /// O check-in do dia é a sessão que respondeu as CINCO portas. Registro avulso (só os
    /// sintomas escolhidos) não conta como check-in: os outros sintomas não foram perguntados.
    nonisolated static func ehCheckinCompleto(_ dia: DiaDoHistorico) -> Bool {
        Rotulos.portas.isSubset(of: Set(dia.respostas.map(\.campo)))
    }

    private func estado(de itens: [DiaDoHistorico]) async throws -> EstadoDoDia {
        let deHoje = itens.filter { Calendar.current.isDateInToday($0.iniciadaEm) }
        let concluidas = deHoje.filter { $0.estado == .concluida }.sorted { $0.iniciadaEm > $1.iniciadaEm }
        let registros = concluidas.filter { !Self.ehCheckinCompleto($0) }
        registrosDeHoje = registros.count

        // Segurança antes de tudo: se um registro de hoje pediu contato, a instrução fica.
        instrucaoDeRegistro = nil
        for registro in registros.prefix(3) {
            let sessao: RetornoDoCheckin = try await api.obter("/triagem/sessoes/\(registro.id)")
            if sessao.pedeContatoComServico { instrucaoDeRegistro = sessao; break }
        }

        if let completa = concluidas.first(where: Self.ehCheckinCompleto) {
            let sessao: RetornoDoCheckin = try await api.obter("/triagem/sessoes/\(completa.id)")
            return .respondido(sessao)
        }
        // "Começou o check-in" vem do rascunho DO CHECK-IN. Uma sessão em andamento no
        // servidor não serve de sinal: ela chega sem respostas, e pode ser um registro
        // avulso deixado pela metade — dizer "você começou o check-in" seria falso.
        if RascunhoDoCheckin.carregar(.diario).map({ !$0.respostas.isEmpty }) ?? false {
            return .emAndamento(local: true)
        }
        // Abandonada hoje conta como pendente: a pessoa pode responder de novo.
        return .pendente
    }

    // MARK: Ciclo em palavras

    /// O que a tela diz sobre o ciclo. Previsão vencida troca de pergunta — quanto passou,
    /// não quanto falta — e nunca vira "Faltam 0 dias" nem "Passou 40 dias" (ADR-006).
    struct Ciclo: Equatable {
        let numero: Int
        let dia: Int?
        let totalDoCiclo: Int?
        /// Dias até a próxima sessão prevista; nil se não há previsão ou se já passou.
        let faltam: Int?
        /// Frase quando a previsão já passou.
        let previsaoVencida: String?
    }

    var ciclo: Ciclo? {
        guard let c = perfil?.ciclo else { return nil }
        var total: Int?
        var faltam: Int?
        var vencida: String?
        if let previsao = c.previsaoDaProximaSessao {
            let dias = DataCivil.diasAte(previsao)
            if dias >= 0 {
                faltam = dias
                if let realizada = c.sessaoRealizadaEm {
                    total = DataCivil.diasAte(previsao) - DataCivil.diasAte(realizada)
                }
            } else {
                vencida = "A próxima sessão estava prevista para \(DataCivil.porExtensoSemAno(previsao)). Confirme a data com a equipe."
            }
        }
        return Ciclo(numero: c.numero, dia: c.diaDoCiclo, totalDoCiclo: total, faltam: faltam, previsaoVencida: vencida)
    }
}
