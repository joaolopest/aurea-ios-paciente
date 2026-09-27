import SwiftUI

/// O diário dos dias respondidos, por mês. Sem juízo de valor e sem classificação.
///
/// Zero culpa (inviolável 4): dia sem resposta não aparece como buraco nem alerta. O
/// check-in que ficou pela metade é "Check-in não terminado.", em tom neutro.
struct HistoricoView: View {
    @State private var carga = Carga<[DiaDoHistorico]> {
        let pagina: Pagina<DiaDoHistorico> = try await ClienteAPI.compartilhado.obter("/triagem/historico")
        return pagina.itens
    }

    var body: some View {
        TelaDeConsulta(titulo: "Histórico", apoio: "Os dias em que você respondeu, do mais recente para o mais antigo.", carga: carga) { dias in
            if dias.isEmpty {
                EstadoVazio(titulo: "Seu diário começa no primeiro check-in", texto: "Quando você responder, os dias aparecem aqui.")
            } else {
                Text(resumo(dias)).tipo(.ajuda).foregroundStyle(Cor.tintaSuave)
                ForEach(Self.porMes(dias), id: \.mes) { grupo in
                    VStack(alignment: .leading, spacing: 10) {
                        RotuloDeSecao(grupo.mes)
                        VStack(spacing: 0) {
                            ForEach(Array(grupo.dias.enumerated()), id: \.element.id) { i, dia in
                                if i > 0, dia.diaDoCiclo != nil, let anterior = grupo.dias[i - 1].diaDoCiclo,
                                   let atual = dia.diaDoCiclo, atual > anterior {
                                    // Lista do mais novo ao mais antigo: o dia do ciclo cair
                                    // de uma linha para a de cima é virada de ciclo.
                                    MarcaDeCicloNovo()
                                }
                                LinhaDoDia(dia: dia)
                                if i < grupo.dias.count - 1 { Divider().overlay(Cor.linha).padding(.leading, 76) }
                            }
                        }
                        .superficie()
                    }
                }
            }
        }
    }

    private func resumo(_ dias: [DiaDoHistorico]) -> String {
        let respondidos = dias.filter { $0.estado == .concluida }.count
        return respondidos == 1 ? "1 dia respondido" : "\(respondidos) dias respondidos"
    }

    private static func porMes(_ dias: [DiaDoHistorico]) -> [(mes: String, dias: [DiaDoHistorico])] {
        let ordenados = dias.sorted { $0.iniciadaEm > $1.iniciadaEm }
        var grupos: [(mes: String, dias: [DiaDoHistorico])] = []
        for dia in ordenados {
            let mes = dia.iniciadaEm.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "pt_BR"))).capitalizandoPrimeira
            if grupos.last?.mes == mes { grupos[grupos.count - 1].dias.append(dia) } else { grupos.append((mes, [dia])) }
        }
        return grupos
    }
}

private struct LinhaDoDia: View {
    let dia: DiaDoHistorico

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Text(dia.iniciadaEm.formatted(.dateTime.day()))
                    .tipo(.titulo)
                    .monospacedDigit()
                    .foregroundStyle(Cor.tinta)
                Text(Formato.diaRelativo(dia.iniciadaEm))
                    .tipo(.rotulo)
                    .foregroundStyle(Cor.tintaSuave)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(relato).tipo(.leitura).foregroundStyle(dia.estado == .concluida ? Cor.tinta : Cor.tintaSuave)
                Text(detalhe).tipo(.rotulo).foregroundStyle(Cor.tintaSuave)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
    }

    /// "Registro avulso · dia 61 do ciclo" — o check-in do dia não leva rótulo.
    private var detalhe: String {
        var partes: [String] = []
        if dia.estado == .concluida, !HojeStore.ehCheckinCompleto(dia) { partes.append("Registro avulso") }
        if let d = dia.diaDoCiclo { partes.append("Dia \(d) do ciclo") }
        return partes.joined(separator: " · ")
    }

    private var relato: String {
        switch dia.estado {
        case .concluida:
            let sintomas = dia.sintomasRelatados.map(Rotulos.sintoma)
            return sintomas.isEmpty ? "Nada a relatar." : sintomas.joined(separator: ", ")
        case .emAndamento, .abandonada:
            return "Check-in não terminado."
        case .desconhecido:
            return "Registro do dia."
        }
    }
}

private struct MarcaDeCicloNovo: View {
    var body: some View {
        HStack(spacing: 10) {
            Capsule().fill(Cor.lavanda).frame(height: 2)
            Text("Começou um ciclo novo").tipo(.rotulo).foregroundStyle(Cor.ameixa).fixedSize()
            Capsule().fill(Cor.lavanda).frame(height: 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
