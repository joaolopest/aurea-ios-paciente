import SwiftUI

/// A conta: o único lugar com lista padrão (é ajuste, não conteúdo).
struct ContaView: View {
    @Environment(Sessao.self) private var sessao
    @Environment(\.dismiss) private var fechar
    @State private var confirmandoSaida = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sessao.eu?.nome ?? "Sua conta").tipo(.resposta).foregroundStyle(Cor.tinta)
                    Text("Acompanhamento diário").tipo(.ajuda).foregroundStyle(Cor.tintaSuave)
                }
                .padding(.vertical, 6)
            }
            Section {
                NavigationLink {
                    TermoLidoView()
                } label: {
                    Text("Ver o termo que você aceitou").tipo(.leitura)
                }
            }
            Section {
                Button("Sair da conta") { confirmandoSaida = true }
                    .tipo(.leitura)
                    .foregroundStyle(Cor.tinta)
            } footer: {
                Text("Para trocar a senha ou excluir a conta, fale com a equipe do serviço.")
                    .tipo(.ajuda)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Cor.papel)
        .navigationTitle("Conta")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Fechar") { fechar() }
            }
        }
        .confirmationDialog("Sair da conta?", isPresented: $confirmandoSaida, titleVisibility: .visible) {
            Button("Sair") { Task { await sessao.sair() } }
            Button("Ficar", role: .cancel) {}
        } message: {
            Text("Para voltar, você entra de novo com o CPF e a senha.")
        }
    }
}

/// O termo já aceito, para reler. O link do web para "/termos" não existe; aqui o texto
/// é o mesmo da tela de consentimento.
struct TermoLidoView: View {
    var body: some View {
        ZStack {
            FundoDePapel(composicao: .discreto)
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    CabecalhoDeTela(titulo: "Termo de consentimento")
                    ForEach(TermoDeConsentimento.secoes) { secao in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(secao.titulo).tipo(.resposta).foregroundStyle(Cor.tinta).accessibilityAddTraits(.isHeader)
                            Text(secao.texto).tipo(.leitura).foregroundStyle(Cor.tintaSuave)
                        }
                    }
                }
                .padding(Espaco.margem)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
