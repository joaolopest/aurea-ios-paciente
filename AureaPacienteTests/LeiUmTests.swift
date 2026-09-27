import XCTest
@testable import AureaPaciente

/// A lei 1, provada: o paciente nunca vê cor de risco, nome de regra nem nome de campo.
///
/// A segunda trava depois do servidor (`servicos/resposta-ao-paciente.ts`). Se alguém
/// "completar" um modelo com o que a API manda, estes testes falham — e o comentário de
/// `Triagem.swift` explica por quê.
final class LeiUmTests: XCTestCase {
    /// Nomes que não podem existir em NENHUMA propriedade dos modelos que chegam à tela.
    private let proibidos = [
        "resultado", "classificacao", "classificacoes", "explicacao", "regrasDisparadas",
        "conjuntoDeLimiaresId", "situacao", "enfermagemAvisada", "validadoClinicamente",
        "versaoDoConjunto", "justificativa", "valorObservado",
    ]

    func testRetornoComVazamentoNaoCarregaClassificacao() throws {
        // A resposta da API ANTES da correção de 26/09, com tudo o que vazava.
        let retorno = try decodificar(RetornoDoCheckin.self, "checkin_com_vazamento")

        XCTAssertEqual(retorno.orientacoes.first?.titulo, "Procure atendimento")
        XCTAssertTrue(retorno.pedeContatoComServico)
        assertSemCampoProibido(retorno)
        retorno.orientacoes.forEach { assertSemCampoProibido($0) }

        // E o texto do objeto inteiro, como uma tela o imprimiria, não contém a cor.
        let impresso = String(describing: retorno)
        for cor in ["VERMELHO", "AMARELO", "VERDE", "temperaturaMaxima", "38,5"] {
            XCTAssertFalse(impresso.contains(cor), "O modelo guardou “\(cor)” vindo da API.")
        }
    }

    func testSessaoRealDecodificaSoOQueOPacienteVe() throws {
        let sessao = try decodificar(RetornoDoCheckin.self, "triagem_sessao")
        XCTAssertEqual(sessao.estado, .concluida)
        XCTAssertFalse(sessao.orientacoes.isEmpty)
        assertSemCampoProibido(sessao)
    }

    func testHistoricoRealNaoTemClassificacao() throws {
        let pagina = try decodificar(Pagina<DiaDoHistorico>.self, "triagem_historico")
        XCTAssertFalse(pagina.itens.isEmpty)
        pagina.itens.forEach { assertSemCampoProibido($0) }
    }

    // MARK: Apoio

    private func assertSemCampoProibido(_ valor: Any, arquivo: StaticString = #filePath, linha: UInt = #line) {
        for filho in Mirror(reflecting: valor).children {
            guard let nome = filho.label else { continue }
            XCTAssertFalse(proibidos.contains(nome), "\(type(of: valor)) expõe “\(nome)”. Lei 1: ver docs/CONTORNOS.md, C-01.", file: arquivo, line: linha)
        }
    }
}

func decodificar<T: Decodable>(_ tipo: T.Type, _ nome: String) throws -> T {
    let url = try XCTUnwrap(Bundle(for: LeiUmTests.self).url(forResource: nome, withExtension: "json"), "Fixture \(nome).json não está no bundle de teste")
    return try ClienteAPI.decodificador.decode(T.self, from: Data(contentsOf: url))
}
