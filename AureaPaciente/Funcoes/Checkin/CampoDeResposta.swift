import SwiftUI

/// O campo certo para cada tipo de pergunta. Toque = resposta; nada de botão "Enviar"
/// separado, exceto onde a pessoa digita (temperatura).
struct CampoDeResposta: View {
    let pergunta: Pergunta
    let resposta: Valor?
    let responder: (Valor) -> Void

    var body: some View {
        switch pergunta.tipo {
        case .simOuNao:
            VStack(spacing: 14) {
                BotaoDeResposta(titulo: "Sim", icone: "circle", selecionado: resposta == .booleano(true)) { responder(.booleano(true)) }
                BotaoDeResposta(titulo: "Não", icone: "minus", selecionado: resposta == .booleano(false)) { responder(.booleano(false)) }
            }
        case .opcao:
            VStack(spacing: 12) {
                ForEach(pergunta.opcoes ?? [], id: \.self) { opcao in
                    BotaoDeResposta(titulo: Rotulos.opcao(opcao), icone: nil, selecionado: resposta == .texto(opcao)) {
                        responder(.texto(opcao))
                    }
                }
            }
        case .inteiro:
            let minimo = Int(pergunta.minimo ?? 0)
            let maximo = Int(pergunta.maximo ?? 30)
            if minimo == 0, maximo == 10 {
                EscalaDeZeroADez(selecionado: valorInteiro, responder: { responder(.numero(Double($0))) })
            } else {
                Contador(minimo: minimo, maximo: maximo, inicial: valorInteiro, responder: { responder(.numero(Double($0))) })
            }
        case .numero:
            CampoNumerico(pergunta: pergunta, inicial: valorNumero, responder: { responder(.numero($0)) })
        case .desconhecido:
            // Tipo novo na API que este app não conhece: diz, em vez de travar.
            Aviso(tom: .informacao, titulo: "Esta pergunta precisa do app atualizado", texto: "Atualize o AUREA pela App Store. Suas outras respostas ficam guardadas.")
        }
    }

    private var valorInteiro: Int? {
        if case .numero(let n) = resposta { return Int(n) }
        return nil
    }

    private var valorNumero: Double? {
        if case .numero(let n) = resposta { return n }
        return nil
    }
}

// MARK: - Botão de resposta

/// 56pt, folha, ícone em círculo de céu. Selecionado: enche de tinta, texto creme. Nunca
/// um check verde.
struct BotaoDeResposta: View {
    let titulo: String
    let icone: String?
    let selecionado: Bool
    let acao: () -> Void

    @State private var apertado = false

    var body: some View {
        Button {
            Tato.selecao()
            withAnimation(Movimento.toque) { apertado = true }
            // A pessoa VÊ a escolha antes de a pergunta trocar.
            Task {
                try? await Task.sleep(for: .milliseconds(220))
                acao()
                apertado = false
            }
        } label: {
            HStack(spacing: 14) {
                if let icone {
                    Image(systemName: icone)
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(ativo ? Cor.papel : Cor.tinta)
                        .frame(width: 44, height: 44)
                        .background(ativo ? Cor.papel.opacity(0.2) : Cor.ceu, in: Circle())
                        .accessibilityHidden(true)
                }
                Text(titulo)
                    .tipo(.resposta)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .foregroundStyle(ativo ? Cor.papel : Cor.tinta)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: Espaco.resposta, alignment: .leading)
            .superficie(raio: Canto.resposta, fundo: ativo ? Cor.tinta : Cor.folha)
            .contentShape(Canto.forma(Canto.resposta))
        }
        .buttonStyle(Apertavel())
        .accessibilityAddTraits(selecionado ? .isSelected : [])
    }

    private var ativo: Bool { selecionado || apertado }
}

// MARK: - Escala 0 a 10

/// Dor de 0 a 10: onze alvos, número grande, sem gradiente de cor (cor aqui seria
/// classificação). No tamanho de texto máximo, os alvos empilham em mais linhas.
struct EscalaDeZeroADez: View {
    let selecionado: Int?
    let responder: (Int) -> Void

    @Environment(\.dynamicTypeSize) private var tamanhoDoTexto
    @State private var tocado: Int?

    private var colunas: Int { tamanhoDoTexto.isAccessibilitySize ? 3 : 6 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: colunas), spacing: 10) {
                ForEach(0...10, id: \.self) { n in
                    let ativo = (tocado ?? selecionado) == n
                    Button {
                        Tato.selecao()
                        withAnimation(Movimento.toque) { tocado = n }
                        Task {
                            try? await Task.sleep(for: .milliseconds(220))
                            responder(n)
                        }
                    } label: {
                        Text("\(n)")
                            .tipo(.numero)
                            .monospacedDigit()
                            .foregroundStyle(ativo ? Cor.papel : Cor.tinta)
                            .frame(maxWidth: .infinity, minHeight: 64)
                            .superficie(raio: Canto.resposta, fundo: ativo ? Cor.tinta : Cor.folha)
                    }
                    .buttonStyle(Apertavel())
                    .accessibilityLabel(n == 0 ? "0, sem dor" : n == 10 ? "10, a pior dor" : "\(n)")
                    .accessibilityAddTraits(ativo ? .isSelected : [])
                }
            }
            HStack {
                Text("0 · sem dor")
                Spacer()
                Text("10 · a pior dor")
            }
            .tipo(.rotulo)
            .foregroundStyle(Cor.tintaSuave)
            .accessibilityHidden(true)
        }
    }
}

// MARK: - Contador

/// Contagem pequena (vezes ao banheiro, vômitos): menos e mais grandes, sem teclado.
struct Contador: View {
    let minimo: Int
    let maximo: Int
    let inicial: Int?
    let responder: (Int) -> Void

    @State private var valor: Int

    init(minimo: Int, maximo: Int, inicial: Int?, responder: @escaping (Int) -> Void) {
        self.minimo = minimo
        self.maximo = maximo
        self.inicial = inicial
        self.responder = responder
        _valor = State(initialValue: inicial ?? minimo)
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                botao("minus", "Menos um", habilitado: valor > minimo) { valor -= 1 }
                Text("\(valor)")
                    .font(.nunito(64))
                    .monospacedDigit()
                    .foregroundStyle(Cor.tinta)
                    .frame(maxWidth: .infinity)
                    .contentTransition(.numericText(value: Double(valor)))
                    .accessibilityHidden(true)
                botao("plus", "Mais um", habilitado: valor < maximo) { valor += 1 }
            }
            .padding(12)
            .superficie()
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(valor) vezes")
            .accessibilityAdjustableAction { direcao in
                switch direcao {
                case .increment: if valor < maximo { valor += 1 }
                case .decrement: if valor > minimo { valor -= 1 }
                @unknown default: break
                }
            }

            BotaoPrincipal(titulo: valor == 1 ? "Foi 1 vez" : "Foram \(valor) vezes") {
                Tato.selecao()
                responder(valor)
            }
        }
    }

    private func botao(_ icone: String, _ rotulo: String, habilitado: Bool, acao: @escaping () -> Void) -> some View {
        Button {
            Tato.selecao()
            withAnimation(Movimento.toque) { acao() }
        } label: {
            Image(systemName: icone)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Cor.tinta)
                .frame(width: 64, height: 64)
                .background(Cor.ceu, in: Circle())
        }
        .buttonStyle(Apertavel())
        .desabilitado(!habilitado)
        .accessibilityLabel(rotulo)
    }
}

// MARK: - Número digitado

/// Temperatura: teclado decimal, vírgula ou ponto, limites ditos em frase.
struct CampoNumerico: View {
    let pergunta: Pergunta
    let inicial: Double?
    let responder: (Double) -> Void

    @State private var texto: String
    @State private var erro: String?
    @FocusState private var focado: Bool

    init(pergunta: Pergunta, inicial: Double?, responder: @escaping (Double) -> Void) {
        self.pergunta = pergunta
        self.inicial = inicial
        self.responder = responder
        _texto = State(initialValue: inicial.map { Self.formatar($0, casas: pergunta.casasDecimais ?? 1) } ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                TextField("", text: $texto, prompt: Text("0,0").foregroundStyle(Cor.tintaSuave.opacity(0.5)))
                    .font(.nunito(56))
                    .monospacedDigit()
                    .foregroundStyle(Cor.tinta)
                    .keyboardType(.decimalPad)
                    .focused($focado)
                    .accessibilityLabel(pergunta.pergunta)
                if let unidade = pergunta.unidade {
                    Text(unidade).tipo(.titulo).foregroundStyle(Cor.tintaSuave)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .superficie()

            Text(erro ?? limites)
                .tipo(.ajuda)
                .foregroundStyle(erro == nil ? Cor.tintaSuave : Cor.tinta)

            BotaoPrincipal(titulo: "Confirmar") { confirmar() }
                .desabilitado(texto.isEmpty)
        }
        .onAppear { focado = true }
    }

    private var limites: String {
        let u = pergunta.unidade.map { " \($0)" } ?? ""
        let casas = pergunta.casasDecimais ?? 0
        switch (pergunta.minimo, pergunta.maximo) {
        case let (min?, max?): return "Entre \(Self.formatar(min, casas: casas)) e \(Self.formatar(max, casas: casas))\(u)."
        case let (min?, nil): return "A partir de \(Self.formatar(min, casas: casas))\(u)."
        case let (nil, max?): return "Até \(Self.formatar(max, casas: casas))\(u)."
        default: return " "
        }
    }

    private func confirmar() {
        let limpo = texto.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        guard let numero = Double(limpo) else {
            erro = "Digite só o número, por exemplo 38,5."
            Tato.aviso()
            return
        }
        if let min = pergunta.minimo, numero < min {
            erro = "O menor valor possível é \(Self.formatar(min, casas: pergunta.casasDecimais ?? 0))\(pergunta.unidade.map { " \($0)" } ?? ""). Confira o número."
            Tato.aviso()
            return
        }
        if let max = pergunta.maximo, numero > max {
            erro = "O maior valor possível é \(Self.formatar(max, casas: pergunta.casasDecimais ?? 0))\(pergunta.unidade.map { " \($0)" } ?? ""). Confira o número."
            Tato.aviso()
            return
        }
        erro = nil
        focado = false
        let casas = pergunta.casasDecimais ?? 0
        let fator = pow(10, Double(casas))
        responder((numero * fator).rounded() / fator)
    }

    static func formatar(_ n: Double, casas: Int) -> String {
        n.formatted(.number.precision(.fractionLength(casas)).locale(Locale(identifier: "pt_BR")))
    }
}
