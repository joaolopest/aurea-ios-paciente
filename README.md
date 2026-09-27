# AUREA Paciente · iOS

App do paciente em quimioterapia: o check-in diário de sintomas em casa, a agenda, o tratamento explicado e a biblioteca da equipe. Irmão do AUREA Plantão (app da equipe), em repositório separado.

**Só dado sintético** até o parecer do Comitê de Ética (opção A). Debug aponta para `localhost:3333`.

## Rodar

```bash
./run.sh                      # gera o projeto, builda, instala e abre no simulador
./scripts/conformidade.sh     # a lei 1, verificada (também roda em todo build)
xcodebuild -project AureaPaciente.xcodeproj -scheme AureaPaciente \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" test
maestro test maestro/checkin.yaml   # fluxo completo, com screenshots em maestro/shots/
```

Conta de demonstração: CPF `123.456.789-09`, senha `aurea-demo-2026` (sintética).

## Stack

SwiftUI · iOS 17 mínimo · Swift 6 estrito · `@Observable` · xcodegen (`.xcodeproj` fora do git) · zero dependências · API REST própria da AUREA.

## Antes de mexer

1. `docs/BRIEFING-E-DCM.md` — o contrato de design: os oito invioláveis, tokens, voz, motion.
2. `docs/CONTORNOS.md` — o que parece faltar e é decisão.
3. As três leis do produto valem aqui com mais força que no web: o paciente **nunca** vê cor de risco, nome de regra nem nome de campo; silêncio não é verde; o texto nunca avalia o estado de saúde.

## Estrutura

```
AureaPaciente/
  App/          raiz, abas
  Sistema/      design system "papel e céu" (cores, tipo, forma, movimento, componentes)
  Dados/        ClienteAPI, DataCivil, modelos (do curl real), rótulos, rascunho
  Seguranca/    sessão, token no Keychain
  Funcoes/      uma pasta por tela
AureaPacienteTests/   lei 1 + contratos, contra Fixtures/ do curl real
maestro/              fluxos de navegação
scripts/conformidade.sh
```
