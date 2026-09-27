import Foundation

// Modelos da porta. Todos escritos a partir do curl real (AureaPacienteTests/Fixtures),
// nunca do tipo TS do web — seis defeitos do web vieram de confiar no tipo.

/// `POST /autenticacao/entrar`
struct RespostaDeEntrada: Decodable, Sendable {
    let token: String
    let expiraEm: Date
    let perfil: String
    let precisaVerPrimeiroAcesso: Bool
}

/// `GET /autenticacao/eu`. O nome NÃO vem na raiz: mora em `perfilDetalhado.nome`
/// (o web normaliza isso em `sessao.tsx`; aqui, `nome`).
struct QuemSou: Decodable, Sendable, Equatable {
    struct Detalhe: Decodable, Sendable, Equatable {
        let id: String
        let nome: String
    }

    let id: String
    let perfil: String
    let pacienteId: String?
    let perfilDetalhado: Detalhe?

    var nome: String? { perfilDetalhado?.nome }

    /// "Paciente Um (fictício)" → "Paciente". Na saudação, só o primeiro nome.
    var primeiroNome: String? {
        nome?.split(separator: " ").first.map(String.init)
    }
}

/// `GET /conta/consentimento`. Libera o app com `!exigido || aceito` — a mesma conta
/// do web (`sessao.tsx`).
struct EstadoDoConsentimento: Decodable, Sendable {
    let exigido: Bool
    let versaoVigente: String
    let aceito: Bool
    let aceitoEm: Date?

    var liberado: Bool { !exigido || aceito }
}
