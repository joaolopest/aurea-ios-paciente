import SwiftUI
import UIKit

/// Motion do Patamar 1 (docs/BRIEFING-E-DCM.md §8).
///
/// O DC-001 proíbe motion expressivo no questionário: náusea e sensibilidade vestibular.
/// Por isso nenhuma mola quica, exceto a do céu do fechamento — a única assinatura do app.
/// Nada desliza para o lado no check-in, e nada se move em loop em tela nenhuma.
enum Movimento {
    /// Toque em resposta, troca de estado pequena.
    static let toque = Animation.easeOut(duration: 0.15)
    /// Troca de pergunta e de tela: sem quique.
    static let interface = Animation.spring(response: 0.35, dampingFraction: 1)
    /// O céu do fechamento. O único quique do app.
    static let ceu = Animation.spring(response: 0.6, dampingFraction: 0.75)

    /// Próxima pergunta: esmaece e sobe 8pt. Nunca desliza para o lado.
    static var trocaDePergunta: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .offset(y: 8)),
            removal: .opacity
        )
    }
}

/// Vibração com vocabulário: cada evento tem a sua, e só estes eventos vibram.
@MainActor
enum Tato {
    /// Toque numa resposta.
    static func selecao() { UISelectionFeedbackGenerator().selectionChanged() }
    /// Número fora do limite. Uma vez, sem tremer o campo.
    static func aviso() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    /// Fechamento do dia: leve, pausa, conclusão. A única sequência do app.
    static func fechamento() async {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        try? await Task.sleep(for: .milliseconds(300))
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
