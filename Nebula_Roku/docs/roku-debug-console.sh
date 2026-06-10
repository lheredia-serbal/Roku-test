#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROKU_PORT="${ROKU_DEBUG_PORT:-8085}"
RECONNECT_DELAY="${ROKU_RECONNECT_DELAY:-2}"

find_launch_host() {
    local launch_file="$PROJECT_DIR/.vscode/launch.json"
    [[ -f "$launch_file" ]] || return 0
    sed -nE 's/^[[:space:]]*"host"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$launch_file" | head -n 1
}

ROKU_HOST="${ROKU_HOST:-$(find_launch_host)}"
if [[ -z "$ROKU_HOST" ]]; then
    echo "Uso: ROKU_HOST=<ip-del-roku> $0" >&2
    echo "También puedes definir host en .vscode/launch.json." >&2
    exit 1
fi

LOG_DIR="${ROKU_LOG_DIR:-$PROJECT_DIR/logs/roku}"
mkdir -p "$LOG_DIR"
SESSION_LOG="$LOG_DIR/roku-$(date -u +%Y%m%dT%H%M%SZ).log"
LATEST_LOG="$LOG_DIR/latest.log"
: > "$SESSION_LOG"
ln -sfn "$(basename "$SESSION_LOG")" "$LATEST_LOG" 2>/dev/null || true

log_line() {
    local line="$1"
    local timestamp
    timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '[%s] %s\n' "$timestamp" "$line" | tee -a "$SESSION_LOG"

    if [[ "$line" =~ (BrightScript\ Debugger|Runtime\ Error|Syntax\ Error|BRIGHTSCRIPT|crash|Crash|fatal|Fatal|backtrace|Backtrace|Channel\ terminated|Application\ exited) ]]; then
        printf '[%s] >>> POSIBLE CRASH/ERROR DETECTADO: revisa las líneas anteriores <<<\n' "$timestamp" | tee -a "$SESSION_LOG"
    fi
}

log_line "Capturando consola de $ROKU_HOST:$ROKU_PORT"
log_line "Archivo de sesión: $SESSION_LOG"
log_line "Detén la captura con Ctrl+C. Si el canal se cierra, se intentará reconectar."

trap 'log_line "Captura detenida por el usuario."; exit 0' INT TERM

while true; do
    log_line "Conectando con la consola de depuración Roku..."

    if { exec 3<>"/dev/tcp/$ROKU_HOST/$ROKU_PORT"; } 2>/dev/null; then
        log_line "Conexión establecida. Esperando salida del canal..."
        while IFS= read -r -u 3 line; do
            log_line "$line"
        done
        exec 3<&- 3>&-
        log_line "Conexión cerrada inesperadamente; posible cierre/crash del canal. Reintentando en ${RECONNECT_DELAY}s..."
    else
        log_line "Consola no disponible todavía. Reintentando en ${RECONNECT_DELAY}s..."
    fi

    sleep "$RECONNECT_DELAY"
done
