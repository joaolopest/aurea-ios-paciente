import Foundation
import Security

/// O token da sessão, no Keychain.
///
/// `AfterFirstUnlockThisDeviceOnly`: não sai do aparelho em backup, não migra para outro
/// iPhone, e fica legível depois do primeiro desbloqueio: o lembrete pode abrir o app
/// com a tela travada. O token é opaco — o servidor guarda o hash e valida a cada
/// chamada —, então não há nada para decodificar aqui.
final class GuardaDeToken: Sendable {
    static let compartilhado = GuardaDeToken()

    private let servico = "com.zenixcode.aurea.paciente.sessao"
    private let conta = "token"

    func ler() -> String? {
        var consulta = base
        consulta[kSecReturnData as String] = true
        consulta[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(consulta as CFDictionary, &item) == errSecSuccess,
              let dados = item as? Data else { return nil }
        return String(data: dados, encoding: .utf8)
    }

    func guardar(_ token: String) {
        apagar()
        var novo = base
        novo[kSecValueData as String] = Data(token.utf8)
        novo[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(novo as CFDictionary, nil)
    }

    func apagar() {
        SecItemDelete(base as CFDictionary)
    }

    private var base: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: servico,
            kSecAttrAccount as String: conta,
        ]
    }
}
