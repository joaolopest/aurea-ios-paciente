import Foundation

/// O mural "O que pode aparecer no seu tratamento": cópia literal de
/// `packages/contratos/src/mural.ts` (versão `rascunho-0`), gerada por script.
///
/// ⚠️ CONTORNO C-06 (docs/CONTORNOS.md): conteúdo fixo no front, não servido pela API.
/// `textoRevisadoPelaClinica == false` OBRIGA a tela a mostrar o selo de não validado.
struct VerbeteDoMural: Identifiable, Sendable {
    let sintoma: String
    let titulo: String
    let resumo: String
    let porQueAcontece: String
    let oQueEsperar: [String]
    let emCasa: [String]
    let quandoProcurar: [String]
    var id: String { sintoma }

    static let versao = "rascunho-0"
    static let textoRevisadoPelaClinica = false

    static let todos: [VerbeteDoMural] = [
        VerbeteDoMural(
            sintoma: "FEBRE",
            titulo: "Febre",
            resumo: "Durante a quimioterapia a febre tem peso diferente do que tinha antes, e é o sinal que a equipe mais quer saber cedo.",
            porQueAcontece: "A quimioterapia reduz por alguns dias as células de defesa do corpo. Nesse período uma infecção pequena avança mais rápido do que avançaria antes, e a febre costuma ser o primeiro aviso, às vezes o único.",
            oQueEsperar: [
                "A queda de defesa costuma acontecer nos dias seguintes à sessão, e o serviço informa em quais dias ela é mais provável no seu protocolo.",
                "Você pode se sentir bem e ter febre assim mesmo. Sentir-se bem não descarta.",
            ],
            emCasa: [
                "Meça a temperatura sempre que sentir calor, calafrio ou moleza, e não só quando parecer óbvio.",
                "Anote o valor e a hora. É isso que a equipe usa para decidir, e é a pergunta que o check-in faz.",
            ],
            quandoProcurar: [
                "Entre em contato no mesmo dia se a temperatura passar de 37,8 °C.",
                "Não tome remédio para baixar a febre antes de falar com a equipe: o remédio esconde o sinal e atrasa a avaliação.",
                "Calafrio forte, tremor ou moleza fora do comum pedem contato mesmo com a temperatura ainda normal.",
            ]
        ),
        VerbeteDoMural(
            sintoma: "DIARREIA",
            titulo: "Diarreia",
            resumo: "Comum em vários protocolos. O que muda a conduta não é o incômodo, é quanto líquido você está perdendo.",
            porQueAcontece: "Alguns medicamentos irritam o revestimento do intestino, que se renova rápido e por isso sente antes. O intestino passa a absorver menos água.",
            oQueEsperar: [
                "Pode aparecer nos primeiros dias depois da sessão e ceder sozinha.",
                "A frequência varia de um ciclo para outro, mesmo com a mesma medicação.",
            ],
            emCasa: [
                "Beba líquido em goles ao longo do dia, sem esperar sede. Perder água é o que mais rápido complica.",
                "Refeições menores e mais frequentes pesam menos que três grandes.",
                "Se você tem remédio receitado para isso, use conforme a receita. Nada novo deve ser começado por conta própria.",
            ],
            quandoProcurar: [
                "Procure a equipe se as evacuações aumentarem muito em relação ao seu normal, ou se durarem mais de um dia sem melhora.",
                "Sangue nas fezes pede contato imediato.",
                "Se você não estiver conseguindo beber água, ou notar boca muito seca, tontura ao levantar e urina muito escura, não espere o próximo dia.",
            ]
        ),
        VerbeteDoMural(
            sintoma: "NAUSEA_VOMITO",
            titulo: "Enjoo e vômito",
            resumo: "Dos efeitos mais frequentes, e um dos que mais têm remédio eficaz, desde que a equipe saiba que está acontecendo.",
            porQueAcontece: "A medicação estimula a área do cérebro que controla o vômito, e também irrita o estômago. Por isso o enjoo pode vir mesmo sem nada no estômago.",
            oQueEsperar: [
                "Costuma ser mais forte nas primeiras 24 a 48 horas depois da sessão.",
                "Cheiros fortes, comida gordurosa e jejum longo costumam piorar.",
            ],
            emCasa: [
                "Coma em porções pequenas ao longo do dia; estômago vazio costuma enjoar mais.",
                "Beba líquidos gelados em goles, mesmo sem vontade.",
                "Use o remédio para enjoo que está na sua receita, no horário orientado, inclusive nos dias em que você acha que não vai precisar, se foi assim que a equipe orientou.",
            ],
            quandoProcurar: [
                "Procure a equipe se você vomitar repetidamente e não conseguir segurar líquido.",
                "Se não conseguir tomar os remédios de uso contínuo por causa do vômito, avise no mesmo dia.",
                "Vômito com sangue ou com aspecto de borra de café pede contato imediato.",
            ]
        ),
        VerbeteDoMural(
            sintoma: "DOR",
            titulo: "Dor",
            resumo: "Dor tratada cedo é mais fácil de controlar. Aguentar calado não ajuda o tratamento e não é sinal de força.",
            porQueAcontece: "Pode vir da própria doença, do efeito da medicação sobre nervos e mucosas, ou do local do cateter. Onde dói diz mais à equipe do que o quanto dói.",
            oQueEsperar: [
                "Dor no corpo e nas articulações nos dias seguintes à sessão é relatada com frequência.",
                "A intensidade tende a variar ao longo do dia.",
            ],
            emCasa: [
                "Se você tem analgésico receitado, use conforme a receita, no horário, sem esperar a dor ficar forte.",
                "Anote onde dói e em que horas piora. É isso que permite mudar a conduta com segurança.",
            ],
            quandoProcurar: [
                "Procure a equipe se a dor aumentar, mudar de lugar ou não ceder com o que está na sua receita.",
                "Dor no peito e falta de ar juntas pedem atendimento imediato, não contato pelo aplicativo.",
                "Dor, vermelhidão ou inchaço no local do cateter pedem avaliação no mesmo dia.",
            ]
        ),
        VerbeteDoMural(
            sintoma: "FALTA_DE_AR",
            titulo: "Falta de ar",
            resumo: "É o sintoma desta lista com menor margem para esperar. Na dúvida, o caminho é o serviço, não o aplicativo.",
            porQueAcontece: "Pode vir de anemia, que é comum durante o tratamento, mas também de causas que precisam de avaliação rápida. Só o exame distingue, e não dá para distinguir de casa.",
            oQueEsperar: [
                "Cansaço ao subir escada ou ao caminhar mais que o habitual aparece com frequência quando a anemia se instala.",
                "Esse cansaço costuma vir junto com palidez e sono fora do comum.",
            ],
            emCasa: [
                "Distribua esforço ao longo do dia e aceite ajuda nas tarefas pesadas.",
                "Repare em quando a falta de ar aparece: subindo escada, andando no plano, ou parado. A diferença entre esses três muda a conduta.",
            ],
            quandoProcurar: [
                "Falta de ar em repouso, ou que apareceu de repente, é procura imediata pelo serviço.",
                "Se vier com dor no peito, lábios ou pontas dos dedos arroxeados, procure atendimento agora.",
                "Falta de ar que piorou de um dia para o outro merece contato no mesmo dia, mesmo que seja leve.",
            ]
        ),
    ]
}
