#!/bin/bash
# conformidade.sh — a lei 1 do produto, verificada a cada build.
#
#   "O paciente nunca vê cor de risco, nome de regra nem nome de campo."
#
# No web a lei é imposta por tipo e por scripts/conformidade.mjs. Aqui, o equivalente:
# o código do app não pode NOMEAR a classificação, nem declarar cor que o olho confunda
# com a escala de risco. Se o nome não existe no código, nenhuma tela mostra por engano.
#
# Falha o build (exit 1) e diz o arquivo e a linha. Roda também sozinho:
#   ./scripts/conformidade.sh
set -uo pipefail
cd "$(dirname "$0")/.."
ALVO="AureaPaciente"
falhas=0

checar() {
  local descricao="$1" padrao="$2"
  local achados
  # Linha de comentário não conta: explicar a lei ("silêncio não é verde") não a viola.
  achados=$(grep -rnE --include='*.swift' "$padrao" "$ALVO" \
    | grep -vE '^[^:]+:[0-9]+:[[:space:]]*(//|\*|/\*)' \
    | grep -v '// conformidade: permitido' || true)
  if [[ -n "$achados" ]]; then
    echo "error: [conformidade] $descricao"
    echo "$achados" | sed 's/^/  /'
    falhas=$((falhas + 1))
  fi
}

# 1. Campos da classificação clínica. O modelo do paciente os omite de propósito
#    (docs/CONTORNOS.md, C-01). Aparecer aqui é o primeiro passo para aparecer na tela.
checar "campo de classificação no código do paciente" \
  '\b(resultado|classificacao|classificacoes|explicacao|regrasDisparadas|conjuntoDeLimiares(Id)?|enfermagemAvisada|validadoClinicamente|versaoDoConjunto)\b'

# 2. Nomes da escala de risco.
checar "nome da escala de risco" '\b(VERDE|AMARELO|VERMELHO|verde|amarelo|vermelho|risco|Risco)\b'

# 3. Cores do sistema que são, ou parecem, a escala de risco. O app só usa os tokens de Cor.
checar "cor do sistema proibida (verde, vermelho, amarelo, laranja, menta, teal)" \
  '(Color|UIColor|\.foregroundStyle\(|\.fill\(|\.tint\(|\.background\()?\.(green|red|yellow|orange|mint|teal)\b'
checar "cor do sistema fora dos tokens" '\b(Color|UIColor)\.(green|red|yellow|orange|mint|teal|systemGreen|systemRed|systemYellow|systemOrange|systemMint|systemTeal)\b'

# 4. Identificador cru de opção na tela: Text("BOCA_OU_GARGANTA"). Rótulo passa por Rotulos.swift.
checar "identificador cru em Text()" 'Text\("[A-Z]+(_[A-Z]+)+"\)'

if [[ $falhas -gt 0 ]]; then
  echo "error: [conformidade] $falhas regra(s) violada(s). Ver docs/BRIEFING-E-DCM.md §2."
  exit 1
fi
echo "[conformidade] ok: nenhuma cor de risco, nenhum campo de classificação."
