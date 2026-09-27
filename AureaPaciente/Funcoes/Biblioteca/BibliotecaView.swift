import SwiftUI

/// Os textos que a equipe deixou. Busca sem acento, cartões por categoria em lavanda.
struct BibliotecaView: View {
    @State private var carga = Carga<[VerbeteResumido]> {
        let pagina: Pagina<VerbeteResumido> = try await ClienteAPI.compartilhado.obter("/paciente/biblioteca")
        return pagina.itens
    }
    @State private var busca = ""

    var body: some View {
        TelaDeConsulta(titulo: "Biblioteca", apoio: "Os textos que a sua equipe deixou para você.", carga: carga) { itens in
            SeloDeNaoValidado()
            CampoDeBusca(texto: $busca)
            let filtrados = filtrar(itens)
            if itens.isEmpty {
                EstadoVazio(titulo: "A equipe ainda não publicou textos aqui", texto: "Quando publicar, eles aparecem nesta tela.")
            } else if filtrados.isEmpty {
                EstadoVazio(titulo: "Nada com “\(busca)”", texto: "Tente outra palavra, como enjoo ou febre.")
            } else {
                ForEach(porCategoria(filtrados), id: \.categoria) { grupo in
                    VStack(alignment: .leading, spacing: 10) {
                        RotuloDeSecao(Rotulos.categoria(grupo.categoria))
                        ForEach(grupo.itens) { verbete in
                            NavigationLink(value: verbete.id) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(verbete.titulo).tipo(.resposta).foregroundStyle(Cor.tinta).multilineTextAlignment(.leading)
                                    if let resumo = verbete.resumo {
                                        Text(resumo).tipo(.ajuda).foregroundStyle(Cor.tintaSuave).multilineTextAlignment(.leading)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(Espaco.cartao)
                                .superficie(fundo: Cor.lavanda)
                            }
                            .buttonStyle(Apertavel())
                        }
                    }
                }
            }
        }
        .navigationDestination(for: String.self) { VerbeteView(id: $0) }
    }

    private func filtrar(_ itens: [VerbeteResumido]) -> [VerbeteResumido] {
        let termo = busca.trimmingCharacters(in: .whitespaces).folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
        guard !termo.isEmpty else { return itens }
        return itens.filter {
            "\($0.titulo) \($0.resumo ?? "")".folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil).contains(termo)
        }
    }

    private func porCategoria(_ itens: [VerbeteResumido]) -> [(categoria: String, itens: [VerbeteResumido])] {
        var grupos: [(categoria: String, itens: [VerbeteResumido])] = []
        for v in itens {
            if let i = grupos.firstIndex(where: { $0.categoria == v.categoria }) { grupos[i].itens.append(v) } else { grupos.append((v.categoria, [v])) }
        }
        return grupos
    }
}

private struct CampoDeBusca: View {
    @Binding var texto: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(Cor.tintaSuave).accessibilityHidden(true)
            TextField("", text: $texto, prompt: Text("Procurar: enjoo, febre, comida…").foregroundStyle(Cor.tintaSuave))
                .tipo(.leitura)
                .foregroundStyle(Cor.tinta)
                .autocorrectionDisabled()
                .accessibilityLabel("Procurar na biblioteca")
        }
        .padding(.horizontal, 18)
        .frame(minHeight: Espaco.alvoDoCheckin)
        .superficie(raio: Canto.resposta)
    }
}

/// Um texto da biblioteca, com tipografia de leitura.
struct VerbeteView: View {
    let id: String
    @State private var carga: Carga<Verbete>

    init(id: String) {
        self.id = id
        _carga = State(initialValue: Carga { try await ClienteAPI.compartilhado.obter("/paciente/biblioteca/\(id)") })
    }

    var body: some View {
        ZStack {
            FundoDePapel(composicao: .discreto)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch carga.estado {
                    case .carregando: Esqueleto(linhas: 2)
                    case .erro(let m): ErroDeCarga(mensagem: m) { Task { await carga.carregar() } }
                    case .pronto(let v):
                        RotuloDeSecao(Rotulos.categoria(v.categoria))
                        Text(v.titulo).tipo(.titulo).foregroundStyle(Cor.tinta).accessibilityAddTraits(.isHeader)
                        if let revisado = v.revisadoEm {
                            Text("Revisado em \(revisado.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "pt_BR"))))")
                                .tipo(.rotulo).foregroundStyle(Cor.tintaSuave)
                        }
                        ForEach(Array(v.corpo.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.enumerated()), id: \.offset) { _, paragrafo in
                            Text(paragrafo).tipo(.leitura).foregroundStyle(Cor.tinta).fixedSize(horizontal: false, vertical: true)
                        }
                        if let autoria = v.autoria {
                            Text(autoria).tipo(.ajuda).foregroundStyle(Cor.tintaSuave).padding(.top, 8)
                        }
                    }
                }
                .frame(maxWidth: 620, alignment: .leading)
                .padding(.horizontal, Espaco.margem)
                .padding(.vertical, 12)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await carga.carregar() }
    }
}
