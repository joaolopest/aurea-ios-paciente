import Foundation
import Observation

/// O estado de quem está usando o app, do lado de fora das telas.
///
/// A porta tem duas travas independentes e em sequência, como no web (`sessao.tsx`):
/// `fora` → (entrar) → `trocandoSenha`? → `consentindo`? → `dentro`
///
/// Face ID DESLIGADO por decisão do João (25/09/2026): entra com CPF e senha, como o web.
/// Religar volta à mesa com o parecer do Comitê de Ética.
@MainActor
@Observable
final class Sessao {
    enum Fase: Equatable {
        case verificando
        case fora
        case trocandoSenha(senhaAtual: String)
        case consentindo(versao: String)
        case dentro
    }

    private(set) var fase: Fase = .verificando
    private(set) var eu: QuemSou?
    /// Mensagem que a tela de entrada mostra ao voltar (sessão expirada, senha trocada).
    var avisoDeEntrada: String?

    private let api: ClienteAPI
    private let token: GuardaDeToken

    init(api: ClienteAPI = .compartilhado, token: GuardaDeToken = .compartilhado) {
        self.api = api
        self.token = token
    }

    /// Abertura: com token guardado, confere quem é e o termo; sem token, vai para a entrada.
    func iniciar() {
        guard token.ler() != nil else { fase = .fora; return }
        Task { await conferirPortas() }
    }

    // MARK: Entrar e sair

    /// Paciente entra com CPF. O CPF vai só com dígitos; a API valida.
    func entrar(cpf: String, senha: String) async throws {
        struct Corpo: Encodable, Sendable { let cpf: String; let senha: String; let manterConectado: Bool }
        let digitos = cpf.filter(\.isNumber)
        let resposta: RespostaDeEntrada = try await api.enviar(
            "/autenticacao/entrar",
            corpo: Corpo(cpf: digitos, senha: senha, manterConectado: true)
        )

        // Este é o app do paciente. A conta da equipe tem o app dela.
        guard resposta.perfil == "PACIENTE" else {
            throw ErroDaAPI.recusado("Esta conta é da equipe. O app da equipe é o AUREA Plantão.")
        }

        token.guardar(resposta.token)
        avisoDeEntrada = nil

        if resposta.precisaVerPrimeiroAcesso {
            eu = try? await api.obter("/autenticacao/eu")
            fase = .trocandoSenha(senhaAtual: senha)
        } else {
            await conferirPortas()
        }
    }

    /// Troca da senha provisória. A API revoga TODAS as sessões ao trocar — inclusive
    /// esta —, então a pessoa volta para a entrada com a senha nova.
    func trocarSenha(atual: String, nova: String) async throws {
        struct Corpo: Encodable, Sendable { let senhaAtual: String; let senhaNova: String }
        let _: Vazio = try await api.enviar("/conta/senha", corpo: Corpo(senhaAtual: atual, senhaNova: nova))
        encerrarLocalmente(aviso: "Senha trocada. Entre com a senha nova.")
    }

    /// Aceite do termo. Só navega depois que o servidor confirma: o web já navegou com o
    /// aceite falhando e nunca registrou consentimento nenhum (commit 6614122).
    func aceitarTermo(versao: String) async throws {
        struct Corpo: Encodable, Sendable { let versaoDoTermo: String }
        let _: Vazio = try await api.enviar("/conta/consentimento", corpo: Corpo(versaoDoTermo: versao))
        let estado: EstadoDoConsentimento = try await api.obter("/conta/consentimento")
        guard estado.liberado else {
            throw ErroDaAPI.recusado("Seu aceite não foi registrado. Tente de novo em instantes.")
        }
        fase = .dentro
    }

    func sair() async {
        struct Nada: Encodable, Sendable {}
        try? await api.enviarSemResposta("/autenticacao/sair", corpo: Nada())
        encerrarLocalmente(aviso: nil)
    }

    /// A API respondeu 401 no meio do uso.
    func sessaoExpirou() {
        encerrarLocalmente(aviso: "Sua sessão terminou. Entre de novo.")
    }

    private func encerrarLocalmente(aviso: String?) {
        token.apagar()
        RascunhoDoCheckin.apagarTodos()
        eu = nil
        avisoDeEntrada = aviso
        fase = .fora
    }

    // MARK: Portas

    private func conferirPortas() async {
        do {
            eu = try await api.obter("/autenticacao/eu")
            let termo: EstadoDoConsentimento = try await api.obter("/conta/consentimento")
            fase = termo.liberado ? .dentro : .consentindo(versao: termo.versaoVigente)
        } catch ErroDaAPI.sessaoEncerrada {
            sessaoExpirou()
        } catch {
            // Sem rede ao abrir: entra, e cada tela mostra o próprio erro com "Tentar de
            // novo". O termo é conferido de novo na próxima abertura.
            fase = .dentro
        }
    }
}
