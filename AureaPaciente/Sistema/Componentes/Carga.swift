import SwiftUI

/// Carga de uma tela de consulta: carregando → pronto | erro. Relê ao puxar.
@MainActor
@Observable
final class Carga<Dado: Sendable> {
    enum Estado { case carregando, pronto(Dado), erro(String) }

    private(set) var estado: Estado = .carregando
    private let buscar: @Sendable () async throws -> Dado

    init(_ buscar: @escaping @Sendable () async throws -> Dado) {
        self.buscar = buscar
    }

    var dado: Dado? {
        if case .pronto(let d) = estado { return d }
        return nil
    }

    func carregar() async {
        do {
            estado = .pronto(try await buscar())
        } catch let e as ErroDaAPI {
            if dado == nil { estado = .erro(e.mensagem) }
        } catch {
            if dado == nil { estado = .erro("Não foi possível carregar agora.") }
        }
    }
}

/// Moldura comum das telas de consulta: papel, cabeçalho próprio, rolagem, puxar para
/// atualizar e os três estados.
struct TelaDeConsulta<Dado: Sendable, Conteudo: View>: View {
    let titulo: String
    var apoio: String?
    let carga: Carga<Dado>
    @ViewBuilder let conteudo: (Dado) -> Conteudo

    var body: some View {
        ZStack {
            FundoDePapel(composicao: .discreto)
            ScrollView {
                VStack(alignment: .leading, spacing: Espaco.entreSecoes) {
                    CabecalhoDeTela(titulo: titulo, apoio: apoio)
                        .padding(.top, 12)
                    switch carga.estado {
                    case .carregando:
                        Esqueleto(linhas: 3)
                    case .erro(let mensagem):
                        ErroDeCarga(mensagem: mensagem) { Task { await carga.carregar() } }
                    case .pronto(let dado):
                        conteudo(dado)
                    }
                }
                .padding(.horizontal, Espaco.margem)
                .padding(.bottom, 32)
            }
            .refreshable { await carga.carregar() }
            .veuDoTopo()
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .task { if carga.dado == nil { await carga.carregar() } }
    }
}

/// Rótulo de seção dentro de uma tela.
struct RotuloDeSecao: View {
    let texto: String
    init(_ texto: String) { self.texto = texto }

    var body: some View {
        Text(texto)
            .tipo(.rotulo)
            .foregroundStyle(Cor.ameixa)
            .accessibilityAddTraits(.isHeader)
    }
}
