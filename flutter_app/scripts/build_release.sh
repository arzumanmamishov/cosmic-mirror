#!/usr/bin/env bash
# Build store-ready release artifacts (Google Play .aab + App Store .ipa).
# Builds only — nothing is uploaded.
#
# Usage:
#   REVENUECAT_API_KEY_IOS=appl_... REVENUECAT_API_KEY_ANDROID=goog_... \
#     scripts/build_release.sh [android|ios|all]      (default: all)
#
# Env vars:
#   REVENUECAT_API_KEY_IOS      required for ios      RevenueCat public Apple
#                                                     SDK key (appl_…)
#   REVENUECAT_API_KEY_ANDROID  required for android  RevenueCat public Google
#                                                     SDK key (goog_…)
#   REVENUECAT_API_KEY          optional  fallback when the per-platform var is
#                                         unset (must still match the platform)
#   API_BASE_URL                optional  default https://api.livelyapp.co
#
# Premium is sold only through App Store / Google Play in-app purchases
# (RevenueCat); the app contains no Stripe SDK. RevenueCat keys are
# platform-specific — RevenueCat → Project settings → API keys.
#
# Debug symbols go to build/debug-info/<platform>. They are gitignored but MUST
# be archived privately per release — without them obfuscated crash stack
# traces cannot be symbolicated (`flutter symbolize`).
set -euo pipefail

cd "$(dirname "$0")/.."

TARGET="${1:-all}"
case "$TARGET" in android|ios|all) ;; *)
  echo "usage: $0 [android|ios|all]" >&2; exit 64 ;;
esac

API_BASE_URL="${API_BASE_URL:-https://api.livelyapp.co}"

die() { echo "error: $*" >&2; exit 1; }

[[ "$API_BASE_URL" == https://* ]] || die "API_BASE_URL must be https:// (got $API_BASE_URL)"

# rc_key_for IOS|ANDROID — the RevenueCat public SDK key for that platform.
# The app rejects a key for the wrong store at runtime (purchases would be
# silently disabled), so the prefix is enforced here: appl_ for iOS, goog_
# for Android.
rc_key_for() {
  local platform_var="REVENUECAT_API_KEY_$1"
  local key="${!platform_var:-${REVENUECAT_API_KEY:-}}"
  [[ -n "$key" && "$key" != "your_revenuecat_api_key" ]] \
    || die "$platform_var is not set (RevenueCat public SDK key for $1)"
  local prefix
  case "$1" in
    IOS) prefix=appl_ ;;
    ANDROID) prefix=goog_ ;;
  esac
  if [[ "$key" != "$prefix"* ]]; then
    if [[ -z "${!platform_var:-}" ]]; then
      die "REVENUECAT_API_KEY is not a $1 key (expected ${prefix}…); set $platform_var"
    fi
    die "$platform_var must start with ${prefix} (got ${key:0:5}…)"
  fi
  printf '%s' "$key"
}

common_defines() {
  local rc_key="$1"
  local defines=(
    --dart-define=ENVIRONMENT=prod
    "--dart-define=API_BASE_URL=$API_BASE_URL"
    "--dart-define=REVENUECAT_API_KEY=$rc_key"
  )
  printf '%s\n' "${defines[@]}"
}

build_android() {
  [[ -f android/key.properties ]] \
    || die "android/key.properties missing (see android/key.properties.example)"
  local rc_key; rc_key="$(rc_key_for ANDROID)"
  local defines=(); while IFS= read -r d; do defines+=("$d"); done < <(common_defines "$rc_key")
  echo "==> Building Android App Bundle"
  flutter build appbundle --release --obfuscate \
    --split-debug-info=build/debug-info/android "${defines[@]}"
}

build_ios() {
  [[ "$(uname)" == Darwin ]] || die "iOS builds require macOS"
  local rc_key; rc_key="$(rc_key_for IOS)"
  local defines=(); while IFS= read -r d; do defines+=("$d"); done < <(common_defines "$rc_key")
  echo "==> Building iOS IPA"
  flutter build ipa --release --obfuscate \
    --split-debug-info=build/debug-info/ios "${defines[@]}"
}

flutter pub get
[[ "$TARGET" == ios ]] || build_android
[[ "$TARGET" == android ]] || build_ios

echo
echo "Done. Artifacts:"
[[ "$TARGET" == ios ]] || echo "  build/app/outputs/bundle/release/app-release.aab"
[[ "$TARGET" == android ]] || echo "  build/ios/ipa/"
echo "Archive build/debug-info/ privately for crash symbolication."
