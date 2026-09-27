import SwiftUI
import UIKit

/// A paleta "papel e céu" (docs/BRIEFING-E-DCM.md §3).
///
/// Metade fria do círculo e neutros quentes. Verde, amarelo, âmbar e vermelho são a escala
/// de risco da equipe e NÃO EXISTEM neste projeto — nem os vizinhos que o olho confunde
/// com eles (laranja, pêssego, coral, terracota, sálvia, lima, menta, teal). Se a cor não
/// está declarada aqui, nenhuma tela consegue pintar uma barra de verde por engano, como
/// aconteceu no web (ADR-006, tarefa 207). `scripts/conformidade.sh` barra as cores do
/// sistema no build.
///
/// Cada token tem a variante do dia e a da noite. A noite é grafite quente, não preto
/// puro: quem abre o app de madrugada com febre não precisa de contraste máximo.
enum Cor {
    /// Fundo de toda tela.
    static let papel = dinamica(0xFBF9EF, 0x1C1A21)
    /// Cartões e botões de resposta.
    static let folha = dinamica(0xFFFFFF, 0x27242D)
    /// Texto, botão principal e resposta selecionada. A tinta institucional da AUREA.
    static let tinta = dinamica(0x0E2739, 0xF2EEE4)
    /// Texto de apoio. 7,3:1 sobre folha, AAA.
    static let tintaSuave = dinamica(0x4A5866, 0xB7B0BF)
    /// Formas de fundo e superfícies de apoio. Nunca texto.
    static let ceu = dinamica(0xD6E4F5, 0x2B3A52)
    /// Fechamento do dia, aba ativa, biblioteca. Nunca texto.
    static let lavanda = dinamica(0xE6DEF5, 0x3A3150)
    /// O único acento: progresso, rótulos, links. 7,2:1 sobre papel.
    static let ameixa = dinamica(0x62468A, 0xB9A2E0)
    /// Divisórias, estados vazios, selo de "não validado".
    static let areia = dinamica(0xEFE7D6, 0x34302A)
    /// Hairline de cartão. A profundidade vem daqui, não de sombra preta.
    static let linha = dinamica(0xE8E1D1, 0x34313B)
    /// Sombra tingida de petróleo (ADR-006: sombra preta acinzenta o creme).
    static let sombra = Color(red: 14 / 255, green: 39 / 255, blue: 57 / 255)

    private static func dinamica(_ claro: UInt32, _ escuro: UInt32) -> Color {
        Color(UIColor { traco in
            UIColor(hex: traco.userInterfaceStyle == .dark ? escuro : claro)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
