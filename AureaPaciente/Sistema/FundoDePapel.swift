import SwiftUI

/// O papel pintado com aquarela atrás do conteúdo: 2 ou 3 elipses de céu e lavanda com
/// desfoque largo. É daqui que vem o lúdico do app (nível 3, sem personagem).
///
/// A posição é FIXA por composição, nunca aleatória: a mesma tela tem sempre o mesmo papel.
/// E nada disto se move — durante o check-in o fundo fica parado.
struct FundoDePapel: View {
    enum Composicao {
        /// Hoje: céu no alto à direita, lavanda à esquerda.
        case manha
        /// Check-in: mais apagado, para a pergunta ser o que se vê.
        case foco
        /// Porta (entrar, consentimento): céu grande no topo.
        case porta
        /// Telas de consulta: um toque só, no alto.
        case discreto
    }

    var composicao: Composicao = .discreto

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                Cor.papel
                ForEach(Array(formas(largura: w).enumerated()), id: \.offset) { _, forma in
                    Ellipse()
                        .fill(forma.cor)
                        .frame(width: forma.tamanho.width, height: forma.tamanho.height)
                        .position(forma.centro)
                        .opacity(forma.opacidade)
                }
                .blur(radius: 34)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private struct Forma {
        let cor: Color
        let tamanho: CGSize
        let centro: CGPoint
        let opacidade: Double
    }

    /// Proporções tiradas da prévia aprovada (tela de 260pt → fração da largura).
    private func formas(largura w: CGFloat) -> [Forma] {
        switch composicao {
        case .manha:
            [
                Forma(cor: Cor.ceu, tamanho: CGSize(width: w * 0.95, height: w * 0.95), centro: CGPoint(x: w * 0.92, y: w * 0.12), opacidade: 1),
                Forma(cor: Cor.lavanda, tamanho: CGSize(width: w * 0.72, height: w * 0.72), centro: CGPoint(x: -w * 0.04, y: w * 0.88), opacidade: 1),
            ]
        case .foco:
            [
                Forma(cor: Cor.ceu, tamanho: CGSize(width: w * 1.1, height: w * 1.1), centro: CGPoint(x: w * 0.02, y: w * 0.62), opacidade: 0.8),
                Forma(cor: Cor.lavanda, tamanho: CGSize(width: w * 0.85, height: w * 0.85), centro: CGPoint(x: w * 0.95, y: w * 0.12), opacidade: 0.9),
            ]
        case .porta:
            [
                Forma(cor: Cor.ceu, tamanho: CGSize(width: w * 1.3, height: w * 1.0), centro: CGPoint(x: w * 0.62, y: w * 0.05), opacidade: 1),
                Forma(cor: Cor.lavanda, tamanho: CGSize(width: w * 0.8, height: w * 0.7), centro: CGPoint(x: w * 0.02, y: w * 0.5), opacidade: 1),
            ]
        case .discreto:
            [
                Forma(cor: Cor.ceu, tamanho: CGSize(width: w * 0.9, height: w * 0.75), centro: CGPoint(x: w * 0.95, y: 0), opacidade: 0.9),
                Forma(cor: Cor.lavanda, tamanho: CGSize(width: w * 0.5, height: w * 0.45), centro: CGPoint(x: -w * 0.05, y: w * 0.35), opacidade: 0.6),
            ]
        }
    }
}

/// Véu de papel sob a barra de status: o conteúdo rolado esmaece antes de encostar no
/// relógio, em vez de passar por baixo dele.
private struct VeuDoTopo: ViewModifier {
    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            GeometryReader { geo in
                LinearGradient(
                    stops: [.init(color: Cor.papel, location: 0), .init(color: Cor.papel, location: 0.6), .init(color: Cor.papel.opacity(0), location: 1)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: geo.safeAreaInsets.top + 16)
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
            }
            .accessibilityHidden(true)
        }
    }
}

extension View {
    func veuDoTopo() -> some View { modifier(VeuDoTopo()) }
}
