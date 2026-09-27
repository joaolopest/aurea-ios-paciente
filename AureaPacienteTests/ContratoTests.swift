import XCTest
@testable import AureaPaciente

/// Os modelos contra o curl real (Fixtures/, conta demo sintética, 26/09/2026), e a lógica
/// do check-in contra a árvore real.
final class ContratoTests: XCTestCase {
    func testFixturesReaisDecodificam() throws {
        _ = try decodificar(QuemSou.self, "autenticacao_eu")
        _ = try decodificar(EstadoDoConsentimento.self, "conta_consentimento")
        _ = try decodificar(PerfilDoPaciente.self, "paciente_perfil")
        _ = try decodificar(Pagina<ItemDaAgenda>.self, "paciente_agenda")
        _ = try decodificar(Pagina<VerbeteResumido>.self, "paciente_biblioteca")
        _ = try decodificar(Pagina<PedidoDeContato>.self, "paciente_solicitacoes-de-contato")
        _ = try decodificar(PaginaDeAvisos.self, "paciente_notificacoes")
    }

    func testNomeVemDePerfilDetalhado() throws {
        let eu = try decodificar(QuemSou.self, "autenticacao_eu")
        XCTAssertEqual(eu.nome, "Paciente Um (fictício)")
        XCTAssertEqual(eu.primeiroNome, "Paciente")
    }

    /// `valorNumerico` chega como TEXTO ("38.9"): Decimal do Prisma.
    func testValorNumericoEmTexto() throws {
        let pagina = try decodificar(Pagina<DiaDoHistorico>.self, "triagem_historico")
        let numeros = pagina.itens.flatMap(\.respostas).compactMap(\.valorNumerico?.valor)
        XCTAssertFalse(numeros.isEmpty)
    }

    func testDataCivilDoCicloNaoVoltaUmDia() throws {
        let perfil = try decodificar(PerfilDoPaciente.self, "paciente_perfil")
        let previsao = try XCTUnwrap(perfil.ciclo?.previsaoDaProximaSessao)
        XCTAssertEqual(DataCivil.chave(previsao), "2026-08-17")
        XCTAssertEqual(DataCivil.porExtensoSemAno(previsao), "17 de agosto")
    }

    // MARK: Árvore

    func testPortasAbremEFecham() throws {
        let arvore = try decodificar(ArvoreDeTriagem.self, "triagem_arvore")
        XCTAssertEqual(CheckinStore.passosVisiveis(arvore: arvore, respostas: [:]).count, 5, "Sem respostas, só as 5 portas.")

        let comFebre = CheckinStore.passosVisiveis(arvore: arvore, respostas: ["apresentouFebre": .booleano(true)])
        XCTAssertEqual(comFebre.map(\.pergunta.campo).prefix(3), ["apresentouFebre", "temperaturaMaxima", "usouAntitermico"])

        // Segundo nível: "quantas vezes vomitou" só depois de "vomitou = sim".
        let enjoo = CheckinStore.passosVisiveis(arvore: arvore, respostas: ["sentiuNausea": .booleano(true)]).map(\.pergunta.campo)
        XCTAssertTrue(enjoo.contains("vomitou"))
        XCTAssertFalse(enjoo.contains("episodiosDeVomito"))
    }

    func testTrocarSimPorNaoPodaDetalhes() throws {
        let arvore = try decodificar(ArvoreDeTriagem.self, "triagem_arvore")
        let respostas: [String: Valor] = [
            "sentiuNausea": .booleano(false),
            "vomitou": .booleano(true),
            "episodiosDeVomito": .numero(3),
        ]
        XCTAssertEqual(CheckinStore.podar(respostas: respostas, arvore: arvore), ["sentiuNausea": .booleano(false)])
    }

    func testCorpoDoEnvioAgrupaPorSintomaNaOrdemDaArvore() throws {
        let arvore = try decodificar(ArvoreDeTriagem.self, "triagem_arvore")
        let corpo = CheckinStore.corpoDoEnvio(sessaoId: "s", arvore: arvore, respostas: [
            "apresentouDor": .booleano(true), "localizacao": .texto("CABECA"), "intensidade": .numero(4),
            "apresentouFebre": .booleano(false),
        ])
        XCTAssertEqual(corpo.sintomas.map(\.sintoma), ["FEBRE", "DOR"])

        let json = String(decoding: try JSONEncoder().encode(corpo), as: UTF8.self)
        XCTAssertTrue(json.contains("\"valorTexto\":\"CABECA\""))
        XCTAssertTrue(json.contains("\"valorNumerico\":4"))
        XCTAssertFalse(json.contains("valorBooleano\":null"), "Exatamente um tipo de valor por resposta.")
    }

    func testTodaOpcaoDaArvoreTemRotulo() throws {
        let arvore = try decodificar(ArvoreDeTriagem.self, "triagem_arvore")
        for opcao in arvore.sintomas.flatMap(\.detalhes).flatMap({ $0.opcoes ?? [] }) {
            XCTAssertFalse(Rotulos.opcao(opcao).hasPrefix("Opção sem nome"), "\(opcao) sem rótulo em português.")
        }
    }

    // MARK: Registro avulso

    @MainActor
    func testRegistroPerguntaSoOsDetalhesDoSintomaEscolhido() throws {
        let arvore = try decodificar(ArvoreDeTriagem.self, "triagem_arvore")
        var respostas: [String: Valor] = ["apresentouFebre": .booleano(true)]
        let fila = CheckinStore.passosVisiveis(arvore: arvore, respostas: respostas)
            .filter { $0.sintoma == "FEBRE" && $0.pergunta.campo != "apresentouFebre" }
        XCTAssertEqual(fila.map(\.pergunta.campo), ["temperaturaMaxima", "usouAntitermico"])

        // O envio leva só a febre: os outros quatro sintomas não foram perguntados.
        respostas["temperaturaMaxima"] = .numero(38.2)
        respostas["usouAntitermico"] = .booleano(false)
        let corpo = CheckinStore.corpoDoEnvio(sessaoId: "s", arvore: arvore, respostas: respostas)
        XCTAssertEqual(corpo.sintomas.map(\.sintoma), ["FEBRE"])
        XCTAssertEqual(corpo.sintomas.first?.respostas.count, 3)
    }

    func testSoOCheckinDosCincoSintomasContaComoDoDia() throws {
        let pagina = try decodificar(Pagina<DiaDoHistorico>.self, "triagem_historico")
        let completos = pagina.itens.filter(HojeStore.ehCheckinCompleto)
        XCTAssertFalse(completos.isEmpty, "O check-in real de 25/09 respondeu as cinco portas.")
        for dia in completos {
            XCTAssertTrue(Rotulos.portas.isSubset(of: Set(dia.respostas.map(\.campo))))
        }
    }
}
