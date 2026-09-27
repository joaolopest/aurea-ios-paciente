import SwiftUI

/// Espaço, cantos e profundidade (docs/BRIEFING-E-DCM.md §5). Grade de 4pt.
/// Medidas calibradas pela prévia "papel e céu" aprovada (27/09/2026).
enum Espaco {
    static let margem: CGFloat = 24
    static let cartao: CGFloat = 22
    static let entreCartoes: CGFloat = 14
    static let entreSecoes: CGFloat = 28
    /// Alvo mínimo no check-in (DC-001). No resto do app, 44.
    static let alvoDoCheckin: CGFloat = 56
    /// Botão de resposta do check-in: bem acima do mínimo, é o gesto central do app.
    static let resposta: CGFloat = 78
    /// Botão principal (CTA).
    static let botao: CGFloat = 64
    static let alvo: CGFloat = 44
}

/// Cantos sempre contínuos (squircle), nunca o arredondado simples.
enum Canto {
    static let cartao: CGFloat = 32
    static let resposta: CGFloat = 28
    static let botao: CGFloat = 24
    static let peca: CGFloat = 14

    static func forma(_ raio: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: raio, style: .continuous)
    }
}

extension View {
    /// Superfície de cartão, como na prévia: sem contorno. Uma linha de luz de 1pt embaixo
    /// (a borda do papel) e uma sombra macia tingida de petróleo, que acaba antes da borda
    /// de baixo (raio grande, deslocada). Sombra preta sobre creme acinzenta o papel (ADR-006).
    func superficie(raio: CGFloat = Canto.cartao, fundo: Color = Cor.folha) -> some View {
        background {
            Canto.forma(raio)
                .fill(fundo)
                .shadow(color: Cor.linha, radius: 0, y: 1)
                .shadow(color: Cor.sombra.opacity(0.14), radius: 16, y: 12)
        }
    }
}
