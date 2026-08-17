#!/usr/bin/env bash
# notifications LXS smoke test — golden request→response pairs.
# Usage: BASE_URL=<http://host:port> JWT_SECRET=<estate secret> ./examples.sh
# Runs against a pulled binary or a live estate URL; every curl must succeed
# and return the documented shape or the script exits non-zero.
# All endpoints require a valid HS512 JWT; if JWT_SECRET is unset the script
# still verifies the unauthenticated probes (health + 401 on protected ones).
set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1:8090}"
JWT_SECRET="${JWT_SECRET:-}"

# Mint an HS512 JWT {sub,exp} like auth would. Requires openssl.
mint_token() {
  local secret="$1" sub="$2"
  local now exp hdr payload sig signing_input
  now=$(date +%s)
  exp=$((now + 3600))
  hdr=$(printf '%s' '{"alg":"HS512","typ":"JWT"}' | openssl base64 -A | tr '+/' '-_' | tr -d '=')
  payload=$(printf '{"sub":"%s","exp":%s}' "$sub" "$exp" | openssl base64 -A | tr '+/' '-_' | tr -d '=')
  signing_input="${hdr}.${payload}"
  sig=$(printf '%s' "$signing_input" | openssl dgst -sha512 -hmac "$secret" -binary | openssl base64 -A | tr '+/' '-_' | tr -d '=')
  echo "${signing_input}.${sig}"
}

# 1) health (both aliases)
code=$(curl -s -o /tmp/notifications-health.out -w '%{http_code}' "$BASE_URL/health")
test "$code" = "200"
grep -q '"OK"' /tmp/notifications-health.out
echo "OK health -> 200"

code=$(curl -s -o /tmp/notifications-health2.out -w '%{http_code}' "$BASE_URL/api/notifications/health")
test "$code" = "200"
grep -q '"OK"' /tmp/notifications-health2.out
echo "OK /api/notifications/health -> 200"

# 2) protected endpoints reject missing tokens
code=$(curl -s -o /tmp/notifications-unauth.out -w '%{http_code}' "$BASE_URL/api/notifications")
test "$code" = "401"
grep -q 'Bearer token' /tmp/notifications-unauth.out
echo "OK list without token -> 401"

code=$(curl -s -o /tmp/notifications-unauth2.out -w '%{http_code}' "$BASE_URL/api/notifications/unread-count")
test "$code" = "401"
echo "OK unread-count without token -> 401"

# 3) authenticated flows (only when a secret is provided)
if [[ -n "$JWT_SECRET" ]]; then
  TOKEN=$(mint_token "$JWT_SECRET" "smoke-test-user")

  code=$(curl -s -o /tmp/notifications-list.out -w '%{http_code}' "$BASE_URL/api/notifications" \
    -H "Authorization: Bearer $TOKEN")
  test "$code" = "200"
  echo "OK list -> 200"

  code=$(curl -s -o /tmp/notifications-unread.out -w '%{http_code}' "$BASE_URL/api/notifications/unread-count" \
    -H "Authorization: Bearer $TOKEN")
  test "$code" = "200"
  grep -q 'unread_count' /tmp/notifications-unread.out
  echo "OK unread-count -> 200"

  # ingest one notification to this user
  code=$(curl -s -o /tmp/notifications-ingest.out -w '%{http_code}' "$BASE_URL/api/notifications/ingest" \
    -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
    -d "{\"recipient_ids\":[\"smoke-test-user\"],\"kind\":\"smoke\",\"title\":\"Smoke test\",\"body\":\"hello\"}")
  test "$code" = "200"
  grep -q '"notified":1' /tmp/notifications-ingest.out
  echo "OK ingest -> 200 (notified:1)"

  # mark one read: pull the id from the list response, then post it
  code=$(curl -s -o /tmp/notifications-list2.out -w '%{http_code}' "$BASE_URL/api/notifications" \
    -H "Authorization: Bearer $TOKEN")
  test "$code" = "200"
  NID=$(grep -o '"id":"[0-9a-f]*"' /tmp/notifications-list2.out | head -1 | sed 's/"id":"//;s/"//')
  test -n "$NID"
  code=$(curl -s -o /tmp/notifications-read.out -w '%{http_code}' "$BASE_URL/api/notifications/$NID/read" \
    -X POST -H "Authorization: Bearer $TOKEN")
  test "$code" = "200"
  grep -q '"ok":true' /tmp/notifications-read.out
  echo "OK mark-one-read -> 200"

  code=$(curl -s -o /tmp/notifications-readall.out -w '%{http_code}' "$BASE_URL/api/notifications/read-all" \
    -X POST -H "Authorization: Bearer $TOKEN")
  test "$code" = "200"
  grep -q '"ok":true' /tmp/notifications-readall.out
  echo "OK read-all -> 200"

  # websocket endpoint without upgrade headers must be rejected (not 200)
  code=$(curl -s -o /tmp/notifications-ws.out -w '%{http_code}' "$BASE_URL/api/notifications/ws?token=$TOKEN")
  test "$code" != "200"
  echo "OK ws without upgrade headers rejected -> $code"
else
  echo "SKIP authenticated checks (set JWT_SECRET)"
fi

echo "ALL OK"
