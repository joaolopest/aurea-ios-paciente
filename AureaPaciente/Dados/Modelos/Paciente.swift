import Foundation

/// `GET /paciente/perfil`. Datas `@db.Date` chegam como meia-noite UTC: exibir SEMPRE por
/// `DataCivil`, nunca formatar direto (o dia volta um no fuso do Brasil).
struct PerfilDoPaciente: Decodable, Sendable {
    struct Paciente: Decodable, Sendable {
        let id: String
        let nome: String
        let dataNascimento: Date?
        let diagnostico: String?
    }

    struct Medico: Decodable, Sendable {
        let nome: String
        let funcao: String?
        let registroDoConselho: String?
    }

    struct Tratamento: Decodable, Sendable {
        struct Protocolo: Decodable, Sendable { let id: String; let nome: String }
        let protocolo: Protocolo?
        let iniciadoEm: Date?
    }

    struct Ciclo: Decodable, Sendable {
        let numero: Int
        let sessaoRealizadaEm: Date?
        let previsaoDaProximaSessao: Date?
        let diaDoCiclo: Int?
    }

    struct Contato: Decodable, Sendable, Identifiable {
        let id: String
        let nome: String
        let telefone: String?
        let relacao: String?
    }

    struct Contatos: Decodable, Sendable {
        let doPaciente: [Contato]
        let deEmergencia: [Contato]
    }

    let paciente: Paciente
    let medicoAssistente: Medico?
    let tratamento: Tratamento?
    let ciclo: Ciclo?
    let contatos: Contatos
    let alergias: [Alergia]
}

struct Alergia: Decodable, Sendable, Identifiable, Equatable {
    let id: String
    let descricao: String
    let origem: String?
    let confirmada: Bool?
}

/// `POST /paciente/alergias` → `{ alergia, jaRegistrada, mensagem }`.
struct RespostaDeAlergia: Decodable, Sendable {
    let alergia: Alergia
    let jaRegistrada: Bool
    let mensagem: String?
}

/// `GET /paciente/agenda` — `{ itens, proximoCursor, periodo }`.
struct ItemDaAgenda: Decodable, Sendable, Identifiable, Equatable {
    struct Profissional: Decodable, Sendable, Equatable {
        let nome: String
        let funcao: String?
    }

    let id: String
    let tipo: String
    /// Instante real (não `@db.Date`): formata no fuso do aparelho.
    let aconteceEm: Date
    let local: String?
    let observacoes: String?
    let profissional: Profissional?
}

/// `GET /paciente/biblioteca` (lista) — `corpo` não vem, só `resumo`.
struct VerbeteResumido: Decodable, Sendable, Identifiable, Equatable {
    let id: String
    let categoria: String
    let titulo: String
    let autoria: String?
    let resumo: String?
}

/// `GET /paciente/biblioteca/:id` — aqui é `corpo`, não `conteudo` (divergência do tipo
/// do web registrada no levantamento), e `revisadoEm` pode ser nulo.
struct Verbete: Decodable, Sendable, Identifiable {
    let id: String
    let categoria: String
    let titulo: String
    let corpo: String
    let autoria: String?
    let revisadoEm: Date?
}

/// `GET /paciente/solicitacoes-de-contato`. Sem `motivo`: a coluna não existe
/// (docs/CONTORNOS.md, C-03).
struct PedidoDeContato: Decodable, Sendable, Identifiable, Equatable {
    let id: String
    let solicitadaEm: Date
    let atendidaEm: Date?
    let atendida: Bool
}

/// `POST /paciente/solicitacoes-de-contato`.
struct RespostaDePedidoDeContato: Decodable, Sendable {
    let solicitacaoId: String
    let solicitadaEm: Date
    let reaproveitada: Bool
}

/// `GET /paciente/notificacoes` — o envelope tem `naoLidas` além da página.
struct PaginaDeAvisos: Decodable, Sendable {
    let itens: [AvisoDaEquipe]
    let proximoCursor: String?
    let naoLidas: Int
}

struct AvisoDaEquipe: Decodable, Sendable, Identifiable, Equatable {
    let id: String
    let assunto: String
    let corpo: String?
    let criadaEm: Date
    let lidaEm: Date?
}
