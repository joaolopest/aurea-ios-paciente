import SwiftUI

/// Seu tratamento. Primeiro o mural — o que a pessoa vem buscar: os sintomas que o AUREA
/// acompanha, explicados no ritmo dela. Depois o cadastro, que é consulta pontual.
struct TratamentoView: View {
    @State private var carga = Carga<PerfilDoPaciente> { try await ClienteAPI.compartilhado.obter("/paciente/perfil") }

    var body: some View {
        TelaDeConsulta(titulo: "Seu tratamento", apoio: "O que a equipe explicou na consulta, para reler quando quiser.", carga: carga) { perfil in
            BlocoDoProtocolo(perfil: perfil)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    RotuloDeSecao("O que pode aparecer")
                    Spacer()
                    if !VerbeteDoMural.textoRevisadoPelaClinica { SeloDeNaoValidado() }
                }
                Text("São os sintomas sobre os quais o AUREA pergunta todo dia. Toque em um para ler o que costuma acontecer, o que dá para fazer em casa e quando procurar a equipe.")
                    .tipo(.ajuda)
                    .foregroundStyle(Cor.tintaSuave)
                ForEach(VerbeteDoMural.todos) { verbete in
                    NavigationLink(value: verbete.sintoma) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(verbete.titulo).tipo(.resposta).foregroundStyle(Cor.tinta)
                                Spacer()
                                Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold)).foregroundStyle(Cor.tintaSuave)
                                    .accessibilityHidden(true)
                            }
                            Text(verbete.resumo).tipo(.ajuda).foregroundStyle(Cor.tintaSuave).multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Espaco.cartao)
                        .superficie()
                    }
                    .buttonStyle(Apertavel())
                }
            }

            BlocoDeContatos(perfil: perfil)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    RotuloDeSecao("Alergias")
                    Spacer()
                    NavigationLink("Ver e adicionar") { AlergiasView(iniciais: perfil.alergias) }
                        .tipo(.rotulo)
                        .foregroundStyle(Cor.ameixa)
                        .frame(minHeight: Espaco.alvo)
                }
                Text(perfil.alergias.isEmpty ? "Nenhuma alergia registrada." : perfil.alergias.map(\.descricao).joined(separator: ", "))
                    .tipo(.leitura)
                    .foregroundStyle(Cor.tinta)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Espaco.cartao)
                    .superficie()
            }
        }
        .navigationDestination(for: String.self) { sintoma in
            if let verbete = VerbeteDoMural.todos.first(where: { $0.sintoma == sintoma }) {
                VerbeteDoMuralView(verbete: verbete)
            }
        }
    }
}

private struct BlocoDoProtocolo: View {
    let perfil: PerfilDoPaciente

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RotuloDeSecao("Protocolo")
            Text(perfil.tratamento?.protocolo?.nome ?? "Nenhum tratamento registrado.")
                .tipo(.titulo)
                .foregroundStyle(Cor.tinta)
            if let ciclo = perfil.ciclo {
                Text(ciclo.diaDoCiclo.map { "Ciclo \(ciclo.numero), dia \($0)" } ?? "Ciclo \(ciclo.numero)")
                    .tipo(.leitura).foregroundStyle(Cor.tinta)
                if let previsao = ciclo.previsaoDaProximaSessao {
                    Text("Próxima sessão prevista: \(DataCivil.porExtensoSemAno(previsao))")
                        .tipo(.ajuda).foregroundStyle(Cor.tintaSuave)
                }
            }
            if let medico = perfil.medicoAssistente {
                Divider().overlay(Cor.linha).padding(.vertical, 6)
                Text("Médico assistente").tipo(.rotulo).foregroundStyle(Cor.tintaSuave)
                Text(medico.nome).tipo(.resposta).foregroundStyle(Cor.tinta)
                if let registro = medico.registroDoConselho {
                    Text(registro).tipo(.ajuda).foregroundStyle(Cor.tintaSuave)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Espaco.cartao)
        .superficie()
        .accessibilityElement(children: .combine)
    }
}

private struct BlocoDeContatos: View {
    let perfil: PerfilDoPaciente

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RotuloDeSecao("Contatos")
            let todos = perfil.contatos.doPaciente.map { ($0, "Seu contato") } + perfil.contatos.deEmergencia.map { ($0, "Contato de emergência") }
            if todos.isEmpty {
                EstadoVazio(titulo: "Nenhum contato registrado.")
            }
            ForEach(todos, id: \.0.id) { contato, papel in
                VStack(alignment: .leading, spacing: 4) {
                    Text(papel).tipo(.rotulo).foregroundStyle(Cor.tintaSuave)
                    Text(contato.relacao.map { "\(contato.nome) (\($0))" } ?? contato.nome)
                        .tipo(.resposta).foregroundStyle(Cor.tinta)
                    if let telefone = contato.telefone {
                        Text(Self.formatar(telefone))
                            .tipo(.leitura)
                            .monospacedDigit()
                            .foregroundStyle(Cor.tinta)
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Espaco.cartao)
                .superficie()
            }
        }
    }

    /// 79911111111 → (79) 91111-1111
    static func formatar(_ t: String) -> String {
        let d = Array(t.filter(\.isNumber))
        guard d.count == 11 || d.count == 10 else { return t }
        let ddd = String(d[0..<2]), meio = d.count == 11 ? String(d[2..<7]) : String(d[2..<6]), fim = String(d.suffix(4))
        return "(\(ddd)) \(meio)-\(fim)"
    }
}

/// Um sintoma do mural em página própria. O "quando procurar" nunca aparece longe do
/// "o que esperar" (regra do próprio mural).
struct VerbeteDoMuralView: View {
    let verbete: VerbeteDoMural

    var body: some View {
        ZStack {
            FundoDePapel(composicao: .discreto)
            ScrollView {
                VStack(alignment: .leading, spacing: Espaco.entreSecoes) {
                    VStack(alignment: .leading, spacing: 10) {
                        if !VerbeteDoMural.textoRevisadoPelaClinica { SeloDeNaoValidado() }
                        Text(verbete.titulo).tipo(.titulo).foregroundStyle(Cor.tinta).accessibilityAddTraits(.isHeader)
                        Text(verbete.resumo).tipo(.leitura).foregroundStyle(Cor.tinta)
                    }
                    secao("Por que acontece", [verbete.porQueAcontece])
                    secao("O que costuma acontecer", verbete.oQueEsperar)
                    secao("O que dá para fazer em casa", verbete.emCasa)
                    VStack(alignment: .leading, spacing: 10) {
                        RotuloDeSecao("Quando procurar a equipe")
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(verbete.quandoProcurar, id: \.self) { item(texto: $0) }
                        }
                        .padding(Espaco.cartao)
                        .superficie(fundo: Cor.lavanda)
                    }
                }
                .padding(.horizontal, Espaco.margem)
                .padding(.vertical, 12)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func secao(_ titulo: String, _ itens: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            RotuloDeSecao(titulo)
            ForEach(itens, id: \.self) { item(texto: $0) }
        }
    }

    private func item(texto: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Circle().fill(Cor.ameixa).frame(width: 6, height: 6).alignmentGuide(.firstTextBaseline) { $0[.bottom] + 2 }
                .accessibilityHidden(true)
            Text(texto).tipo(.leitura).foregroundStyle(Cor.tinta).fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Alergias: lista e sugestão nova. Só a substância — `reacao` não tem coluna
/// (docs/CONTORNOS.md, C-04). A sugestão vai para a equipe conferir.
struct AlergiasView: View {
    let iniciais: [Alergia]
    @State private var alergias: [Alergia] = []
    @State private var substancia = ""
    @State private var enviando = false
    @State private var aviso: String?
    @State private var erro: String?

    var body: some View {
        ZStack {
            FundoDePapel(composicao: .discreto)
            ScrollView {
                VStack(alignment: .leading, spacing: Espaco.entreSecoes) {
                    CabecalhoDeTela(titulo: "Alergias", apoio: "O que já está registrado e como avisar a equipe de uma nova.")
                    VStack(alignment: .leading, spacing: 10) {
                        RotuloDeSecao("Registradas")
                        if alergias.isEmpty {
                            EstadoVazio(titulo: "Nenhuma alergia registrada ainda.")
                        }
                        ForEach(alergias) { alergia in
                            HStack {
                                Text(alergia.descricao).tipo(.resposta).foregroundStyle(Cor.tinta)
                                Spacer()
                                if alergia.confirmada == false {
                                    Text("A equipe vai conferir").tipo(.rotulo).foregroundStyle(Cor.tintaSuave)
                                }
                            }
                            .padding(Espaco.cartao)
                            .superficie()
                        }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        RotuloDeSecao("Avisar de uma alergia")
                        CampoDeTexto(rotulo: "Substância ou remédio", texto: $substancia, ajuda: "Por exemplo: dipirona.")
                        if let aviso { Aviso(tom: .informacao, titulo: aviso) }
                        if let erro { Aviso(tom: .informacao, titulo: "Não foi registrado", texto: erro) }
                        BotaoPrincipal(titulo: "Avisar a equipe", carregando: enviando) { Task { await registrar() } }
                            .desabilitado(substancia.trimmingCharacters(in: .whitespaces).count < 2)
                    }
                }
                .padding(.horizontal, Espaco.margem)
                .padding(.vertical, 12)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if alergias.isEmpty { alergias = iniciais } }
    }

    /// Grava e RELÊ do servidor: o web já disse "enviado à equipe" com a alergia morando
    /// só no navegador (commit 481b734).
    private func registrar() async {
        struct Corpo: Encodable, Sendable { let descricao: String }
        enviando = true
        aviso = nil
        erro = nil
        defer { enviando = false }
        do {
            let _: RespostaDeAlergia = try await ClienteAPI.compartilhado.enviar("/paciente/alergias", corpo: Corpo(descricao: substancia.trimmingCharacters(in: .whitespaces)))
            let perfil: PerfilDoPaciente = try await ClienteAPI.compartilhado.obter("/paciente/perfil")
            alergias = perfil.alergias
            substancia = ""
            aviso = "Registrado. A equipe vai conferir."
        } catch let e as ErroDaAPI {
            erro = e.mensagem
        } catch {
            erro = "Tente de novo em instantes."
        }
    }
}
