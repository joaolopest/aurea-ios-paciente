import SwiftUI

// MARK: - Entrar

/// Porta do paciente: CPF e senha. Erro sempre genérico — não revela se a pessoa é
/// paciente do serviço (decisão de privacidade do web).
struct EntradaView: View {
    @Environment(Sessao.self) private var sessao
    @State private var cpf = ""
    @State private var senha = ""
    @State private var mostrandoSenha = false
    @State private var entrando = false
    @State private var erro: String?
    @State private var recuperando = false
    @FocusState private var foco: Campo?

    private enum Campo { case cpf, senha }

    private var pronto: Bool { cpf.filter(\.isNumber).count == 11 && senha.count >= 8 }

    var body: some View {
        ZStack {
            FundoDePapel(composicao: .porta)
            ScrollView {
                VStack(alignment: .leading, spacing: Espaco.entreSecoes) {
                    Marca(tamanho: 56)
                        .padding(.top, 48)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Como você está hoje?")
                            .tipo(.saudacao)
                            .foregroundStyle(Cor.tinta)
                        Text("Entre com o CPF e a senha que a equipe entregou a você.")
                            .tipo(.ajuda)
                            .foregroundStyle(Cor.tintaSuave)
                    }

                    VStack(spacing: 14) {
                        if let aviso = sessao.avisoDeEntrada, erro == nil {
                            Aviso(tom: .informacao, titulo: aviso)
                        }
                        if let erro {
                            Aviso(tom: .informacao, titulo: erro)
                        }

                        CampoDeTexto(rotulo: "CPF", texto: $cpf, teclado: .numberPad, conteudo: .username)
                            .focused($foco, equals: .cpf)
                            .onChange(of: cpf) { _, novo in
                                let mascara = Self.mascarar(novo)
                                if mascara != novo { cpf = mascara }
                            }

                        CampoDeSenha(rotulo: "Senha", texto: $senha, mostrando: $mostrandoSenha, conteudo: .password)
                            .focused($foco, equals: .senha)
                            .submitLabel(.go)
                            .onSubmit { Task { await entrar() } }

                        BotaoPrincipal(titulo: "Entrar", carregando: entrando) {
                            Task { await entrar() }
                        }
                        .desabilitado(!pronto)

                        Button("Esqueci minha senha") { recuperando = true }
                            .tipo(.ajuda)
                            .foregroundStyle(Cor.ameixa)
                            .frame(minHeight: Espaco.alvo)
                    }
                }
                .padding(.horizontal, Espaco.margem)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .sheet(isPresented: $recuperando) { RecuperarView() }
    }

    private func entrar() async {
        guard pronto, !entrando else { return }
        entrando = true
        erro = nil
        defer { entrando = false }
        do {
            try await sessao.entrar(cpf: cpf, senha: senha)
        } catch let e as ErroDaAPI {
            erro = switch e {
            case .semConexao, .bloqueado, .servidor: e.mensagem
            // 401 e 400 viram o mesmo texto: não diz se o CPF existe.
            default: "CPF ou senha não conferem."
            }
        } catch {
            erro = "CPF ou senha não conferem."
        }
    }

    /// 000.000.000-00, enquanto digita.
    static func mascarar(_ texto: String) -> String {
        let d = Array(texto.filter(\.isNumber).prefix(11))
        var saida = ""
        for (i, c) in d.enumerated() {
            if i == 3 || i == 6 { saida.append(".") }
            if i == 9 { saida.append("-") }
            saida.append(c)
        }
        return saida
    }
}

// MARK: - Recuperar

/// Honesta: nesta fase não há recuperação automática. Não finge um e-mail que não chega.
struct RecuperarView: View {
    @Environment(\.dismiss) private var fechar

    var body: some View {
        ZStack {
            FundoDePapel(composicao: .discreto)
            VStack(alignment: .leading, spacing: Espaco.entreSecoes) {
                CabecalhoDeTela(
                    titulo: "Esqueci minha senha",
                    apoio: "Nesta fase, a senha nova é feita com a equipe do serviço onde você faz o tratamento, por telefone ou pessoalmente."
                )
                Aviso(
                    tom: .informacao,
                    titulo: "Leve o seu CPF",
                    texto: "A equipe confere quem é você e entrega uma senha provisória. No primeiro acesso, o app pede para você criar a sua."
                )
                Spacer()
                BotaoPrincipal(titulo: "Voltar para a entrada", discreto: true) { fechar() }
            }
            .padding(Espaco.margem)
            .padding(.top, 24)
        }
        .presentationDetents([.large])
    }
}

// MARK: - Primeiro acesso

/// Troca da senha provisória. A troca revoga as sessões: a pessoa volta para entrar.
struct TrocaDeSenhaView: View {
    @Environment(Sessao.self) private var sessao
    let senhaAtual: String
    @State private var nova = ""
    @State private var confirmacao = ""
    @State private var mostrando = false
    @State private var salvando = false
    @State private var erro: String?

    private var erroDeRegra: String? {
        if !nova.isEmpty, nova.count < 10 { return "A senha precisa ter pelo menos 10 caracteres." }
        if !confirmacao.isEmpty, confirmacao != nova { return "As duas senhas precisam ser iguais." }
        return nil
    }

    private var pronto: Bool { nova.count >= 10 && nova == confirmacao }

    var body: some View {
        ZStack {
            FundoDePapel(composicao: .porta)
            ScrollView {
                VStack(alignment: .leading, spacing: Espaco.entreSecoes) {
                    CabecalhoDeTela(
                        titulo: "Crie a sua senha",
                        apoio: "A senha provisória deixa de valer assim que você salvar a nova. Daqui em diante, só você conhece a sua."
                    )
                    .padding(.top, 48)

                    VStack(spacing: 14) {
                        if let erro { Aviso(tom: .informacao, titulo: erro) }
                        CampoDeSenha(rotulo: "Nova senha", texto: $nova, mostrando: $mostrando, conteudo: .newPassword, ajuda: "Pelo menos 10 caracteres.")
                        CampoDeSenha(rotulo: "Repita a nova senha", texto: $confirmacao, mostrando: $mostrando, conteudo: .newPassword)
                        if let erroDeRegra {
                            Text(erroDeRegra).tipo(.ajuda).foregroundStyle(Cor.tinta)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        BotaoPrincipal(titulo: "Salvar a senha", carregando: salvando) {
                            Task { await salvar() }
                        }
                        .desabilitado(!pronto)
                    }
                }
                .padding(.horizontal, Espaco.margem)
                .padding(.bottom, 40)
            }
        }
    }

    private func salvar() async {
        guard pronto else { return }
        salvando = true
        erro = nil
        defer { salvando = false }
        do {
            try await sessao.trocarSenha(atual: senhaAtual, nova: nova)
        } catch let e as ErroDaAPI {
            erro = e.mensagem
        } catch {
            erro = "A senha não foi trocada. Tente de novo em instantes."
        }
    }
}

// MARK: - Consentimento

/// O termo, lido antes de entrar. A caixa só libera depois de rolar até o fim, e o app
/// só navega depois que o servidor confirma o aceite.
struct ConsentimentoView: View {
    @Environment(Sessao.self) private var sessao
    let versao: String
    @State private var chegouAoFim = false
    @State private var alturaVisivel: CGFloat = 0
    @State private var concordo = false
    @State private var enviando = false
    @State private var erro: String?

    var body: some View {
        ZStack {
            FundoDePapel(composicao: .discreto)
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Espaco.entreSecoes) {
                        CabecalhoDeTela(titulo: "Antes de começar", apoio: "Leia com calma. Você pode voltar a este termo sempre que quiser, na sua conta.")
                            .padding(.top, 32)

                        VStack(alignment: .leading, spacing: 22) {
                            HStack {
                                Text(TermoDeConsentimento.rotulo).tipo(.rotulo).foregroundStyle(Cor.ameixa)
                                Spacer()
                                Text("Versão \(versao)").tipo(.rotulo).foregroundStyle(Cor.tintaSuave)
                            }
                            ForEach(TermoDeConsentimento.secoes) { secao in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(secao.titulo).tipo(.resposta).foregroundStyle(Cor.tinta)
                                        .accessibilityAddTraits(.isHeader)
                                    Text(secao.texto).tipo(.leitura).foregroundStyle(Cor.tintaSuave)
                                }
                            }
                            // Marca o fim do texto. `onAppear` não serve: num VStack ele
                            // dispara ao montar, não ao aparecer. Mede a posição real.
                            Color.clear.frame(height: 1)
                                .onGeometryChange(for: CGFloat.self) { $0.frame(in: .named("termo")).minY } action: { y in
                                    if y <= alturaVisivel { chegouAoFim = true }
                                }
                        }
                        .padding(Espaco.cartao)
                        .superficie()
                    }
                    .padding(.horizontal, Espaco.margem)
                    .padding(.bottom, 24)
                }
                .coordinateSpace(.named("termo"))
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { alturaVisivel = $0 }

                VStack(spacing: 12) {
                    if let erro { Aviso(tom: .informacao, titulo: "Seu aceite não foi registrado", texto: erro) }
                    Toggle(isOn: $concordo) {
                        Text(chegouAoFim ? "Li e concordo com o termo" : "Leia o termo até o fim para concordar")
                            .tipo(.resposta)
                            .foregroundStyle(Cor.tinta)
                    }
                    .toggleStyle(CaixaDeMarcar())
                    .disabled(!chegouAoFim)
                    BotaoPrincipal(titulo: "Concordo e quero começar", carregando: enviando) {
                        Task { await aceitar() }
                    }
                    .desabilitado(!concordo)
                }
                .padding(Espaco.margem)
                .background(Cor.papel.opacity(0.94))
            }
        }
    }

    private func aceitar() async {
        enviando = true
        erro = nil
        defer { enviando = false }
        do {
            try await sessao.aceitarTermo(versao: versao)
        } catch let e as ErroDaAPI {
            erro = e.mensagem
        } catch {
            erro = "Tente de novo em instantes."
        }
    }
}

/// Caixa de marcar grande, em tinta. Nada de check verde.
struct CaixaDeMarcar: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            Tato.selecao()
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Canto.forma(8)
                        .fill(configuration.isOn ? Cor.tinta : Cor.folha)
                        .frame(width: 30, height: 30)
                        .overlay(Canto.forma(8).strokeBorder(configuration.isOn ? Cor.tinta : Cor.tintaSuave, lineWidth: 2))
                    if configuration.isOn {
                        Image(systemName: "checkmark").font(.system(size: 15, weight: .heavy)).foregroundStyle(Cor.papel)
                    }
                }
                configuration.label
                Spacer(minLength: 0)
            }
            .frame(minHeight: Espaco.alvo)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(configuration.isOn ? .isSelected : [])
    }
}
