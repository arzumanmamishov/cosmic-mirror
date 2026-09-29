#!/usr/bin/env bash
# Build store-ready release artifacts (Google Play .aab + App Store .ipa).
# Builds only — nothing is uploaded.
#
# Usage:
#   REVENUECAT_API_KEY=... STRIPE_PUBLISHABLE_KEY=pk_live_... \
#     scripts/build_release.sh [android|ios|all]      (default: all)
#
# Env vars:
#   REVENUECAT_API_KEY          required  RevenueCat public SDK key (per platform
#                                         keys: REVENUECAT_API_KEY_ANDROID /
#                                         REVENUECAT_API_KEY_IOS override it)
#   STRIPE_PUBLISHABLE_KEY      required  Stripe publishable key (pk_live_…)
#   STRIPE_MERCHANT_IDENTIFIER  optional  Apple Pay merchant id
#   API_BASE_URL                optional  default https://api.livelyapp.co
#   ALLOW_TEST_STRIPE_KEY=1     optional  permit a pk_test_ key
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
STRIPE_MERCHANT_IDENTIFIER="${STRIPE_MERCHANT_IDENTIFIER:-}"

die() { echo "error: $*" >&2; exit 1; }

[[ -n "${STRIPE_PUBLISHABLE_KEY:-}" ]] || die "STRIPE_PUBLISHABLE_KEY is not set"
if [[ "$STRIPE_PUBLISHABLE_KEY" == pk_test_* && "${ALLOW_TEST_STRIPE_KEY:-}" != 1 ]]; then
  die "STRIPE_PUBLISHABLE_KEY is a test key (set ALLOW_TEST_STRIPE_KEY=1 to allow)"
fi
[[ "$API_BASE_URL" == https://* ]] || die "API_BASE_URL must be https:// (got $API_BASE_URL)"

rc_key_for() {
  local platform_var="REVENUECAT_API_KEY_$1"
  local key="${!platform_var:-${REVENUECAT_API_KEY:-}}"
  [[ -n "$key" && "$key" != "your_revenuecat_api_key" ]] \
    || die "REVENUECAT_API_KEY (or $platform_var) is not set"
  printf '%s' "$key"
}

common_defines() {
  local rc_key="$1"
  local defines=(
    --dart-define=ENVIRONMENT=prod
    "--dart-define=API_BASE_URL=$API_BASE_URL"
    "--dart-define=REVENUECAT_API_KEY=$rc_key"
    "--dart-define=STRIPE_PUBLISHABLE_KEY=$STRIPE_PUBLISHABLE_KEY"
  )
  if [[ -n "$STRIPE_MERCHANT_IDENTIFIER" ]]; then
    defines+=("--dart-define=STRIPE_MERCHANT_IDENTIFIER=$STRIPE_MERCHANT_IDENTIFIER")
  fi
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
