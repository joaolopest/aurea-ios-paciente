import SwiftUI

// MARK: - Botão principal

/// O CTA do app: tinta sobre papel, 56pt, texto que diz exatamente o que acontece.
struct BotaoPrincipal: View {
    let titulo: String
    var carregando = false
    var discreto = false
    let acao: () -> Void

    var body: some View {
        Button(action: acao) {
            ZStack {
                Text(titulo).multilineTextAlignment(.center).opacity(carregando ? 0 : 1)
                if carregando {
                    ProgressView().tint(discreto ? Cor.tinta : Cor.papel)
                        .accessibilityLabel("\(titulo), aguarde")
                }
            }
            .tipo(.resposta)
            .frame(maxWidth: .infinity, minHeight: Espaco.botao)
            .padding(.horizontal, 16)
            .foregroundStyle(discreto ? Cor.tinta : Cor.papel)
            .background {
                Canto.forma(Canto.botao)
                    .fill(discreto ? Cor.folha : Cor.tinta)
                    .shadow(color: discreto ? Cor.linha : .clear, radius: 0, y: 1)
                    .shadow(color: Cor.sombra.opacity(discreto ? 0.10 : 0.22), radius: 12, y: 8)
            }
            .contentShape(Canto.forma(Canto.botao))
        }
        .buttonStyle(Apertavel())
        .disabled(carregando)
    }
}

/// Desabilitado: bem mais claro (35%), para ler como "ainda não" e não como botão cinza.
struct EstiloDesabilitado: ViewModifier {
    let desabilitado: Bool
    func body(content: Content) -> some View {
        content
            .disabled(desabilitado)
            .saturation(desabilitado ? 0 : 1)
            .opacity(desabilitado ? 0.35 : 1)
            .animation(Movimento.toque, value: desabilitado)
    }
}

extension View {
    func desabilitado(_ sim: Bool) -> some View { modifier(EstiloDesabilitado(desabilitado: sim)) }
}

/// Aperto físico curto: o botão afunda 2% e volta. Sem quique.
struct Apertavel: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Movimento.toque, value: configuration.isPressed)
    }
}

// MARK: - Aviso

/// Aviso de sistema. `firme` é a instrução "entre em contato com o serviço hoje": firme e
/// calmo, parado, sem sirene. Não existe tom de cor clínica aqui — gravidade de MENSAGEM
/// não é classificação de paciente.
struct Aviso: View {
    enum Tom { case firme, informacao }

    let tom: Tom
    let titulo: String
    var texto: String?

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: tom == .firme ? "phone.fill" : "info.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(tom == .firme ? Cor.papel : Cor.ameixa)
                .frame(width: 40, height: 40)
                .background(tom == .firme ? Cor.tinta : Cor.lavanda, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(titulo).tipo(.resposta).foregroundStyle(Cor.tinta)
                if let texto {
                    Text(texto).tipo(.ajuda).foregroundStyle(Cor.tintaSuave)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Espaco.cartao)
        .superficie(fundo: tom == .firme ? Cor.lavanda : Cor.folha)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Estados

/// Esqueleto que imita o layout real (cartões em areia), sem shimmer rápido.
struct Esqueleto: View {
    var linhas = 3

    var body: some View {
        VStack(alignment: .leading, spacing: Espaco.entreCartoes) {
            ForEach(0..<linhas, id: \.self) { i in
                Canto.forma(Canto.cartao)
                    .fill(Cor.areia)
                    .frame(height: i == 0 ? 180 : 96)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Carregando")
    }
}

/// Estado vazio: frase dita por extenso, nunca "Nenhum item".
struct EstadoVazio: View {
    let titulo: String
    var texto: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titulo).tipo(.resposta).foregroundStyle(Cor.tinta)
            if let texto { Text(texto).tipo(.ajuda).foregroundStyle(Cor.tintaSuave) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Espaco.cartao)
        .background(Cor.areia.opacity(0.6), in: Canto.forma(Canto.cartao))
        .accessibilityElement(children: .combine)
    }
}

/// Erro de carregamento: diz o que não veio e oferece tentar de novo.
struct ErroDeCarga: View {
    let mensagem: String
    let tentar: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Aviso(tom: .informacao, titulo: "Não carregou", texto: mensagem)
            BotaoPrincipal(titulo: "Tentar de novo", discreto: true, acao: tentar)
        }
    }
}

/// "Não validado clinicamente": areia com tinta, discreto e legível.
struct SeloDeNaoValidado: View {
    var body: some View {
        Text("Não validado clinicamente")
            .tipo(.rotulo)
            .foregroundStyle(Cor.tinta)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Cor.areia, in: Capsule())
    }
}

// MARK: - Cabeçalho de tela

/// Título de tela próprio (não o large title padrão), com apoio opcional.
struct CabecalhoDeTela: View {
    let titulo: String
    var apoio: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo).tipo(.titulo).foregroundStyle(Cor.tinta)
                .accessibilityAddTraits(.isHeader)
            if let apoio { Text(apoio).tipo(.ajuda).foregroundStyle(Cor.tintaSuave) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
