import SwiftUI

/// A casca do app autenticado: cinco abas nativas (DCM §6).
///
/// Nativa de propósito: acessibilidade e o vidro do iOS 26 vêm de graça; a assinatura
/// visual do app mora no check-in e no céu, não na barra. Conta abre pelo avatar de Hoje,
/// Avisos pelo sino — seis alvos em 390pt dão erro de dedo.
struct AbasView: View {
    enum Aba: Hashable { case hoje, historico, agenda, tratamento, biblioteca }

    @Environment(Sessao.self) private var sessao
    @Environment(\.scenePhase) private var fase
    @State private var aba: Aba = .hoje
    @State private var hoje = HojeStore()
    @State private var checkin: CheckinStore?

    var body: some View {
        TabView(selection: $aba) {
            NavigationStack { HojeView(store: hoje, abrirCheckin: { abrir(.diario) }, registrarSintoma: { abrir(.registro) }) }
                .tabItem { Label("Hoje", systemImage: aba == .hoje ? "sun.max.fill" : "sun.max") }
                .tag(Aba.hoje)
            NavigationStack { HistoricoView() }
                .tabItem { Label("Histórico", systemImage: aba == .historico ? "book.closed.fill" : "book.closed") }
                .tag(Aba.historico)
            NavigationStack { AgendaView() }
                .tabItem { Label("Agenda", systemImage: aba == .agenda ? "calendar.circle.fill" : "calendar") }
                .tag(Aba.agenda)
            NavigationStack { TratamentoView() }
                .tabItem { Label("Tratamento", systemImage: aba == .tratamento ? "heart.text.square.fill" : "heart.text.square") }
                .tag(Aba.tratamento)
            NavigationStack { BibliotecaView() }
                .tabItem { Label("Biblioteca", systemImage: aba == .biblioteca ? "books.vertical.fill" : "books.vertical") }
                .tag(Aba.biblioteca)
        }
        .tint(Cor.ameixa)
        .task(id: fase) {
            guard fase == .active else { return }
            await hoje.carregar()
            if case .erro(let m) = hoje.carga, m == ErroDaAPI.sessaoEncerrada.mensagem {
                sessao.sessaoExpirou()
            }
        }
        .fullScreenCover(item: $checkin) { store in
            CheckinView(store: store)
        }
        .onOpenURL { url in
            // aurea://checkin — lembrete e widget abrem direto na primeira pergunta.
            switch url.host() {
            case "checkin": aba = .hoje; abrir(.diario)
            // aurea://registrar — atalho para relatar um sintoma fora do check-in.
            case "registrar": aba = .hoje; abrir(.registro)
            default: break
            }
        }
    }

    private func abrir(_ modo: CheckinStore.Modo) {
        guard checkin == nil else { return }
        let store = CheckinStore(modo: modo)
        // Hoje relê do servidor: o estado do dia nunca é suposto pelo cliente.
        store.aoConcluir = { [hoje] _ in Task { await hoje.carregar() } }
        checkin = store
    }
}

extension CheckinStore: Identifiable {
    nonisolated var id: ObjectIdentifier { ObjectIdentifier(self) }
}
