#!/usr/bin/env bash
#
# Regenerates every screenshot on the user documentation pages.
#
#   bash tools/screenshots.sh            capture, then install
#   bash tools/screenshots.sh capture    drive the simulators only
#   bash tools/screenshots.sh install    composite, optimise and install only
#
# Captures run on three devices because the app is not the same on all of
# them: the clients roster exists only behind the desktop nav rail at 600dp
# and up, and two screens are documented per platform. The images are
# committed, so the docs build needs none of this.

set -euo pipefail

cd "$(dirname "$0")/.."

readonly RAW_DIR="build/screenshots"
readonly OPTIMISED_DIR="build/screenshots/optimised"
readonly INSTALL_DIR="src/docs/modules/ROOT/assets/images"

readonly IPHONE_NAME="iPhone 16 Pro"
readonly IPAD_NAME="iPad Pro 11-inch (M4)"
readonly AVD_NAME="Medium_Phone_API_36.1"

# Documentation images are 750px wide and must stay under 200KB each, so the
# docs repository does not grow by a megabyte every time a screen is retouched.
readonly TARGET_WIDTH=750
readonly MAX_BYTES=200000

# The contract. Step "verify" checks against this list rather than against
# whatever happens to be on disk, so a capture suite that silently stopped
# half way fails the run instead of installing a partial set.
readonly EXPECTED_IMAGES=(
  hero
  first-workout
  workout-logging
  cardio-session
  heart-rate-panel
  coach-mode
  stretching
  exercise-library
  templates
  programmes
  history
  analytics
  body-metrics
  settings
  notifications
  clients
  sync-ios
  sync-android
  nav-ios
  nav-android
)

log() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
die() { printf '\033[31merror: %s\033[0m\n' "$1" >&2; exit 1; }

# ── Devices ────────────────────────────────────────────────────────────────

# Several simulators can share a name, one per installed runtime, so a
# `flutter drive -d "iPhone 16 Pro"` is ambiguous. Resolve to the UDID of the
# last available match, which is the newest runtime simctl lists.
simulator_udid() {
  local name="$1" udid
  udid=$(xcrun simctl list devices available |
    grep -F "$name (" |
    tail -1 |
    sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
  [[ -n "$udid" ]] || die "no simulator named '$name' is available"
  printf '%s' "$udid"
}

boot_simulator() {
  xcrun simctl boot "$1" 2>/dev/null || true
  xcrun simctl bootstatus "$1" -b >/dev/null
}

boot_emulator() {
  if adb devices | grep -q "emulator-[0-9]*[[:space:]]*device"; then
    return
  fi
  local emulator="${ANDROID_HOME:-$HOME/Library/Android/sdk}/emulator/emulator"
  if command -v emulator >/dev/null; then
    emulator="emulator"
  fi
  "$emulator" -avd "$AVD_NAME" -no-snapshot -no-boot-anim >/dev/null 2>&1 &
  adb wait-for-device
  until [[ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]; do
    sleep 2
  done
}

drive() {
  local target="$1"
  shift
  flutter drive \
    --driver=test_driver/integration_test.dart \
    --target="integration_test/screenshots/$target" \
    "$@"
}

# ── Capture ────────────────────────────────────────────────────────────────

capture() {
  local iphone ipad
  iphone=$(simulator_udid "$IPHONE_NAME")
  ipad=$(simulator_udid "$IPAD_NAME")

  # Android runs first, and deliberately so. progress_test also photographs
  # history, analytics and body metrics, which the docs shoot on an iPhone;
  # running Android last would leave Android versions of those three behind
  # under iPhone filenames, which no later step could detect.
  log "Android: sync and navigation ($AVD_NAME)"
  boot_emulator
  # --flavor dev because the project has three Android flavours and a bare
  # assembleDebug produces no single APK. --profile because the debug APK is
  # ~120MB, mostly kernel_blob.bin, and installs fail on an AVD with a full
  # data partition; profile mode is AOT-compiled, small, and photographs the
  # same.
  drive progress_test.dart -d emulator-5554 --flavor dev --profile \
    --dart-define=SCREENSHOT_PLATFORM=android

  log "iPhone: training screens ($IPHONE_NAME)"
  boot_simulator "$iphone"
  drive training_test.dart -d "$iphone"

  log "iPhone: library screens"
  drive library_test.dart -d "$iphone"

  log "iPhone: progress screens"
  drive progress_test.dart -d "$iphone"

  log "iPad: clients roster ($IPAD_NAME)"
  boot_simulator "$ipad"
  drive clients_test.dart -d "$ipad"
}

# ── Hero ───────────────────────────────────────────────────────────────────

# The hero reuses three captures rather than shooting three more, so it can
# never drift from the images further down the same page.
compose_hero() {
  log "Compositing the hero"
  for name in workout-logging heart-rate-panel analytics; do
    [[ -f "$RAW_DIR/$name.png" ]] ||
      die "the hero needs $RAW_DIR/$name.png, which the capture did not produce"
  done

  # Workout logging centred and full size, the other two behind it at 80% and
  # offset either side so they read as a stack rather than a row.
  local centre_h=1200 side_h=960 canvas_w=1200 canvas_h=1260
  local side_y=$(((canvas_h - side_h) / 2))

  magick -size "${canvas_w}x${canvas_h}" xc:'#0A0A0A' \
    \( "$RAW_DIR/heart-rate-panel.png" -resize "x${side_h}" \) \
    -gravity NorthWest -geometry "+0+${side_y}" -composite \
    \( "$RAW_DIR/analytics.png" -resize "x${side_h}" \) \
    -gravity NorthEast -geometry "+0+${side_y}" -composite \
    \( "$RAW_DIR/workout-logging.png" -resize "x${centre_h}" \) \
    -gravity North -geometry "+0+30" -composite \
    "$RAW_DIR/hero.png"
}

# ── Verify, optimise, install ──────────────────────────────────────────────

verify_manifest() {
  local missing=()
  for name in "${EXPECTED_IMAGES[@]}"; do
    [[ -f "$RAW_DIR/$name.png" ]] || missing+=("$name.png")
  done
  if ((${#missing[@]} > 0)); then
    printf '\033[31mmissing %d of %d expected images in %s:\033[0m\n' \
      "${#missing[@]}" "${#EXPECTED_IMAGES[@]}" "$RAW_DIR" >&2
    printf '  %s\n' "${missing[@]}" >&2
    die "refusing to install a partial set"
  fi
  log "All ${#EXPECTED_IMAGES[@]} expected images are present"
}

optimise() {
  log "Resizing to ${TARGET_WIDTH}px and optimising"
  rm -rf "$OPTIMISED_DIR"
  mkdir -p "$OPTIMISED_DIR"

  for name in "${EXPECTED_IMAGES[@]}"; do
    local out="$OPTIMISED_DIR/$name.png"
    magick "$RAW_DIR/$name.png" \
      -resize "${TARGET_WIDTH}x" -strip \
      -define png:compression-level=9 "$out"

    # Quantise only what still exceeds the budget. Most screens are flat dark
    # panels that compress losslessly to well under it; the few with large
    # gradients need a 256-colour palette, which costs a little dithering
    # noise in the gradient and nothing at all in the text.
    local bytes
    bytes=$(stat -f%z "$out")
    if ((bytes > MAX_BYTES)); then
      magick "$RAW_DIR/$name.png" \
        -resize "${TARGET_WIDTH}x" -strip -colors 256 \
        -define png:compression-level=9 "$out"
      bytes=$(stat -f%z "$out")
      ((bytes <= MAX_BYTES)) ||
        die "$name.png is ${bytes} bytes after quantising, over the ${MAX_BYTES} budget"
    fi
    printf '  %-20s %6s KB\n' "$name.png" "$((bytes / 1024))"
  done
}

install_images() {
  log "Installing into $INSTALL_DIR"
  mkdir -p "$INSTALL_DIR"
  for name in "${EXPECTED_IMAGES[@]}"; do
    cp "$OPTIMISED_DIR/$name.png" "$INSTALL_DIR/$name.png"
  done
  printf '  %d images, %s total\n' \
    "${#EXPECTED_IMAGES[@]}" "$(du -sh "$INSTALL_DIR" | cut -f1)"
}

# ── Entry point ────────────────────────────────────────────────────────────

main() {
  case "${1:-all}" in
    capture) capture ;;
    install)
      compose_hero
      verify_manifest
      optimise
      install_images
      ;;
    all)
      capture
      compose_hero
      verify_manifest
      optimise
      install_images
      ;;
    *) die "unknown phase '$1' (expected: capture, install, or all)" ;;
  esac
  log "Done"
}

main "$@"
