import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// LEI 1 — o paciente nunca vê cor de risco, nome de regra nem nome de campo.
//
// Nenhum modelo deste arquivo declara a classificação, a explicação por regra, as
// regras disparadas, o conjunto de limiares nem o aviso interno à enfermagem. A API
// chegou a mandar tudo isso ao paciente até 26/09/2026; a correção está no servidor
// (`servicos/resposta-ao-paciente.ts`), e a omissão aqui é a segunda trava: campo que
// não existe no modelo é descartado no decode e não chega a nenhuma tela.
//
// É DECISÃO, NÃO ESQUECIMENTO. Ver docs/CONTORNOS.md (C-01) antes de "completar" um
// modelo com o que a API manda. `LeiUmTests` falha se estes tipos passarem a expor esses
// campos, e `scripts/conformidade.sh` falha o build se o nome aparecer no código.
// ─────────────────────────────────────────────────────────────────────────────

// MARK: Árvore

/// `GET /triagem/arvore` — as perguntas vêm SEMPRE do servidor, nunca embarcadas no app
/// (duas cópias de pergunta divergem).
struct ArvoreDeTriagem: Decodable, Sendable {
    let sintomas: [Ramo]
}

struct Ramo: Decodable, Sendable, Identifiable {
    /// Identificador do sintoma (`FEBRE`). Nunca vai à tela: a tela usa `rotulo`.
    let sintoma: String
    let rotulo: String
    let porta: Pergunta
    let detalhes: [Pergunta]

    var id: String { sintoma }
}

struct Pergunta: Decodable, Sendable, Identifiable, Equatable {
    enum TipoDeResposta: Equatable, Sendable {
        case simOuNao, numero, inteiro, opcao
        case desconhecido(String)
    }

    struct Dependencia: Decodable, Sendable, Equatable {
        let campo: String
        let valor: Valor
    }

    /// Chave da pergunta (`temperaturaMaxima`). É o que o app envia de volta; nunca é
    /// mostrada — a tela mostra `pergunta`.
    let campo: String
    let pergunta: String
    let tipo: TipoDeResposta
    let dependeDe: Dependencia?
    let minimo: Double?
    let maximo: Double?
    let casasDecimais: Int?
    let unidade: String?
    let ajuda: String?
    let opcoes: [String]?

    var id: String { campo }

    enum CodingKeys: String, CodingKey {
        case campo, pergunta, tipo, dependeDe, minimo, maximo, casasDecimais, unidade, ajuda, opcoes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        campo = try c.decode(String.self, forKey: .campo)
        pergunta = try c.decode(String.self, forKey: .pergunta)
        let bruto = try c.decode(String.self, forKey: .tipo)
        tipo = switch bruto {
        case "BOOLEANO": .simOuNao
        case "NUMERICO": .numero
        case "INTEIRO": .inteiro
        case "OPCAO": .opcao
        default: .desconhecido(bruto)
        }
        dependeDe = try c.decodeIfPresent(Dependencia.self, forKey: .dependeDe)
        minimo = try c.decodeIfPresent(Double.self, forKey: .minimo)
        maximo = try c.decodeIfPresent(Double.self, forKey: .maximo)
        casasDecimais = try c.decodeIfPresent(Int.self, forKey: .casasDecimais)
        unidade = try c.decodeIfPresent(String.self, forKey: .unidade)
        ajuda = try c.decodeIfPresent(String.self, forKey: .ajuda)
        opcoes = try c.decodeIfPresent([String].self, forKey: .opcoes)
    }
}

// MARK: Valor de resposta

/// Uma resposta: exatamente um dos três tipos (a API recusa mais de um).
enum Valor: Codable, Sendable, Equatable, Hashable {
    case booleano(Bool)
    case numero(Double)
    case texto(String)

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let b = try? c.decode(Bool.self) { self = .booleano(b) }
        else if let n = try? c.decode(Double.self) { self = .numero(n) }
        else { self = .texto(try c.decode(String.self)) }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .booleano(let b): try c.encode(b)
        case .numero(let n): try c.encode(n)
        case .texto(let t): try c.encode(t)
        }
    }
}

/// Número que a API manda às vezes como texto: `valorNumerico` é Decimal no Prisma e
/// chega como `"38.9"`. Aceita os dois; nunca falha o decode por isso.
struct NumeroFlexivel: Decodable, Sendable, Equatable {
    let valor: Double

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let n = try? c.decode(Double.self) { valor = n; return }
        let texto = try c.decode(String.self)
        guard let n = Double(texto) else {
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Número ilegível: \(texto)")
        }
        valor = n
    }
}

// MARK: Envio

/// `POST /triagem/sessoes` → `{ sessaoId, estado, reaproveitada }`.
struct SessaoAberta: Decodable, Sendable {
    let sessaoId: String
    let estado: EstadoDaSessao
    let reaproveitada: Bool
}

/// Corpo de `POST /triagem/sessoes/:id/respostas`, agrupado por sintoma.
struct EnvioDeRespostas: Encodable, Sendable {
    struct PorSintoma: Encodable, Sendable {
        let sintoma: String
        let respostas: [RespostaDeCampo]
    }

    struct RespostaDeCampo: Encodable, Sendable {
        let campo: String
        let valor: Valor

        enum CodingKeys: String, CodingKey { case campo, valorNumerico, valorBooleano, valorTexto }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(campo, forKey: .campo)
            switch valor {
            case .booleano(let b): try c.encode(b, forKey: .valorBooleano)
            case .numero(let n): try c.encode(n, forKey: .valorNumerico)
            case .texto(let t): try c.encode(t, forKey: .valorTexto)
            }
        }
    }

    let sessaoId: String
    let sintomas: [PorSintoma]
}

// MARK: O que o paciente recebe de volta

/// Orientação escrita pela equipe. Só texto — a cor que o motor calculou não viaja.
struct Orientacao: Decodable, Sendable, Identifiable, Equatable {
    let id: String
    let titulo: String
    let corpo: String
}

/// Retorno da conclusão do check-in, e também de `GET /triagem/sessoes/:id`.
///
/// Duas coisas, e só elas: as orientações da equipe e a instrução "procure o serviço
/// hoje" — a gravidade virada em instrução, calculada no servidor.
struct RetornoDoCheckin: Decodable, Sendable, Equatable {
    let sessaoId: String
    let estado: EstadoDaSessao
    let concluidaEm: Date?
    let orientacoes: [Orientacao]
    let pedeContatoComServico: Bool

    enum CodingKeys: String, CodingKey {
        case sessaoId, id, estado, concluidaEm, orientacoes, pedeContatoComServico
    }

    init(sessaoId: String, estado: EstadoDaSessao, concluidaEm: Date?, orientacoes: [Orientacao], pedeContatoComServico: Bool) {
        self.sessaoId = sessaoId
        self.estado = estado
        self.concluidaEm = concluidaEm
        self.orientacoes = orientacoes
        self.pedeContatoComServico = pedeContatoComServico
    }

    /// A conclusão manda `sessaoId`; a sessão reaberta manda `id`. Mesmo conteúdo.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sessaoId = try c.decodeIfPresent(String.self, forKey: .sessaoId) ?? c.decode(String.self, forKey: .id)
        estado = try c.decode(EstadoDaSessao.self, forKey: .estado)
        concluidaEm = try c.decodeIfPresent(Date.self, forKey: .concluidaEm)
        orientacoes = try c.decodeIfPresent([Orientacao].self, forKey: .orientacoes) ?? []
        pedeContatoComServico = try c.decodeIfPresent(Bool.self, forKey: .pedeContatoComServico) ?? false
    }
}

enum EstadoDaSessao: Decodable, Sendable, Equatable {
    case emAndamento, concluida, abandonada
    case desconhecido(String)

    init(from decoder: Decoder) throws {
        let bruto = try decoder.singleValueContainer().decode(String.self)
        self = switch bruto {
        case "EM_ANDAMENTO": .emAndamento
        case "CONCLUIDA": .concluida
        case "ABANDONADA": .abandonada
        default: .desconhecido(bruto)
        }
    }
}

// MARK: Histórico

/// Uma resposta gravada, como o histórico devolve.
struct RespostaGravada: Decodable, Sendable, Equatable {
    let sintoma: String
    let campo: String
    let valorNumerico: NumeroFlexivel?
    let valorBooleano: Bool?
    let valorTexto: String?
}

/// `GET /triagem/historico` — um item por sessão. Sem classificação (conferido no curl).
struct DiaDoHistorico: Decodable, Sendable, Identifiable, Equatable {
    let id: String
    let iniciadaEm: Date
    let concluidaEm: Date?
    let estado: EstadoDaSessao
    let diaDoCiclo: Int?
    let respostas: [RespostaGravada]

    /// Sintomas que a pessoa relatou: portas respondidas com "sim".
    var sintomasRelatados: [String] {
        var vistos: [String] = []
        for r in respostas where r.valorBooleano == true && Rotulos.portas.contains(r.campo) {
            if !vistos.contains(r.sintoma) { vistos.append(r.sintoma) }
        }
        return vistos
    }
}

/// Envelope de lista paginada por cursor.
struct Pagina<Item: Decodable & Sendable>: Decodable, Sendable {
    let itens: [Item]
    let proximoCursor: String?
}
