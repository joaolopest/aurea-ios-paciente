import SwiftUI

/// O fechamento do dia. IGUAL PARA TODO MUNDO (inviolável 3): o mesmo céu e a mesma
/// frase, relate a pessoa febre de 39 °C ou nada. Se o céu variasse com as respostas, a
/// animação classificaria.
///
/// A única diferença é conteúdo escrito: a instrução "entre em contato com o serviço
/// hoje" — que vem ANTES do céu, nunca escondida depois da celebração — e as orientações
/// da equipe. Lista de orientações vazia é estado válido (dia sem nada a orientar).
struct FechamentoView: View {
    let retorno: RetornoDoCheckin
    let falarComEnfermagem: () -> Void
    let voltar: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espaco.entreSecoes) {
                if retorno.pedeContatoComServico {
                    VStack(alignment: .leading, spacing: 14) {
                        Aviso(
                            tom: .firme,
                            titulo: "Entre em contato com o serviço hoje",
                            texto: "Pelo que você contou, a equipe pede que você fale com o serviço ainda hoje."
                        )
                        BotaoPrincipal(titulo: "Falar com a enfermagem", acao: falarComEnfermagem)
                    }
                    .padding(.top, 16)
                }

                CeuDoDia()
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Que bom que você respondeu hoje.")
                        .tipo(.saudacao)
                        .foregroundStyle(Cor.tinta)
                        .accessibilityAddTraits(.isHeader)
                    Text("Suas respostas chegaram à equipe.")
                        .tipo(.leitura)
                        .foregroundStyle(Cor.tintaSuave)
                }

                if !retorno.orientacoes.isEmpty {
                    VStack(alignment: .leading, spacing: Espaco.entreCartoes) {
                        Text("Orientações da sua equipe")
                            .tipo(.rotulo)
                            .foregroundStyle(Cor.ameixa)
                            .accessibilityAddTraits(.isHeader)
                        ForEach(retorno.orientacoes) { orientacao in
                            CartaoDeOrientacao(orientacao: orientacao)
                        }
                    }
                }

                BotaoPrincipal(titulo: "Voltar para o início", discreto: true, acao: voltar)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, Espaco.margem)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

struct CartaoDeOrientacao: View {
    let orientacao: Orientacao

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(orientacao.titulo).tipo(.resposta).foregroundStyle(Cor.tinta)
            Text(orientacao.corpo).tipo(.leitura).foregroundStyle(Cor.tintaSuave)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Espaco.cartao)
        .superficie()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - O céu

/// A assinatura do app: formas de céu e lavanda se abrem e as estrelas acendem em
/// sequência, ~1,2s, com o único quique do app. Vibração: leve, pausa, conclusão.
/// Com Reduzir Movimento, o céu aparece já formado.
struct CeuDoDia: View {
    @State private var aberto = false
    @State private var estrelasAcesas = 0
    @Environment(\.accessibilityReduceMotion) private var reduzirMovimento

    /// Posições fixas (fração do quadro). O céu é o mesmo todo dia, para todo mundo.
    private static let estrelas: [(x: CGFloat, y: CGFloat, r: CGFloat)] = [
        (0.18, 0.30, 3.2), (0.34, 0.16, 2.2), (0.52, 0.34, 3.8), (0.66, 0.12, 2.0),
        (0.80, 0.30, 2.8), (0.28, 0.58, 2.0), (0.60, 0.62, 2.6), (0.86, 0.60, 1.8),
    ]
    /// A constelação liga as primeiras estrelas: um traço, não um desenho.
    private static let traco = [0, 1, 2, 4]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Ellipse().fill(Cor.ceu)
                    .frame(width: w * 0.95, height: h * 0.95)
                    .position(x: w * 0.4, y: h * 0.5)
                    .scaleEffect(aberto ? 1 : 0.6)
                Ellipse().fill(Cor.lavanda)
                    .frame(width: w * 0.7, height: h * 0.8)
                    .position(x: w * 0.72, y: h * 0.42)
                    .scaleEffect(aberto ? 1 : 0.5)
                Ellipse().fill(Cor.ameixa.opacity(0.22))
                    .frame(width: w * 0.35, height: h * 0.45)
                    .position(x: w * 0.3, y: h * 0.35)
                    .scaleEffect(aberto ? 1 : 0.3)
            }
            .blur(radius: 30)
            .opacity(aberto ? 1 : 0)

            Canvas { ctx, tamanho in
                let pontos = Self.estrelas.map { CGPoint(x: $0.x * tamanho.width, y: $0.y * tamanho.height) }
                if estrelasAcesas >= Self.estrelas.count {
                    var linha = Path()
                    for (i, indice) in Self.traco.enumerated() {
                        i == 0 ? linha.move(to: pontos[indice]) : linha.addLine(to: pontos[indice])
                    }
                    ctx.stroke(linha, with: .color(Cor.tinta.opacity(0.22)), lineWidth: 1)
                }
                for (i, estrela) in Self.estrelas.enumerated() where i < estrelasAcesas {
                    let p = pontos[i]
                    let r = estrela.r
                    ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)), with: .color(Cor.tinta.opacity(0.7)))
                }
            }
        }
        .accessibilityHidden(true)
        .task {
            if reduzirMovimento {
                aberto = true
                estrelasAcesas = Self.estrelas.count
                await Tato.fechamento()
                return
            }
            withAnimation(Movimento.ceu) { aberto = true }
            await Tato.fechamento()
            for i in 1...Self.estrelas.count {
                try? await Task.sleep(for: .milliseconds(90))
                withAnimation(.easeOut(duration: 0.2)) { estrelasAcesas = i }
            }
        }
    }
}
