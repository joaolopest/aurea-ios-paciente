import Foundation

/// O texto do termo de consentimento, cópia literal de `apps/web/src/app/consentimento/page.tsx`.
///
/// ⚠️ CONTORNO C-05 (docs/CONTORNOS.md): o texto mora no front do web, não na API. Duas
/// cópias divergem; o certo é a API servir o texto junto com `versaoVigente`. Enquanto
/// isso, quem mudar o termo no web muda aqui também — e a API recusa o aceite (409) se a
/// versão mudou, então o risco é mostrar texto velho, não registrar aceite errado.
enum TermoDeConsentimento {
    struct Secao: Identifiable {
        let titulo: String
        let texto: String
        var id: String { titulo }
    }

    static let rotulo = "Monitoramento remoto de toxicidade"

    static let secoes: [Secao] = [
        Secao(
            titulo: "Para que serve este monitoramento",
            texto: "O AUREA pergunta, todo dia, como você está passando durante a quimioterapia. Suas respostas ajudam a equipe a perceber cedo um efeito colateral que precise de atenção; o objetivo é encurtar a distância entre o sintoma aparecer em casa e a equipe saber disso."
        ),
        Secao(
            titulo: "Como seus dados são usados",
            texto: "Os dados que você registra ficam associados ao seu tratamento e são vistos pela equipe clínica responsável por você. Este uso segue a Lei Geral de Proteção de Dados (Lei 13.709/2018): a finalidade é o cuidado em saúde e a pesquisa clínica associada a este serviço, os dados não são vendidos nem usados para outro fim, e você pode pedir acesso, correção ou exclusão do que foi registrado a qualquer momento, falando com a equipe."
        ),
        Secao(
            titulo: "Nesta fase, os dados são sintéticos",
            texto: "Enquanto o sistema está em validação, tudo que aparece nas telas, nomes, respostas, históricos, é fictício, criado só para testar a interface. Nenhuma informação real de paciente trafega por aqui ainda. Você será avisado quando essa fase terminar e dados reais passarem a ser usados."
        ),
        Secao(
            titulo: "Isto não substitui atendimento",
            texto: "Responder ao check-in diário não troca uma consulta, um pronto atendimento ou uma ligação para a equipe. Se você sentir algo grave ou tiver dúvida sobre um sintoma, procure o serviço diretamente; não espere a próxima pergunta do sistema aparecer."
        ),
        Secao(
            titulo: "Sua participação é voluntária",
            texto: "Você pode deixar de participar a qualquer momento, sem que isso mude o seu tratamento ou o cuidado que você recebe. Para retirar o consentimento, fale com a equipe do serviço."
        ),
    ]
}
