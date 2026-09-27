import Foundation

/// Todo identificador que vira texto passa por aqui.
///
/// O web já mostrou `BOCA_OU_GARGANTA` como opção de toque para o paciente (corrigido).
/// Os mapas são cópia literal de `@aurea/contratos` e `apps/web/src/sistema/formato.ts`.
/// Faltou rótulo? O fallback é VISÍVEL e feio de propósito ("Opção sem nome (…)"), para
/// ser pego no primeiro teste — nunca o identificador cru em caixa alta.
enum Rotulos {
    /// As perguntas-porta: "sim" nelas é o sintoma relatado.
    static let portas: Set<String> = [
        "apresentouFebre", "apresentouDiarreia", "sentiuNausea", "apresentouDor", "apresentouFaltaDeAr",
    ]

    /// Sintoma, em palavra comum. A árvore traz o rótulo do ramo; o histórico, não.
    static func sintoma(_ id: String) -> String {
        switch id {
        case "FEBRE": "Febre"
        case "DIARREIA": "Diarreia"
        case "NAUSEA_VOMITO": "Enjoo e vômito"
        case "DOR": "Dor"
        case "FALTA_DE_AR": "Falta de ar"
        default: semNome(id)
        }
    }

    /// Opções de resposta (`ROTULO_DO_LOCAL_DE_DOR`, `ROTULO_DO_ESFORCO`).
    static func opcao(_ id: String) -> String {
        switch id {
        case "ABDOMINAL": "Barriga"
        case "TORACICA": "Peito"
        case "CABECA": "Cabeça"
        case "BOCA_OU_GARGANTA": "Boca ou garganta"
        case "OSSOS_OU_ARTICULACOES": "Ossos ou juntas"
        case "LOCAL_DO_CATETER": "No lugar do cateter"
        case "OUTRO": "Outro lugar"
        case "AO_CAMINHAR": "Quando eu caminho"
        case "AO_FALAR": "Quando eu falo"
        case "EM_REPOUSO": "Mesmo parado, sem fazer esforço"
        default: semNome(id)
        }
    }

    /// Tipo de compromisso (`ROTULO_DO_EVENTO`).
    static func evento(_ id: String) -> String {
        switch id {
        case "QUIMIOTERAPIA": "Sessão de quimioterapia"
        case "CONSULTA_MEDICA": "Consulta médica"
        case "CONSULTA_NUTRICAO": "Consulta com a nutrição"
        case "CONSULTA_PSICOLOGIA": "Consulta com a psicologia"
        default: semNome(id)
        }
    }

    /// Categoria da biblioteca (`ROTULO_DA_CATEGORIA`).
    static func categoria(_ id: String) -> String {
        switch id {
        case "MEDICAMENTOS": "Medicamentos"
        case "ALIMENTACAO": "Alimentação"
        case "MUCOSITE": "Boca e garganta"
        case "CATETER": "Cateter"
        case "QUEDA_DE_CABELO": "Queda de cabelo"
        case "DIARREIA": "Diarreia"
        case "CONSTIPACAO": "Intestino preso"
        case "EXERCICIOS": "Movimento e descanso"
        case "VACINAS": "Vacinas"
        case "DIREITOS_DO_PACIENTE": "Seus direitos"
        default: semNome(id)
        }
    }

    /// Função do profissional (`ROTULO_DA_FUNCAO`).
    static func funcao(_ id: String) -> String {
        switch id {
        case "MEDICO": "Médico"
        case "ENFERMEIRO": "Enfermeiro"
        case "TECNICO_DE_ENFERMAGEM": "Técnico de enfermagem"
        case "NUTRICIONISTA": "Nutricionista"
        case "PSICOLOGO": "Psicólogo"
        case "FARMACEUTICO": "Farmacêutico"
        default: semNome(id)
        }
    }

    /// Fallback visível. Minúsculas e sem sublinhado: nunca parece rótulo de verdade, e
    /// nunca é o identificador cru em caixa alta.
    private static func semNome(_ id: String) -> String {
        #if DEBUG
        print("🟠 [Rotulos] sem rótulo para \(id)")
        #endif
        return "Opção sem nome (\(id.lowercased().replacingOccurrences(of: "_", with: " ")))"
    }
}
