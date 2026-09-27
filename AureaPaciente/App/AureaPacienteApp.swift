import SwiftUI

@main
struct AureaPacienteApp: App {
    @State private var sessao = Sessao()

    var body: some Scene {
        WindowGroup {
            RaizView()
                .environment(sessao)
                // Nem o azul do sistema vaza: ao lado do petróleo, pareceria outro app.
                .tint(Cor.ameixa)
        }
    }
}

/// A porta do app. Decide o que aparece a partir da fase da sessão.
struct RaizView: View {
    @Environment(Sessao.self) private var sessao
    @Environment(\.scenePhase) private var fase

    var body: some View {
        ZStack {
            switch sessao.fase {
            case .verificando:
                // Emenda com a tela de abertura (papel liso): sem logo girando.
                Cor.papel.ignoresSafeArea()
            case .fora:
                EntradaView().transition(.opacity)
            case .trocandoSenha(let atual):
                TrocaDeSenhaView(senhaAtual: atual).transition(.opacity)
            case .consentindo(let versao):
                ConsentimentoView(versao: versao).transition(.opacity)
            case .dentro:
                AbasView().transition(.opacity)
            }

            // A miniatura do seletor de apps é tirada quando o app sai de ativo. Ela não
            // mostra sintoma nem orientação: vira papel liso com a marca.
            if fase != .active, sessao.fase == .dentro {
                CapaDePrivacidade().transition(.opacity)
            }
        }
        .animation(Movimento.interface, value: sessao.fase)
        .animation(Movimento.toque, value: fase)
        .onAppear { sessao.iniciar() }
    }
}

private struct CapaDePrivacidade: View {
    var body: some View {
        ZStack {
            FundoDePapel(composicao: .porta)
            Marca(tamanho: 64)
        }
    }
}

/// A marca AUREA: o "A" em petróleo sobre um círculo de céu. Sem personagem.
struct Marca: View {
    var tamanho: CGFloat = 44

    var body: some View {
        Text("A")
            .font(.nunito(tamanho * 0.5))
            .foregroundStyle(Cor.tinta)
            .frame(width: tamanho, height: tamanho)
            .superficie(raio: tamanho * 0.32)
            .accessibilityLabel("AUREA")
    }
}
