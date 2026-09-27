# Contornos e decisões deliberadas

Todo contorno de defeito ou lacuna do backend mora aqui, com o teste que diz quando ele pode sair. Antes de "completar" um modelo ou "corrigir" um comportamento que parece faltar, procure aqui: é provável que seja decisão.

Formato: **o quê** · **por quê** · **onde** · **como remover**.

---

## C-01 · Classificação omitida dos modelos (lei 1) — PERMANENTE

- **O quê.** Nenhum modelo declara `resultado`, `classificacao(oes)`, `explicacao`, `regrasDisparadas`, `conjuntoDeLimiaresId`, `situacao`, `enfermagemAvisada`, `validadoClinicamente` nem `versaoDoConjunto`.
- **Por quê.** Lei 1: o paciente nunca vê cor de risco, nome de regra nem nome de campo. Até 26/09/2026 a API mandava tudo isso ao paciente (`POST /triagem/sessoes/:id/respostas` e `GET /triagem/sessoes/:id`). O Prumo corrigiu no servidor (`apps/api/src/servicos/resposta-ao-paciente.ts`, item 259); a omissão aqui é a segunda trava.
- **Onde.** `Dados/Modelos/Triagem.swift` (comentário de cabeçalho). Travas: `scripts/conformidade.sh` (falha o build se o nome aparecer) e `LeiUmTests` (decodifica a resposta com vazamento e falha se o modelo guardar a cor).
- **Como remover.** Não remove. Mesmo com a API corrigida, a omissão continua: é defesa em profundidade.

## C-02 · `valorNumerico` aceita texto

- **O quê.** `NumeroFlexivel` decodifica `"38.9"` e `38.9`.
- **Por quê.** `valorNumerico` é Decimal no Prisma e chega como texto no JSON.
- **Onde.** `Dados/Modelos/Triagem.swift`.
- **Como remover.** Quando `curl /triagem/historico` devolver número, `NumeroFlexivel` pode virar `Double`. Não há pressa: aceitar os dois não custa nada.

## C-03 · Pedido de contato sem campo de motivo

- **O quê.** "Falar com a enfermagem" não pede texto.
- **Por quê.** A coluna `motivo` não existe: o POST aceita o texto e joga fora, e a fila mostra "Sem motivo informado" para todos. Pedir texto seria pedir para descartar.
- **Onde.** `Funcoes/Contato/ContatoView.swift`.
- **Como remover.** Quando existir a migration e `GET /paciente/solicitacoes-de-contato` devolver `motivo` que foi enviado, acrescentar o campo opcional e conferir lendo de volta.

## C-04 · Alergia sem reação

- **O quê.** O formulário de alergia pede só a substância.
- **Por quê.** `reacao` não tem coluna (mesmo motivo do C-03).
- **Onde.** `Funcoes/Tratamento/TratamentoView.swift` (`AlergiasView`).
- **Como remover.** Migration com `reacao` + curl confirmando que volta no perfil.

## C-05 · Texto do termo copiado do web

- **O quê.** O texto do termo de consentimento está no app (`TermoDeConsentimento.swift`), cópia de `apps/web/src/app/consentimento/page.tsx`.
- **Por quê.** A API só serve `versaoVigente` (`demo-0`), não o texto. Divergência já existente: o web mostra "Versão 1.0" e a API aceita `demo-0`. O app mostra a versão da API.
- **Como remover.** Rota que sirva texto + versão juntos. Então o app lê do servidor e o arquivo some.

## C-06 · Mural de sintomas copiado do web

- **O quê.** `MuralDeSintomas.swift`, gerado por script de `packages/contratos/src/mural.ts` (versão `rascunho-0`).
- **Por quê.** O mural é conteúdo fixo do front. Selo de não validado obrigatório enquanto `MURAL_VALIDADO_CLINICAMENTE` for falso.
- **Como remover.** Mural servido pela API (ou pela biblioteca), com versão.

## C-07 · Sem rota de exclusão de conta

- **O quê.** A Conta diz "para excluir a conta, fale com a equipe do serviço".
- **Por quê.** Não há rota. **Bloqueia publicação na App Store** (diretriz 5.1.1(v)).
- **Como remover.** Rota de exclusão (Prumo) + botão com confirmação em duas etapas na Conta.

## C-08 · Agenda sem "Já aconteceu"

- **O quê.** A agenda mostra só de hoje em diante.
- **Por quê.** `GET /paciente/agenda` sem `de` começa em hoje; o passado exige outra chamada e não foi priorizado nesta rodada.
- **Como remover.** Segunda chamada com `de`/`ate` no passado, seção esmaecida.

---

## Decisões de produto que divergem do web

## D-01 · A sessão do check-in abre no PRIMEIRO toque — ⚠️ confirmar com o João

- **Web:** abre a sessão só no fim (`POST /triagem/sessoes` junto com as respostas). Resultado: quem começa e desiste nunca aparece para a equipe; o estado `ABANDONADA` só nasce de falha de rede.
- **iOS:** abre no primeiro toque, com a chave de idempotência do rascunho. Quem começa e não termina aparece no painel como "não terminado" depois da varredura do servidor (`HORAS_ATE_ABANDONO`) — é para isso que a varredura e a lei 3 ("silêncio não é verde") existem.
- **Efeito colateral:** o paciente que responde uma pergunta, fecha o app e volta depois de passado o prazo tem a sessão encerrada; o app detecta o 409, abre sessão nova com as MESMAS respostas e envia. Nada se perde.
- **Onde.** `Funcoes/Checkin/CheckinStore.swift` (`garantirSessaoAberta`, `resolverConflito`).
- **Para voltar ao comportamento do web:** remover a chamada `garantirSessaoAberta()` de `responder(_:)`.

## D-02 · Rascunho do check-in no aparelho

- Única exceção à regra "dado de saúde só na memória": `RascunhoDoCheckin`, arquivo com `FileProtectionType.complete`, fora do backup, apagado ao concluir, ao virar o dia e ao sair da conta. Existe para a resposta nunca se perder (inviolável 5).
