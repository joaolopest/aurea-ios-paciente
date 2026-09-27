import SwiftUI

/// Hoje: uma pergunta central — o check-in de hoje está pendente ou feito? — com o ciclo
/// em números neutros e o próximo compromisso.
struct HojeView: View {
    @Bindable var store: HojeStore
    let abrirCheckin: () -> Void
    let registrarSintoma: () -> Void
    @Environment(Sessao.self) private var sessao
    @State private var mostrandoConta = false

    var body: some View {
        ZStack {
            FundoDePapel(composicao: .manha)
            ScrollView {
                VStack(alignment: .leading, spacing: Espaco.entreSecoes) {
                    cabecalho
                    switch store.carga {
                    case .carregando:
                        Esqueleto(linhas: 3)
                    case .erro(let mensagem) where store.perfil == nil:
                        ErroDeCarga(mensagem: mensagem) { Task { await store.carregar() } }
                    default:
                        if let instrucao = store.instrucaoDeRegistro, !pedeContatoNoCheckin {
                            avisoDeContato(instrucao)
                        }
                        cartaoDoDia
                        CartaoDeRegistro(registrosDeHoje: store.registrosDeHoje, acao: registrarSintoma)
                        if let ciclo = store.ciclo { BlocoDoCiclo(ciclo: ciclo) }
                        cartaoDoProximo
                        NavigationLink(value: RotaDeHoje.contato) {
                            LinhaDeAtalho(titulo: "Falar com a enfermagem", icone: "phone")
                        }
                        .buttonStyle(Apertavel())
                    }
                }
                .padding(.horizontal, Espaco.margem)
                .padding(.bottom, 32)
            }
            .refreshable { await store.carregar() }
            .veuDoTopo()
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: RotaDeHoje.self) { rota in
            switch rota {
            case .contato: ContatoView()
            case .avisos: AvisosView()
            }
        }
        .sheet(isPresented: $mostrandoConta) {
            NavigationStack { ContaView() }
        }
    }

    // MARK: Cabeçalho

    private var cabecalho: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "pt_BR"))).capitalizandoPrimeira)
                    .tipo(.rotulo)
                    .foregroundStyle(Cor.tintaSuave)
                Text(saudacao)
                    .tipo(.saudacao)
                    .foregroundStyle(Cor.tinta)
                    .accessibilityAddTraits(.isHeader)
            }
            Spacer()
            HStack(spacing: 8) {
                NavigationLink(value: RotaDeHoje.avisos) {
                    BotaoRedondo(icone: "bell")
                }
                .accessibilityLabel("Avisos da equipe")
                Button { mostrandoConta = true } label: {
                    BotaoRedondo(icone: "person")
                }
                .accessibilityLabel("Sua conta")
            }
        }
        .padding(.top, 12)
    }

    private var saudacao: String {
        let hora = Calendar.current.component(.hour, from: .now)
        let parte = hora < 12 ? "Bom dia" : hora < 18 ? "Boa tarde" : "Boa noite"
        if let nome = sessao.eu?.primeiroNome { return "\(parte), \(nome)" }
        return parte
    }

    private var pedeContatoNoCheckin: Bool {
        if case .respondido(let r) = store.estadoDoDia { return r.pedeContatoComServico }
        return false
    }

    private func avisoDeContato(_ retorno: RetornoDoCheckin) -> some View {
        VStack(alignment: .leading, spacing: Espaco.entreCartoes) {
            Aviso(
                tom: .firme,
                titulo: "Entre em contato com o serviço hoje",
                texto: "Pelo que você contou, a equipe pede que você fale com o serviço ainda hoje."
            )
            NavigationLink(value: RotaDeHoje.contato) {
                Text("Falar com a enfermagem")
                    .tipo(.resposta)
                    .foregroundStyle(Cor.papel)
                    .frame(maxWidth: .infinity, minHeight: Espaco.alvoDoCheckin)
                    .background(Cor.tinta, in: Canto.forma(Canto.botao))
            }
            .buttonStyle(Apertavel())
            ForEach(retorno.orientacoes) { CartaoDeOrientacao(orientacao: $0) }
        }
    }

    // MARK: Cartão do dia

    @ViewBuilder
    private var cartaoDoDia: some View {
        switch store.estadoDoDia {
        case .pendente:
            CartaoDeChamada(
                titulo: "Como você está hoje?",
                texto: "Leva cerca de dois minutos. Você pode parar no meio e voltar depois.",
                botao: "Começar",
                acao: abrirCheckin
            )
        case .emAndamento(let local):
            CartaoDeChamada(
                titulo: "Você começou o check-in de hoje",
                texto: local ? "Suas respostas estão guardadas. Continue de onde parou." : "Faltam algumas perguntas. Responda de novo quando puder.",
                botao: local ? "Continuar de onde parei" : "Responder agora",
                acao: abrirCheckin
            )
        case .respondido(let retorno):
            VStack(alignment: .leading, spacing: Espaco.entreCartoes) {
                if retorno.pedeContatoComServico {
                    Aviso(
                        tom: .firme,
                        titulo: "Entre em contato com o serviço hoje",
                        texto: "Pelo que você contou, a equipe pede que você fale com o serviço ainda hoje."
                    )
                    NavigationLink(value: RotaDeHoje.contato) {
                        Text("Falar com a enfermagem")
                            .tipo(.resposta)
                            .foregroundStyle(Cor.papel)
                            .frame(maxWidth: .infinity, minHeight: Espaco.alvoDoCheckin)
                            .background(Cor.tinta, in: Canto.forma(Canto.botao))
                    }
                    .buttonStyle(Apertavel())
                }
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Check-in de hoje").tipo(.rotulo).foregroundStyle(Cor.ameixa)
                        Text("Suas respostas de hoje chegaram à equipe.")
                            .tipo(.titulo)
                            .foregroundStyle(Cor.tinta)
                    }
                    // Responder quantas vezes quiser: o quadro muda ao longo do dia, e cada
                    // envio vira uma sessão nova no servidor (chave de idempotência nova).
                    BotaoPrincipal(titulo: "Responder de novo", discreto: true, acao: abrirCheckin)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Espaco.cartao)
                .superficie()
                ForEach(retorno.orientacoes) { CartaoDeOrientacao(orientacao: $0) }
            }
        }
    }

    // MARK: Próximo compromisso

    private var cartaoDoProximo: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Próximo compromisso").tipo(.rotulo).foregroundStyle(Cor.ameixa)
            if let item = store.proximo {
                Text(Rotulos.evento(item.tipo)).tipo(.resposta).foregroundStyle(Cor.tinta)
                Text(Formato.quando(item.aconteceEm) + (item.local.map { " · \($0)" } ?? ""))
                    .tipo(.ajuda)
                    .foregroundStyle(Cor.tintaSuave)
            } else {
                Text("Nada marcado por enquanto.").tipo(.resposta).foregroundStyle(Cor.tinta)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Espaco.cartao)
        .superficie()
        .accessibilityElement(children: .combine)
    }
}

enum RotaDeHoje: Hashable { case contato, avisos }

// MARK: - Peças de Hoje

/// Registrar um sintoma a qualquer hora, sem esperar o check-in do dia seguinte.
/// Sempre visível: a febre das 16h não espera o check-in de amanhã.
struct CartaoDeRegistro: View {
    let registrosDeHoje: Int
    let acao: () -> Void

    var body: some View {
        Button(action: acao) {
            HStack(spacing: 16) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Cor.papel)
                    .frame(width: 52, height: 52)
                    .background(Cor.ameixa, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Registrar um sintoma")
                        .tipo(.resposta)
                        .foregroundStyle(Cor.tinta)
                    Text(apoio)
                        .tipo(.ajuda)
                        .foregroundStyle(Cor.tintaSuave)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(Espaco.cartao)
            .frame(maxWidth: .infinity, alignment: .leading)
            .superficie(fundo: Cor.lavanda)
            .contentShape(Canto.forma(Canto.cartao))
        }
        .buttonStyle(Apertavel())
        .accessibilityHint("Conte um sintoma agora, sem esperar o check-in.")
    }

    private var apoio: String {
        switch registrosDeHoje {
        case 0: "Sentiu alguma coisa? Conte agora, a qualquer hora do dia."
        case 1: "Você registrou 1 sintoma hoje. Pode registrar outro."
        default: "Você fez \(registrosDeHoje) registros hoje. Pode registrar outro."
        }
    }
}

/// O maior elemento da tela: a pergunta do dia e o CTA.
struct CartaoDeChamada: View {
    let titulo: String
    let texto: String
    let botao: String
    let acao: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(titulo).tipo(.pergunta).foregroundStyle(Cor.tinta)
            Text(texto).tipo(.ajuda).foregroundStyle(Cor.tintaSuave)
            BotaoPrincipal(titulo: botao, acao: acao).padding(.top, 4)
        }
        .padding(Espaco.cartao + 4)
        .superficie()
    }
}

/// Ciclo em números neutros. Nenhum é classificação, nenhum é colorido.
struct BlocoDoCiclo: View {
    let ciclo: HojeStore.Ciclo

    var body: some View {
        VStack(alignment: .leading, spacing: Espaco.entreCartoes) {
            HStack(spacing: 10) {
                celula("Ciclo", "\(ciclo.numero)", nil)
                if let dia = ciclo.dia {
                    celula("Dia", "\(dia)", ciclo.totalDoCiclo.map { "de \($0)" } ?? (ciclo.previsaoVencida != nil ? "desde a sessão" : nil))
                }
                if let faltam = ciclo.faltam {
                    celula("Próxima sessão", faltam == 0 ? "Hoje" : "\(faltam)", faltam == 0 ? nil : (faltam == 1 ? "dia" : "dias"))
                }
            }
            if let frase = ciclo.previsaoVencida {
                Text(frase)
                    .tipo(.ajuda)
                    .foregroundStyle(Cor.tintaSuave)
                    .padding(.horizontal, 4)
            }
        }
    }

    private func celula(_ rotulo: String, _ valor: String, _ apoio: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(rotulo).tipo(.rotulo).foregroundStyle(Cor.tintaSuave)
            Text(valor).tipo(.numero).monospacedDigit().foregroundStyle(Cor.tinta)
            Text(apoio ?? " ").tipo(.rotulo).foregroundStyle(Cor.tintaSuave)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .superficie(raio: Canto.resposta)
        .accessibilityElement(children: .combine)
    }
}

struct LinhaDeAtalho: View {
    let titulo: String
    let icone: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icone)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Cor.tinta)
                .frame(width: 40, height: 40)
                .background(Cor.ceu, in: Circle())
                .accessibilityHidden(true)
            Text(titulo).tipo(.resposta).foregroundStyle(Cor.tinta)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Cor.tintaSuave)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: Espaco.alvoDoCheckin + 8)
        .superficie(raio: Canto.resposta)
    }
}

struct BotaoRedondo: View {
    let icone: String

    var body: some View {
        Image(systemName: icone)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Cor.tinta)
            .frame(width: 48, height: 48)
            .background(Cor.folha, in: Circle())
            .shadow(color: Cor.sombra.opacity(0.10), radius: 10, y: 4)
    }
}

// MARK: - Formato

enum Formato {
    private static let ptBR = Locale(identifier: "pt_BR")

    /// "5 de outubro às 11:00" — instante real, no fuso do aparelho.
    static func quando(_ data: Date) -> String {
        let dia = data.formatted(.dateTime.day().month(.wide).locale(ptBR))
        let hora = data.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(ptBR))
        return "\(dia) às \(hora)"
    }

    /// "hoje", "ontem" ou "sexta" — para linhas de lista.
    static func diaRelativo(_ data: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(data) { return "hoje" }
        if cal.isDateInYesterday(data) { return "ontem" }
        // Abreviado ("sex."): na coluna de 60pt o nome inteiro corta ("sexta-fe…").
        return data.formatted(.dateTime.weekday(.abbreviated).locale(ptBR))
    }
}

extension DataCivil {
    /// "17 de agosto" — data civil da API, sem o ano.
    static func porExtensoSemAno(_ data: Date) -> String {
        var estilo = Date.FormatStyle.dateTime.day().month(.wide)
        estilo.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        estilo.locale = Locale(identifier: "pt_BR")
        return data.formatted(estilo)
    }
}

extension String {
    /// "sábado, 26 de setembro" → "Sábado, 26 de setembro".
    var capitalizandoPrimeira: String { prefix(1).uppercased() + dropFirst() }
}
