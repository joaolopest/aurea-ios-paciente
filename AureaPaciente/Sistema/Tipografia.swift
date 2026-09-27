import SwiftUI

/// Tipografia do paciente (docs/BRIEFING-E-DCM.md §4).
///
/// Nunito: redonda e macia, o tom caloroso vem da letra, já que o app não tem
/// personagem. Escolha do João sobre a prévia "papel e céu" (27/09/2026), no lugar da
/// SF Pro Rounded do DCM original — a SF lia mais fria e apertada.
///
/// Os tamanhos-base ficam ACIMA dos mínimos do DC-001 (pergunta 28, corpo 20, ajuda 17)
/// e todos escalam com o Dynamic Type até `.accessibility5` — quem lê pode estar no pior
/// dia do ciclo.
///
/// Sem fonte mono: número usa `.monospacedDigit()`. Sem caixa alta com espaçamento — a
/// estética de painel do web não entra aqui.
enum Tipo: CaseIterable {
    case saudacao, titulo, pergunta, resposta, leitura, ajuda, rotulo, numero

    var tamanho: CGFloat {
        switch self {
        case .saudacao: 34
        case .titulo: 30
        case .pergunta: 34
        case .resposta: 22
        case .leitura: 20
        case .ajuda: 18
        case .rotulo: 16
        case .numero: 36
        }
    }

    var peso: Font.Weight {
        switch self {
        case .saudacao, .pergunta, .numero: .heavy
        case .titulo, .resposta: .bold
        case .leitura, .ajuda: .medium
        case .rotulo: .semibold
        }
    }

    /// O arquivo da Nunito para o peso. Três pesos só, como na prévia: 600 no apoio,
    /// 700 nos rótulos, 800 no que tem voz (pergunta, resposta, título).
    var fonte: String {
        switch peso {
        case .heavy, .bold: "Nunito-ExtraBold"
        case .semibold: "Nunito-Bold"
        default: "Nunito-SemiBold"
        }
    }

    /// O estilo do sistema que dita a curva de escala.
    var escalaCom: Font.TextStyle {
        switch self {
        case .saudacao, .numero: .largeTitle
        case .titulo, .pergunta: .title
        case .resposta, .leitura: .body
        case .ajuda: .callout
        case .rotulo: .subheadline
        }
    }

    /// Entrelinha extra, em fração do tamanho. Leitura respira mais.
    var entrelinha: CGFloat {
        switch self {
        case .leitura, .ajuda: 0.32
        case .pergunta, .titulo, .saudacao: 0.02
        default: 0.14
        }
    }
}

private struct EstiloDeTexto: ViewModifier {
    let tipo: Tipo
    @ScaledMetric private var tamanho: CGFloat

    init(_ tipo: Tipo) {
        self.tipo = tipo
        _tamanho = ScaledMetric(wrappedValue: tipo.tamanho, relativeTo: tipo.escalaCom)
    }

    func body(content: Content) -> some View {
        content
            .font(.custom(tipo.fonte, fixedSize: tamanho))
            .lineSpacing(tamanho * tipo.entrelinha)
            // Título grande aperta um pouco, como a prévia (-0,015em). Corpo fica solto.
            .tracking(tipo.tamanho >= 28 ? -tamanho * 0.015 : 0)
    }
}

extension View {
    /// Aplica um papel tipográfico do paciente, com Dynamic Type.
    func tipo(_ tipo: Tipo) -> some View { modifier(EstiloDeTexto(tipo)) }
}

extension Font {
    /// Nunito num tamanho fixo que escala com o Dynamic Type — para números grandes
    /// fora da escala (contador, temperatura, marca).
    static func nunito(_ tamanho: CGFloat, peso: Font.Weight = .heavy, relativoA estilo: Font.TextStyle = .largeTitle) -> Font {
        let nome = switch peso {
        case .heavy, .bold, .black: "Nunito-ExtraBold"
        case .semibold: "Nunito-Bold"
        default: "Nunito-SemiBold"
        }
        return .custom(nome, size: tamanho, relativeTo: estilo)
    }
}
