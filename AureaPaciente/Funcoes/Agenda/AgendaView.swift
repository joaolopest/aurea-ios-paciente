import SwiftUI

/// Os compromissos que a equipe marcou. "Próximo" em destaque, depois o resto.
/// Sem cor de destaque: verde ou âmbar aqui seriam lidos como classificação.
struct AgendaView: View {
    @State private var carga = Carga<[ItemDaAgenda]> {
        let pagina: Pagina<ItemDaAgenda> = try await ClienteAPI.compartilhado.obter("/paciente/agenda")
        return pagina.itens.sorted { $0.aconteceEm < $1.aconteceEm }
    }

    var body: some View {
        TelaDeConsulta(titulo: "Agenda", apoio: "Os compromissos que a equipe marcou para você.", carga: carga) { itens in
            if let proximo = itens.first {
                VStack(alignment: .leading, spacing: 10) {
                    RotuloDeSecao("Próximo")
                    CartaoDoCompromisso(item: proximo, destaque: true)
                }
                if itens.count > 1 {
                    VStack(alignment: .leading, spacing: 10) {
                        RotuloDeSecao("Depois")
                        ForEach(itens.dropFirst()) { CartaoDoCompromisso(item: $0, destaque: false) }
                    }
                }
            } else {
                EstadoVazio(titulo: "Nada marcado por enquanto", texto: "Quando a equipe marcar um compromisso, ele aparece aqui.")
            }
        }
    }
}

private struct CartaoDoCompromisso: View {
    let item: ItemDaAgenda
    let destaque: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Rotulos.evento(item.tipo))
                .tipo(destaque ? .titulo : .resposta)
                .foregroundStyle(Cor.tinta)
            Text(Formato.quando(item.aconteceEm) + distancia)
                .tipo(.leitura)
                .foregroundStyle(Cor.tinta)
            ForEach(detalhes, id: \.self) { Text($0).tipo(.ajuda).foregroundStyle(Cor.tintaSuave) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Espaco.cartao)
        .superficie(fundo: destaque ? Cor.folha : Cor.folha)
        .overlay(alignment: .topTrailing) {
            if destaque {
                Image(systemName: "calendar")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Cor.tinta)
                    .frame(width: 40, height: 40)
                    .background(Cor.ceu, in: Circle())
                    .padding(16)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var distancia: String {
        let dias = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: item.aconteceEm)).day ?? 0
        switch dias {
        case 0: return " · hoje"
        case 1: return " · amanhã"
        case 2...: return " · em \(dias) dias"
        default: return ""
        }
    }

    private var detalhes: [String] {
        var linhas: [String] = []
        if let local = item.local { linhas.append(local) }
        if let p = item.profissional {
            linhas.append(p.funcao.map { "\(p.nome) · \(Rotulos.funcao($0))" } ?? p.nome)
        }
        if let obs = item.observacoes { linhas.append(obs) }
        return linhas
    }
}
