import SwiftUI

/// Campo de texto grande: rótulo em cima, sempre visível (placeholder some ao digitar e
/// quem está no pior dia esquece o que o campo pedia).
struct CampoDeTexto: View {
    let rotulo: String
    @Binding var texto: String
    var teclado: UIKeyboardType = .default
    var conteudo: UITextContentType?
    var ajuda: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(rotulo).tipo(.rotulo).foregroundStyle(Cor.tintaSuave)
                .accessibilityHidden(true) // o campo já se chama assim; ler duas vezes cansa
            TextField("", text: $texto)
                .tipo(.resposta)
                .foregroundStyle(Cor.tinta)
                .keyboardType(teclado)
                .textContentType(conteudo)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(.horizontal, 18)
                .frame(minHeight: Espaco.alvoDoCheckin)
                .superficie(raio: Canto.resposta)
                .accessibilityLabel(rotulo)
                .accessibilityIdentifier("campo-\(rotulo)")
            if let ajuda { Text(ajuda).tipo(.ajuda).foregroundStyle(Cor.tintaSuave) }
        }
    }
}

/// Senha com "Mostrar": digitar senha longa com náusea e sem ver o que digita é crueldade.
struct CampoDeSenha: View {
    let rotulo: String
    @Binding var texto: String
    @Binding var mostrando: Bool
    var conteudo: UITextContentType = .password
    var ajuda: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(rotulo).tipo(.rotulo).foregroundStyle(Cor.tintaSuave)
                .accessibilityHidden(true)
            HStack(spacing: 8) {
                Group {
                    if mostrando {
                        TextField("", text: $texto)
                    } else {
                        SecureField("", text: $texto)
                    }
                }
                .tipo(.resposta)
                .foregroundStyle(Cor.tinta)
                .textContentType(conteudo)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .accessibilityLabel(rotulo)
                .accessibilityIdentifier("campo-\(rotulo)")

                Button(mostrando ? "Esconder" : "Mostrar") { mostrando.toggle() }
                    .tipo(.rotulo)
                    .foregroundStyle(Cor.ameixa)
                    .frame(minWidth: Espaco.alvo, minHeight: Espaco.alvo)
            }
            .padding(.leading, 18)
            .padding(.trailing, 8)
            .frame(minHeight: Espaco.alvoDoCheckin)
            .superficie(raio: Canto.resposta)
            if let ajuda { Text(ajuda).tipo(.ajuda).foregroundStyle(Cor.tintaSuave) }
        }
    }
}
