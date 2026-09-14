#!/bin/bash
# Installs the optional matrix-rain extras: a background plugin that draws
# the falling-glyphs animation on the wallpaper layer, and a watcher that
# fades idle kitty terminals so the rain shows through. Both are no-ops
# unless the "matrix" theme is active. Run this from inside the cloned
# theme directory (~/.config/omarchy/themes/matrix after `omarchy theme
# install`), or point EXTRAS_DIR at wherever you checked this repo out.

set -euo pipefail

EXTRAS_DIR="${EXTRAS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/extras" && pwd)}"
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$USER.background"
BIN_DIR="$HOME/.local/bin"
AUTOSTART="$HOME/.config/hypr/autostart.lua"
KITTY_CONF="$HOME/.config/kitty/kitty.conf"

echo "==> Background plugin"
if [[ ! -d $PLUGIN_DIR ]]; then
  omarchy plugin clone omarchy.background
fi
cp "$EXTRAS_DIR/Background.qml" "$PLUGIN_DIR/Background.qml"

echo "==> Idle-rain watcher"
mkdir -p "$BIN_DIR"
cp "$EXTRAS_DIR/omarchy-matrix-idle-rain" "$BIN_DIR/omarchy-matrix-idle-rain"
chmod +x "$BIN_DIR/omarchy-matrix-idle-rain"

echo "==> Hyprland autostart"
if [[ -f $AUTOSTART ]] && ! grep -q "omarchy-matrix-idle-rain" "$AUTOSTART"; then
  {
    echo
    echo "-- Matrix theme: fade idle kitty terminals' backgrounds so the animated"
    echo "-- rain wallpaper shows through empty cells. No-op on other themes."
    echo 'o.launch_on_start("omarchy-matrix-idle-rain")'
  } >>"$AUTOSTART"
  echo "  added to $AUTOSTART"
else
  echo "  already present or file missing, skipped"
fi

echo "==> kitty.conf"
if [[ -f $KITTY_CONF ]]; then
  for line in \
    'allow_remote_control yes' \
    'listen_on unix:${XDG_RUNTIME_DIR}/omarchy-kitty-{kitty_pid}' \
    'dynamic_background_opacity yes'
  do
    key=${line%% *}
    if ! grep -q "^$key " "$KITTY_CONF"; then
      echo "$line" >>"$KITTY_CONF"
      echo "  added: $line"
    fi
  done
else
  echo "  $KITTY_CONF not found, skipped — add these lines yourself:"
  printf '    %s\n' 'allow_remote_control yes' \
    'listen_on unix:${XDG_RUNTIME_DIR}/omarchy-kitty-{kitty_pid}' \
    'dynamic_background_opacity yes'
fi

cat <<'EOF'

Done. Next steps:
  omarchy theme set matrix
  omarchy restart shell
  omarchy restart terminal

The watcher only starts on next login (it's in autostart.lua). To start it
now without logging out:
  setsid nohup omarchy-matrix-idle-rain >/dev/null 2>&1 &
disown

Tune the fade with env vars before autostart runs, e.g. in autostart.lua:
  MATRIX_RAIN_IDLE_SECONDS=90 MATRIX_RAIN_OPACITY=0.6 omarchy-matrix-idle-rain
EOF
