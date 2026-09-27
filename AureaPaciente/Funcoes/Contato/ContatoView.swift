import SwiftUI

/// Falar com a enfermagem. Sem campo de motivo: a coluna não existe e o texto seria
/// jogado fora (docs/CONTORNOS.md, C-03).
///
/// A confirmação é RELIDA do servidor, nunca otimista: o web já disse "Recebemos seu
/// pedido às 17:15" sem ter chamado o servidor (commit 7613137).
struct ContatoView: View {
    @State private var carga = Carga<[PedidoDeContato]> {
        let pagina: Pagina<PedidoDeContato> = try await ClienteAPI.compartilhado.obter("/paciente/solicitacoes-de-contato")
        return pagina.itens
    }
    @State private var enviando = false
    @State private var erro: String?

    var body: some View {
        TelaDeConsulta(titulo: "Falar com a enfermagem", carga: carga) { pedidos in
            Aviso(tom: .informacao, titulo: "Este não é um canal de emergência", texto: "Se a situação for grave, procure o serviço ou ligue para a emergência.")
            if let aberto = pedidos.first(where: { !$0.atendida }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Seu pedido já está com a equipe").tipo(.titulo).foregroundStyle(Cor.tinta)
                    Text("A equipe recebeu às \(aberto.solicitadaEm.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))) e vai entrar em contato com você.")
                        .tipo(.leitura).foregroundStyle(Cor.tintaSuave)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Espaco.cartao)
                .superficie(fundo: Cor.lavanda)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    Text("A equipe vê o seu pedido e liga para você.")
                        .tipo(.leitura).foregroundStyle(Cor.tinta)
                    if let erro { Aviso(tom: .informacao, titulo: "Seu pedido não foi enviado", texto: erro) }
                    BotaoPrincipal(titulo: "Pedir para a equipe me ligar", carregando: enviando) { Task { await pedir() } }
                }
            }
        }
    }

    private func pedir() async {
        struct Nada: Encodable, Sendable {}
        enviando = true
        erro = nil
        defer { enviando = false }
        do {
            let _: RespostaDePedidoDeContato = try await ClienteAPI.compartilhado.enviar("/paciente/solicitacoes-de-contato", corpo: Nada())
            await carga.carregar()
        } catch let e as ErroDaAPI {
            erro = e.mensagem
        } catch {
            erro = "Tente de novo em instantes."
        }
    }
}
