import SwiftUI

/// O check-in em modo foco (Steady): sem abas, sem barra de navegação. Uma pergunta por
/// tela, o toque avança sozinho, alvo de 56pt, progresso em pontos.
///
/// "P2 — a tela mais importante do sistema", nas palavras do web. Quem responde pode estar
/// nauseado: nada desliza para o lado, o fundo não se mexe, e nenhuma palavra avalia o
/// estado de saúde da pessoa.
struct CheckinView: View {
    @State var store: CheckinStore
    @Environment(\.dismiss) private var fechar
    @State private var confirmandoSaida = false
    @State private var falandoComEnfermagem = false

    var body: some View {
        ZStack {
            FundoDePapel(composicao: .foco)
            conteudo
                .animation(Movimento.interface, value: store.indice)
                .animation(Movimento.interface, value: store.fase)
        }
        .task {
            if case .carregando = store.fase { await store.carregar() }
        }
        // Alerta, não confirmationDialog: no iOS 26 o diálogo esconde o "cancelar" como
        // toque fora, e quem tem pouca intimidade com o celular precisa ver a saída segura.
        .alert("Parar por agora?", isPresented: $confirmandoSaida) {
            Button("Continuar respondendo", role: .cancel) {}
            Button("Parar por agora") { fechar() }
        } message: {
            Text("Suas respostas ficam guardadas até o fim do dia. Quando voltar, você continua de onde parou.")
        }
        .sheet(isPresented: $falandoComEnfermagem) {
            NavigationStack { ContatoView() }
        }
    }

    @ViewBuilder
    private var conteudo: some View {
        switch store.fase {
        case .carregando:
            VStack { BarraDoFoco(pontos: 0, atual: 0) { fechar() }; Spacer(); Esqueleto(linhas: 2); Spacer() }
                .padding(Espaco.margem)
        case .erroAoCarregar(let mensagem):
            VStack(alignment: .leading, spacing: 20) {
                BarraDoFoco(pontos: 0, atual: 0) { fechar() }
                Spacer()
                ErroDeCarga(mensagem: mensagem) { Task { await store.carregar() } }
                Spacer()
            }
            .padding(Espaco.margem)
        case .escolhendo:
            EscolhaDeSintomas(
                ramos: store.ramos,
                iniciais: store.rascunho.sintomasEscolhidos ?? [],
                continuar: { escolhidos in withAnimation(Movimento.interface) { store.escolher(escolhidos) } },
                sair: sairOuConfirmar
            )
            .transition(Movimento.trocaDePergunta)
        case .respondendo:
            if let passo = store.passoAtual {
                TelaDePergunta(
                    passo: passo,
                    resposta: store.respostaAtual,
                    posicao: store.indice,
                    total: store.passos.count,
                    responder: { valor in Task { await store.responder(valor) } },
                    voltar: {
                        if !withAnimation(Movimento.interface, { store.voltar() }) {
                            sairOuConfirmar()
                        }
                    },
                    sair: sairOuConfirmar
                )
                .id(passo.id)
                .transition(Movimento.trocaDePergunta)
            }
        case .enviando:
            VStack(spacing: 16) {
                ProgressView().tint(Cor.ameixa).controlSize(.large)
                Text("Enviando suas respostas para a equipe")
                    .tipo(.resposta)
                    .foregroundStyle(Cor.tinta)
                    .multilineTextAlignment(.center)
            }
            .padding(Espaco.margem)
            .accessibilityElement(children: .combine)
        case .erroAoEnviar(let mensagem):
            VStack(alignment: .leading, spacing: 16) {
                Spacer()
                Aviso(
                    tom: .informacao,
                    titulo: "Suas respostas não foram enviadas",
                    texto: "\(mensagem) Elas estão guardadas neste iPhone; nada se perdeu."
                )
                BotaoPrincipal(titulo: "Tentar enviar de novo") { Task { await store.enviar() } }
                BotaoPrincipal(titulo: "Parar por agora", discreto: true) { fechar() }
                Spacer()
            }
            .padding(Espaco.margem)
        case .concluido(let retorno):
            FechamentoView(
                retorno: retorno,
                falarComEnfermagem: { falandoComEnfermagem = true },
                voltar: { fechar() }
            )
            .transition(.opacity)
        }
    }

    private func sairOuConfirmar() {
        if store.rascunho.respostas.isEmpty { fechar() } else { confirmandoSaida = true }
    }
}

// MARK: - Barra do foco

/// Pontos de progresso + fechar. Visualmente sem número ("3 de 12" desanima quem está
/// pior, que é justamente quem abre mais ramos); o VoiceOver ouve a contagem.
private struct BarraDoFoco: View {
    let pontos: Int
    let atual: Int
    let sair: () -> Void

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(0..<pontos, id: \.self) { i in
                    Capsule()
                        .fill(i == atual ? Cor.ameixa : Cor.tinta.opacity(i < atual ? 0.45 : 0.18))
                        .frame(width: i == atual ? 20 : 7, height: 7)
                }
            }
            .animation(Movimento.interface, value: atual)
            .animation(Movimento.interface, value: pontos)
            .accessibilityElement()
            .accessibilityLabel(pontos > 0 ? "Pergunta \(atual + 1) de \(pontos)" : "")
            Spacer()
            Button(action: sair) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Cor.tintaSuave)
                    .frame(width: 48, height: 48)
                    .background(Cor.folha, in: Circle())
                    .shadow(color: Cor.sombra.opacity(0.10), radius: 10, y: 4)
            }
            .accessibilityLabel("Parar o check-in")
        }
        .frame(minHeight: Espaco.alvo)
    }
}

// MARK: - Uma pergunta

private struct TelaDePergunta: View {
    let passo: Passo
    let resposta: Valor?
    let posicao: Int
    let total: Int
    let responder: (Valor) -> Void
    let voltar: () -> Void
    let sair: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BarraDoFoco(pontos: total, atual: posicao, sair: sair)
                .padding(.horizontal, Espaco.margem)
                .padding(.top, 8)

            // A pergunta mora EMBAIXO, perto do polegar; o céu respira em cima. Se o texto
            // crescer (Dynamic Type), a coluna rola em vez de cortar.
            GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Spacer(minLength: 24)
                    Text(passo.rotuloDoRamo)
                        .tipo(.rotulo)
                        .foregroundStyle(Cor.ameixa)
                    Text(passo.pergunta.pergunta)
                        .tipo(.pergunta)
                        .foregroundStyle(Cor.tinta)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    if let ajuda = passo.pergunta.ajuda {
                        Text(ajuda).tipo(.ajuda).foregroundStyle(Cor.tintaSuave)
                    }
                    CampoDeResposta(pergunta: passo.pergunta, resposta: resposta, responder: responder)
                        .padding(.top, 10)
                }
                .padding(.horizontal, Espaco.margem)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .bottomLeading)
            }
            .scrollBounceBehavior(.basedOnSize)
            .defaultScrollAnchor(.bottom)
            }

            Button(action: voltar) {
                Text("Voltar")
                    .tipo(.rotulo)
                    .foregroundStyle(Cor.tintaSuave)
                    .frame(maxWidth: .infinity, minHeight: Espaco.alvo)
            }
            .padding(.horizontal, Espaco.margem)
            .padding(.bottom, 8)
        }
    }
}

// MARK: - Registro avulso: o que você está sentindo?

/// A porta do registro avulso: os sintomas em blocos grandes de toque, um ou mais.
/// Escolhido = tinta cheia, como a resposta do check-in. Nenhuma cor por sintoma: cor aqui
/// seria lida como gravidade.
private struct EscolhaDeSintomas: View {
    let ramos: [Ramo]
    let continuar: ([String]) -> Void
    let sair: () -> Void

    @State private var escolhidos: [String]
    @Environment(\.dynamicTypeSize) private var tamanhoDoTexto

    init(ramos: [Ramo], iniciais: [String], continuar: @escaping ([String]) -> Void, sair: @escaping () -> Void) {
        self.ramos = ramos
        self.continuar = continuar
        self.sair = sair
        _escolhidos = State(initialValue: iniciais)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Button(action: sair) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Cor.tintaSuave)
                        .frame(width: 48, height: 48)
                        .background(Cor.folha, in: Circle())
                        .shadow(color: Cor.sombra.opacity(0.10), radius: 10, y: 4)
                }
                .accessibilityLabel("Fechar")
            }
            .padding(.horizontal, Espaco.margem)
            .padding(.top, 8)

            GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Spacer(minLength: 16)
                    Text("Registrar um sintoma").tipo(.rotulo).foregroundStyle(Cor.ameixa)
                    Text("O que você está sentindo?")
                        .tipo(.pergunta)
                        .foregroundStyle(Cor.tinta)
                        .accessibilityAddTraits(.isHeader)
                    Text("Escolha um ou mais. Depois a gente pergunta os detalhes.")
                        .tipo(.ajuda)
                        .foregroundStyle(Cor.tintaSuave)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: tamanhoDoTexto.isAccessibilitySize ? 1 : 2), spacing: 10) {
                        ForEach(ramos) { ramo in
                            BlocoDeSintoma(
                                titulo: ramo.rotulo,
                                icone: Self.icone(ramo.sintoma),
                                escolhido: escolhidos.contains(ramo.sintoma)
                            ) {
                                Tato.selecao()
                                withAnimation(Movimento.toque) {
                                    if let i = escolhidos.firstIndex(of: ramo.sintoma) { escolhidos.remove(at: i) } else { escolhidos.append(ramo.sintoma) }
                                }
                            }
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, Espaco.margem)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .bottomLeading)
            }
            .scrollBounceBehavior(.basedOnSize)
            }

            BotaoPrincipal(titulo: escolhidos.count > 1 ? "Continuar com \(escolhidos.count) sintomas" : "Continuar") {
                // Mantém a ordem da árvore, não a ordem dos toques.
                continuar(ramos.map(\.sintoma).filter(escolhidos.contains))
            }
            .desabilitado(escolhidos.isEmpty)
            .padding(.horizontal, Espaco.margem)
            .padding(.bottom, 12)
        }
    }

    /// Ícone por sintoma. Desconhecido (sintoma novo na API) cai num genérico, nunca some.
    static func icone(_ sintoma: String) -> String {
        switch sintoma {
        case "FEBRE": "thermometer.medium"
        case "DIARREIA": "toilet"
        case "NAUSEA_VOMITO": "mouth"
        case "DOR": "bandage"
        case "FALTA_DE_AR": "lungs"
        default: "plus.circle"
        }
    }
}

private struct BlocoDeSintoma: View {
    let titulo: String
    let icone: String
    let escolhido: Bool
    let acao: () -> Void

    var body: some View {
        Button(action: acao) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Image(systemName: icone)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(escolhido ? Cor.papel : Cor.tinta)
                        .frame(width: 48, height: 48)
                        .background(escolhido ? Cor.papel.opacity(0.18) : Cor.ceu, in: Circle())
                    Spacer()
                    Image(systemName: escolhido ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(escolhido ? Cor.papel : Cor.linha)
                }
                .accessibilityHidden(true)
                Text(titulo)
                    .tipo(.resposta)
                    .foregroundStyle(escolhido ? Cor.papel : Cor.tinta)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
            .superficie(raio: Canto.cartao, fundo: escolhido ? Cor.tinta : Cor.folha)
            .contentShape(Canto.forma(Canto.cartao))
        }
        .buttonStyle(Apertavel())
        .accessibilityLabel(titulo)
        .accessibilityAddTraits(escolhido ? [.isSelected, .isButton] : .isButton)
    }
}
