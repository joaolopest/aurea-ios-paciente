# AUREA Paciente iOS · Briefing e Decisões de Craft Mobile

Ritual de Briefing Mobile conduzido com o João em 26/09/2026. Base factual: levantamento do MAESTRO (nota "AUREA Paciente — levantamento": 14 telas + 4 de porta, 19 rotas, 12 conferidas com curl) e inspeção do web local como paciente demo. Este documento é o contrato antes do primeiro Swift. Mudança aqui exige nova rodada com o João.

## 1. Briefing (P1 a P8)

| | Decisão |
|---|---|
| **P1 · O app** | Registro diário de sintomas para quem está em quimioterapia, em casa. Uma vez por dia, menos de 2 minutos. Público adulto, possivelmente acima de 50 anos, no pior dia do ciclo |
| **P1 · Referências** | **Steady** no check-in (uma pergunta, um toque, sem chrome) + **Gentler Streak** como alma (saúde sem culpa). Sem personagem. Ludicidade nível 3 de 5 |
| **P2 · Primeiro launch** | Calma e intimidade. Curiosidade só no fechamento do dia |
| **P3 · Densidade** | Médio, diário curto. Coerente com P2 |
| **P4 · Modo e paleta** | "Papel e céu". Segue o sistema (claro e noite). Um acento: ameixa. **iOS 17 mínimo**, visual iOS 26 quando disponível |
| **P5 · Não pode parecer** | App de hospital / Conecte SUS · Apple Saúde · Duolingo · Medisafe · Google Forms · Ajustes da Apple · o app do paciente no web hoje |
| **P6 · Voz** | A equipe fala ("a gente", "sua equipe"), 2ª pessoa conversacional, forma neutra de gênero. Calmo e caloroso, sem festa. O texto nunca avalia estado de saúde |
| **P7 · Invioláveis** | Os oito da seção 2 |
| **P8 · Motion e haptics** | Patamar 1 (suave) com uma assinatura: o céu do fechamento do dia |

Refs descartadas pelo auto-veto do vault: Sequel (tracker numérico), Yope (sem componente social), Subby (sem logos; cor por categoria fere a lei da cor), Bear (input rápido), One Sec (precisa de adesão diária), Panels (sem artwork).

## 2. Os oito invioláveis

1. **Check-in em modo foco.** Sem barra de abas nem de navegação. Uma pergunta por tela, o toque avança sozinho, alvo mínimo de 56pt, progresso em pontos (VoiceOver: "Pergunta 2 de 5").
2. **Nenhuma cor de risco existe no projeto.** Nenhum token verde, amarelo, âmbar, vermelho, laranja, pêssego, coral, terracota, sálvia, lima, menta ou teal. O modelo de dados omite `resultado`, `classificacoes`, `explicacao`, `regrasDisparadas` e `conjuntoDeLimiaresId`. Duas travas: teste de decode que falha se o campo entrar no modelo, e `scripts/conformidade.sh` no build.
3. **Fechamento igual para todo mundo.** Mesmo céu, mesma frase, qualquer que seja a resposta. A única diferença é conteúdo: o aviso "Entre em contato com o serviço hoje" (quando `pedeContatoComServico`) e as orientações escritas pela equipe. O aviso vem **antes** do céu.
4. **Zero culpa.** Sem sequência de dias. Histórico mostra dias respondidos; dia sem resposta não vira buraco nem alerta. "Check-in não terminado." em tom neutro.
5. **Resposta nunca se perde, confirmação nunca é antecipada.** Rascunho salvo no aparelho a cada toque, sobrevive ao app fechar, reenviado com a mesma `chaveDeIdempotencia`. "Suas respostas chegaram à equipe." só depois que o servidor confirma.
6. **Estado de hoje vem do servidor** (`GET /triagem/historico`, sessão com data civil de hoje), nunca de armazenamento local.
7. **Texto grande de verdade.** SF Pro Rounded, Dynamic Type até `.accessibility5`, sem truncar. No tamanho máximo, os botões de resposta empilham e crescem.
8. **O texto nunca avalia o estado de saúde.** A lista da seção 9 é lei.

## 3. Cores

| Token | Claro | Noite | Uso |
|---|---|---|---|
| `papel` | `#FBF9EF` | `#1C1A21` | fundo de toda tela |
| `folha` | `#FFFFFF` | `#27242D` | cartões, botões de resposta |
| `tinta` | `#0E2739` | `#F2EEE4` | texto, CTA principal, resposta selecionada |
| `tintaSuave` | `#4A5866` | `#B7B0BF` | texto de apoio |
| `ceu` | `#D6E4F5` | `#2B3A52` | formas de fundo, ícone de resposta |
| `lavanda` | `#E6DEF5` | `#3A3150` | fechamento, aba ativa, biblioteca |
| `ameixa` | `#62468A` | `#B9A2E0` | único acento: progresso, rótulos, links |
| `areia` | `#EFE7D6` | `#34302A` | divisórias, estados vazios |
| `linha` | `#E8E1D1` | `#34313B` | hairline de cartão |

Contraste medido (WCAG 2): tinta/papel 14,5:1 · tinta/céu 11,9:1 · ameixa/papel 7,2:1 · noite 14,9:1 · ameixa noite 7,6:1 · tintaSuave/folha 7,3:1 e 7,2:1. Tudo AAA.

Regras: céu e lavanda são superfície, nunca texto. Resposta selecionada = fundo `tinta`, texto `papel`. Nenhum check verde. Nenhuma cor do sistema (`.green`, `.red`, `.orange`, `.yellow`, `.mint`, `.teal`) em lugar nenhum; nem o `.tint` padrão (azul do sistema) vaza: o app declara `.tint(Cor.ameixa)` na raiz. Asset catalog com as duas variantes; ícone com variante tintada (iOS 18).

## Revisão 1 (27/09/2026) — refino pela prévia aprovada

O João pediu o app nativo igual à prévia "papel e céu". Mudou:
- **Fonte: Nunito** (SIL OFL, embutida em `Resources/Fontes`) no lugar da SF Pro Rounded. Três pesos: 600 apoio, 700 rótulo, 800 voz. Tamanhos-base: pergunta 34, saudação 34, título 30, resposta 22, leitura 20, ajuda 18, rótulo 16, número 36.
- **Check-in com a pergunta embaixo**, perto do polegar; o céu respira em cima. Botão de resposta com 78pt de altura, canto 28.
- **Superfície sem contorno**: linha de luz de 1pt embaixo + sombra macia tingida. Cantos: cartão 32, botão 24. Margem lateral 24. CTA com 64pt.
- **Céu mais presente** atrás do conteúdo (proporções da prévia, blur 34).
- **Nome na tela inicial: "AUREA Paciente"**. Ícone: o mesmo anel do app da equipe, com fundo invertido (papel, céu e lavanda) e o ponto em ameixa. Os dois apps, lado a lado, se reconhecem como família e não se confundem.
- **Responder de novo**: depois do check-in do dia, o paciente pode responder as perguntas outra vez (cada envio é uma sessão nova). **Registrar um sintoma**: relato avulso, a qualquer hora, só dos sintomas escolhidos; não conta como check-in do dia.

A tabela da seção 4 abaixo é a versão original (SF Pro Rounded), mantida como histórico.

## 4. Tipografia

SF Pro Rounded do sistema (`.fontDesign(.rounded)`), tudo via `Font.system(size:weight:design:)` com `relativeTo:` para escalar com Dynamic Type. Sem fonte mono: número usa `.monospacedDigit()`.

| Papel | Tamanho base | Peso | Escala com | Onde |
|---|---|---|---|---|
| `saudacao` | 32 | heavy | `.largeTitle` | "Bom dia, Ana" |
| `titulo` | 28 | bold | `.title` | título de tela |
| `pergunta` | 28 | heavy | `.title` | pergunta do check-in (mínimo DC-001) |
| `resposta` | 20 | bold | `.body` | botão de resposta (mínimo DC-001) |
| `leitura` | 20 | medium | `.body` | corpo, orientação, biblioteca |
| `ajuda` | 17 | medium | `.callout` | ajuda da pergunta (mínimo DC-001) |
| `rotulo` | 15 | semibold | `.subheadline` | rótulos de cartão, em caixa normal |
| `numero` | 34 | heavy | `.largeTitle` | ciclo e dia, `.monospacedDigit()` |

Nada abaixo de 15pt no tamanho padrão. Sem caixa alta com espaçamento (a estética de painel do web sai). Entrelinha de leitura 1,4 (`lineSpacing` proporcional). Largura de leitura contida em iPad (≈ 34em).

## 5. Espaço, forma e profundidade

- Grade de 4pt. Margem lateral 20pt. Padding de cartão 20pt. Espaço entre cartões 12pt. Entre seções 28pt.
- Cantos contínuos sempre (`.rect(cornerRadius:style: .continuous)`): cartão 28 · botão de resposta 22 · CTA 20 · peças pequenas 14.
- Profundidade por hairline `linha` + sombra tingida de petróleo em duas camadas (4% a 1pt e 8% a 18pt de raio). Nunca sombra preta sobre creme (ADR-006).
- Formas de fundo: 2 ou 3 elipses de `ceu` e `lavanda` com blur de 40pt, posição fixa por tela (não aleatória), desenhadas em `Canvas`. Elas não se movem durante o check-in.
- iOS 26: barra de abas e botões flutuantes em Liquid Glass nativo. iOS 17 e 18: `.regularMaterial` com a mesma geometria.

## 6. Navegação

- **`TabView` nativo, 5 abas:** Hoje · Histórico · Agenda · Tratamento · Biblioteca. SF Symbols hierárquicos, variante `.fill` na aba ativa, tint ameixa. Escolha consciente pelo nativo: acessibilidade e Liquid Glass de graça no iOS 26; a assinatura visual do app está em outro lugar.
- **Conta** abre pelo avatar no topo de Hoje. **Avisos** pelo sino no topo de Hoje.
- **Check-in** abre em `fullScreenCover` a partir de Hoje, de um widget ou do lembrete. Fechar (✕) pergunta "Parar por agora? Suas respostas ficam guardadas até o fim do dia." com "Continuar respondendo" em destaque.
- Detalhes (verbete, sintoma do mural, alergias, contato) em `NavigationStack` dentro da aba.
- Deep links: `aurea://checkin`, `aurea://biblioteca/{id}`, `aurea://tratamento/sintomas/{apelido}`.

## 7. Telas (paridade com o web + nativo)

| Tela | Fonte | Nota de craft |
|---|---|---|
| Entrar | `POST /autenticacao/entrar` | CPF com máscara e teclado numérico. Erro sempre genérico: "CPF ou senha não conferem." Sem atalhos de demo |
| Primeiro acesso | `POST /conta/senha` | Troca revoga sessões: volta a Entrar com aviso "Senha trocada. Entre com a nova." |
| Recuperar | nenhuma | Tela honesta: a recuperação é com a equipe do serviço |
| Consentimento | `GET/POST /conta/consentimento` | Texto rolável, caixa liberada ao chegar ao fim, `versaoDoTermo` enviada. Navega só após confirmação |
| Lembrete (novo) | local | Pré-permissão depois do **primeiro** check-in: escolher horário, depois o pedido do sistema |
| Hoje | historico + perfil + agenda | Estados: pendente · em andamento ("Continuar de onde parou") · respondido (frase + orientações + aviso de contato se houver). Previsão vencida vira frase, nunca "Passou 40 dias" |
| Check-in | `GET /triagem/arvore`, `POST /triagem/sessoes`, `POST …/respostas` | Árvore sempre do servidor. Tipos: sim/não, opção, número (teclado decimal, limites ditos em frase). Dor 0–10 como escala de toque, sem cor. Envio automático após a última pergunta visível |
| Fechamento | retorno do envio | Aviso de contato primeiro, céu depois, orientações, "Voltar para o início". Lista de orientações vazia é estado válido |
| Histórico | `GET /triagem/historico` | Diário por mês. Linha: dia, "hoje"/"ontem", sintomas em rótulo leigo ou "Nada a relatar.", marca "Começou um ciclo novo" |
| Agenda | `GET /paciente/agenda` | "Próximo" em destaque, "Depois", "Já aconteceu" esmaecido. Botão "Adicionar ao Calendário" (EventKit, só escrita) |
| Tratamento | `GET /paciente/perfil` | Protocolo em frase, mural de sintomas expansível, médico, contatos (toque para ligar), alergias |
| Sintoma do mural | perfil | Página própria, deep link |
| Alergias | `POST /paciente/alergias` | Só substância (reação não tem coluna). Relê do servidor. "Este registro vai para a equipe conferir." |
| Biblioteca | `GET /paciente/biblioteca` | Busca sem acento, cartões por categoria em `lavanda` |
| Verbete | `GET /paciente/biblioteca/:id` | Tipografia de leitura, "Atualizado em" |
| Falar com a enfermagem | `GET/POST /paciente/solicitacoes-de-contato` | **Sem campo de motivo** até existir coluna. Pedido aberto vira leitura. "Este não é um canal de emergência." em todo ponto de contato |
| Avisos | `GET /paciente/notificacoes` | Não lida por peso de fonte. Marcar como lida ao abrir |
| Conta | `/autenticacao/eu` | Trocar senha, ver o termo aceito, horário do lembrete, sair. Excluir conta: pendente de rota |

Selo "Não validado clinicamente" permanece onde o web mostra (mural e biblioteca), em `areia` com texto `tinta`, discreto e legível.

## 8. Motion e haptics (Patamar 1)

| Momento | Motion | Haptic |
|---|---|---|
| Toque em resposta | preenche de `tinta` em 150ms | `.selection` |
| Próxima pergunta | esmaecimento + 8pt vertical, `spring(response: 0.35, dampingFraction: 1)`. **Nunca deslizar para o lado** | nenhum |
| Número fora do limite | mensagem em frase, campo não treme | `.warning` uma vez |
| **Céu do fechamento** | elipses se expandem, estrelas acendem em sequência, ≈1,2s, `spring(response: 0.6, dampingFraction: 0.75)`, único quique do app | `.soft` → 300ms → `.success`, única sequência do app |
| Aviso de contato | aparece parado | nenhum |
| Pull to refresh | nativo | nativo |
| Reduce Motion | tudo vira esmaecimento; o céu aparece formado | mantidos |

Durante o check-in nada se move no fundo. Nenhuma animação em loop em nenhuma tela.

## 9. Voz e texto

**Proibido** (lei, não estilo):
- Avaliação clínica: "Você está bem", "Tudo certo!", "Ótimo!", "Continue assim", "Parece grave", "Fique tranquilo".
- Culpa: "Você esqueceu", "Sentimos sua falta", "Não perca sua sequência", "Faz N dias".
- Festa: "Parabéns!", "Arrasou!", emoji, confete.
- Vago: "Carregando…", "Algo deu errado", "Nenhum item encontrado", "Continuar" sem contexto.
- Técnico: nome de campo, enum cru, "sessão", "triagem", "classificação", "limiar".
- Promessa: vigilância em tempo real, cura, melhora.

**Frases-base:**
- Fechamento: "Que bom que você respondeu hoje." / "Suas respostas chegaram à equipe."
- Lembrete: "Como você está hoje? São dois minutos." (não repete no mesmo dia)
- Erro de envio: "Suas respostas não foram enviadas. Elas estão guardadas aqui; tente de novo quando tiver sinal."
- Vazio de agenda: "Nada marcado por enquanto."
- Contato: "Este não é um canal de emergência. Se a situação for grave, procure o serviço."

Todo enum que vira texto passa por um mapa de rótulo em português com fallback visível (feio de propósito, pego no primeiro teste), como o `rotuloDaOpcao()` do web.

## 10. Componentes-assinatura

- **Cartão Hoje:** o maior elemento da tela, pergunta em `pergunta`, CTA `tinta` de 56pt.
- **Botão de resposta:** `folha`, 22 de canto, ícone em círculo `ceu` à esquerda, 56pt mínimo, cresce com o texto.
- **Pontos de progresso:** 6pt, o atual vira pílula de 18pt em `ameixa`.
- **Escala de dor 0–10:** 11 alvos em duas linhas no iPhone pequeno, número grande, sem gradiente de cor.
- **Céu:** `Canvas` com elipses e estrelas; nunca imagem.
- **Skeleton:** imita o layout real da tela, em `areia`, sem shimmer rápido.
- **Estado vazio:** frase + forma de fundo, sem ilustração genérica.

## 11. Fora do app

- **Widget pequeno** (tela inicial e StandBy) e **accessoryRectangular / accessoryCircular** (tela bloqueada): "Check-in de hoje": pendente ou respondido. Toque abre `aurea://checkin`. Nunca mostra sintoma, nem na tela bloqueada. Estado gravado em App Group pelo app só após confirmação do servidor; timeline com entrada à meia-noite que volta a "pendente"; `WidgetCenter.reloadAllTimelines()` após envio. Placeholder com `.redacted`.
- **Live Activity: não.** Não há evento finito.
- **Lembrete diário:** notificação local no horário escolhido. Agendada para os próximos 7 dias, não repetitiva; a de hoje é cancelada ao concluir o check-in e o calendário é reagendado a cada abertura. Sem backend.

## 12. Acessibilidade

- VoiceOver completo em português: resposta selecionada com `.isSelected`, progresso anunciado, céu decorativo oculto (`accessibilityHidden`), aviso de contato anunciado primeiro.
- Dynamic Type até `.accessibility5`, testado em `.accessibility3` no mínimo em toda tela.
- Nenhuma informação só por cor. Suporte a Negrito, Aumentar Contraste e Reduzir Transparência (material vira sólido).
- Alvos de 56pt no check-in, 44pt no resto.

## 13. Stack e segurança

- SwiftUI · iOS 17 mínimo · Swift 6 estrito · `@Observable` · xcodegen (`.xcodeproj` fora do git) · zero dependências.
- **Override da Stack Canônica:** sem Supabase; API REST própria da AUREA via `ClienteAPI` (copiado do app do profissional). `DataCivil` copiado (data `@db.Date` lida em UTC).
- Token no Keychain (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`). Rascunho do check-in em arquivo com `FileProtectionType.complete`. Face ID desligado (decisão do João).
- Debug aponta para `localhost:3333`. Comitê de Ética opção A: só dado sintético, nada em produção.
- Modelos a partir do curl real, enum com `.desconhecido(String)`, toda escrita conferida lendo de volta.
- **Não copiar do app do profissional:** `Dados/Modelos/*`, telas de admin, prontuário e plantão, e os tokens de risco de `Sistema/`.
- Repositório separado: `aurea-ios-paciente`. Nome na tela inicial: AUREA.

## 14. Defaults da Apple quebrados de propósito

| Default | Troca | Por quê |
|---|---|---|
| `.tint` azul do sistema | ameixa | azul do sistema ao lado de petróleo parece dois apps |
| Cores semânticas do sistema | tokens próprios | `.green`/`.red` são classificação clínica aqui |
| `List` em telas de conteúdo | cartões em `ScrollView` | anti-ref Ajustes; só Conta usa `List` |
| Transição push lateral no check-in | esmaecimento vertical | náusea e sensibilidade vestibular (DC-001) |
| `NavigationStack` no check-in | `fullScreenCover` sem chrome | modo foco (Steady) |
| SF Pro | SF Pro Rounded | tom caloroso sem personagem |

## 15. Pendências externas

| Item | Dono | Bloqueia |
|---|---|---|
| API filtrar classificação para o perfil PACIENTE (item 259) | Prumo | nada; contorno no modelo |
| Rota de exclusão de conta | Prumo | publicação na App Store (diretriz 5.1.1(v)) |
| Coluna `motivo` no pedido de contato | Prumo | campo de motivo no app |
| Coluna `reacao` na alergia | Prumo | campo de reação |
| Texto do termo servido pela API (hoje está no front do web) | MAESTRO/Prumo | risco de divergência de versão |
| Push remoto (avisos da equipe) | Prumo | nada no MVP; lembrete é local |
| Validação clínica dos 3 desvios da árvore | equipe clínica | nada no app; a árvore vem do servidor |

## 16. Ordem de construção

1. Repositório, `project.yml`, `Sistema/` do paciente (tokens desta página), `ClienteAPI`, `DataCivil`, `scripts/conformidade.sh`, teste de decode da lei 1.
2. Porta: Entrar, Primeiro acesso, Recuperar, Consentimento.
3. **Check-in e fechamento** (a tela mais importante), com rascunho persistente e idempotência.
4. Hoje com os três estados.
5. Histórico, Agenda, Tratamento, Alergias, Biblioteca, Verbete, Contato, Avisos, Conta.
6. Lembrete local e pré-permissão.
7. Widgets.
8. Passada de acessibilidade em `.accessibility5`, VoiceOver e Reduce Motion, com prints do simulador.

## ✅ Checklist anti-default

- [ ] Primeira tela emenda com a launch screen (papel liso, sem logo girando)
- [ ] Tab bar com símbolos `.fill` e tint ameixa, não 5 ícones cinza
- [ ] Hoje sem large title padrão: saudação própria
- [ ] Estados vazios com frase e forma, não "Nenhum item"
- [ ] Skeleton que imita o layout, não spinner solto
- [ ] Haptics só nos pontos da seção 8
- [ ] Claro e noite testados
- [ ] Dynamic Type testado em `.accessibility3` e `.accessibility5`
- [ ] Reduce Motion testado
- [ ] `scripts/conformidade.sh` verde
