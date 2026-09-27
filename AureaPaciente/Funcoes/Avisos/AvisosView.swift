import SwiftUI

/// Mensagens da equipe. Não lida se distingue por peso de fonte, nunca por cor. Abrir a
/// tela marca como lida (o web tem a função e nenhuma tela a chama).
struct AvisosView: View {
    @State private var carga = Carga<[AvisoDaEquipe]> {
        let pagina: PaginaDeAvisos = try await ClienteAPI.compartilhado.obter("/paciente/notificacoes")
        return pagina.itens
    }

    var body: some View {
        TelaDeConsulta(titulo: "Avisos", apoio: "Mensagens da equipe do seu tratamento.", carga: carga) { avisos in
            if avisos.isEmpty {
                EstadoVazio(titulo: "Nenhum aviso por enquanto", texto: "Quando a equipe mandar uma mensagem, ela aparece aqui.")
            }
            ForEach(avisos) { aviso in
                VStack(alignment: .leading, spacing: 6) {
                    Text(Formato.diaRelativo(aviso.criadaEm).capitalizandoPrimeira + ", " + aviso.criadaEm.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)))
                        .tipo(.rotulo).foregroundStyle(Cor.tintaSuave)
                    Text(aviso.assunto)
                        .tipo(.resposta)
                        .fontWeight(aviso.lidaEm == nil ? .heavy : .semibold)
                        .foregroundStyle(Cor.tinta)
                    if let corpo = aviso.corpo { Text(corpo).tipo(.leitura).foregroundStyle(Cor.tintaSuave) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Espaco.cartao)
                .superficie()
                .accessibilityElement(children: .combine)
                .accessibilityHint(aviso.lidaEm == nil ? "Não lido" : "")
                .task { await marcarComoLido(aviso) }
            }
        }
    }

    private func marcarComoLido(_ aviso: AvisoDaEquipe) async {
        guard aviso.lidaEm == nil else { return }
        struct Nada: Encodable, Sendable {}
        try? await ClienteAPI.compartilhado.enviarSemResposta("/paciente/notificacoes/\(aviso.id)/leitura", corpo: Nada())
    }
}
