import Foundation

/// O check-in em andamento, guardado no aparelho a cada toque (inviolável 5).
///
/// Existe para a resposta nunca se perder: o app pode ser fechado no meio, o telefone
/// pode ficar sem sinal no envio. O rascunho sobrevive e é reenviado com a MESMA
/// `chaveDeIdempotencia`, então o servidor nunca cria dois check-ins do mesmo toque.
///
/// É a única exceção à regra "dado de saúde só na memória": arquivo com
/// `FileProtectionType.complete` (cifrado com o aparelho travado), fora do backup, e
/// apagado ao concluir, ao virar o dia e ao sair da conta.
struct RascunhoDoCheckin: Codable, Sendable, Equatable {
    /// O check-in do dia (os 5 sintomas) ou um registro avulso (só os escolhidos). Cada
    /// um tem o seu arquivo: registrar febre à tarde não apaga o check-in pela metade.
    enum Modo: String, Codable, Sendable { case diario, registro }

    /// Dia civil local em que o check-in começou (`aaaa-mm-dd`). Rascunho de ontem não vale hoje.
    var dia: String
    var chaveDeIdempotencia: String
    var sessaoId: String?
    var respostas: [String: Valor]
    /// Só no registro avulso: os sintomas que a pessoa escolheu relatar.
    var sintomasEscolhidos: [String]?

    static func novo() -> RascunhoDoCheckin {
        RascunhoDoCheckin(dia: DataCivil.hoje, chaveDeIdempotencia: UUID().uuidString.lowercased(), sessaoId: nil, respostas: [:])
    }

    // MARK: Disco

    private static func arquivo(_ modo: Modo) -> URL {
        let pasta = URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: pasta, withIntermediateDirectories: true)
        return pasta.appending(path: modo == .diario ? "rascunho-do-checkin.json" : "rascunho-do-registro.json")
    }

    /// O rascunho de HOJE, se houver. O de outro dia é apagado ao ler.
    static func carregar(_ modo: Modo = .diario) -> RascunhoDoCheckin? {
        guard let dados = try? Data(contentsOf: arquivo(modo)),
              let rascunho = try? JSONDecoder().decode(RascunhoDoCheckin.self, from: dados) else { return nil }
        guard rascunho.dia == DataCivil.hoje else { apagar(modo); return nil }
        return rascunho
    }

    func guardar(_ modo: Modo = .diario) {
        guard let dados = try? JSONEncoder().encode(self) else { return }
        var destino = Self.arquivo(modo)
        try? dados.write(to: destino, options: [.atomic, .completeFileProtection])
        var valores = URLResourceValues()
        valores.isExcludedFromBackup = true
        try? destino.setResourceValues(valores)
    }

    static func apagar(_ modo: Modo = .diario) {
        try? FileManager.default.removeItem(at: arquivo(modo))
    }

    /// Ao sair da conta: nenhum rascunho fica no aparelho.
    static func apagarTodos() {
        apagar(.diario)
        apagar(.registro)
    }
}
