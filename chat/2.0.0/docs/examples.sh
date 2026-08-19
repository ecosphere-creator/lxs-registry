#!/usr/bin/env bash
# chat LXS smoke test — golden request->response pairs.
# Usage: BASE_URL=<http://host:port> JWT_SECRET=<secret> ./examples.sh
# Runs against a pulled binary or a live estate URL; every curl must succeed
# and return the documented shape or the script exits non-zero.
set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1:26377}"
JWT_SECRET="${JWT_SECRET:-testsecret}"
USER_ID="${USER_ID:-smoke-test-user}"

b64url() { base64 | tr '+/' '-_' | tr -d '=\n'; }

mint_jwt() { # $1=sub, $2=secret -> HS512 JWT
  local header payload sig
  header=$(printf '{"alg":"HS512","typ":"JWT"}' | b64url)
  payload=$(printf '{"sub":"%s","exp":%s}' "$1" "$(( $(date +%s) + 3600 ))" | b64url)
  sig=$(printf '%s.%s' "$header" "$payload" | openssl dgst -sha512 -hmac "$2" -binary | b64url)
  printf '%s.%s.%s' "$header" "$payload" "$sig"
}

TOKEN=$(mint_jwt "$USER_ID" "$JWT_SECRET")
AUTH="Authorization: Bearer $TOKEN"

echo "BASE_URL=$BASE_URL"

# 1) health (bare and gateway-alias)
for path in /health /api/chat/health; do
  code=$(curl -s -o /tmp/chat-health.out -w '%{http_code}' "$BASE_URL$path")
  test "$code" = "200"
  rg -q "OK - persistent chat domain" /tmp/chat-health.out
  echo "OK $path -> 200 text"
done

# 2) stickers catalog
code=$(curl -s -o /tmp/chat-stickers.out -w '%{http_code}' "$BASE_URL/api/chat/stickers")
test "$code" = "200"
rg -q '"politik-indonesia"' /tmp/chat-stickers.out
rg -q '"internet-klasik"' /tmp/chat-stickers.out
echo "OK GET /api/chat/stickers -> 200"

# 3) sticker sheet for a compiled pack (200, image/webp) and a missing one (404)
code=$(curl -s -o /tmp/chat-sheet.webp -w '%{http_code}' "$BASE_URL/api/chat/stickers/politik-indonesia.webp")
test "$code" = "200"
code=$(curl -s -o /tmp/chat-sheet-missing.out -w '%{http_code}' "$BASE_URL/api/chat/stickers/emoji-reaksi.webp")
test "$code" = "404"
echo "OK sticker sheet 200 + 404"

# 4) create conversation (creator must be a participant -> include USER_ID)
code=$(curl -s -o /tmp/chat-conv.out -w '%{http_code}' -X POST "$BASE_URL/api/chat/conversations" \
  -H "$AUTH" -H 'Content-Type: application/json' \
  -d "{\"participant_ids\":[\"$USER_ID\",\"smoke-other\"],\"kind\":\"direct\",\"context\":{\"domain\":\"marketplace\",\"reference_id\":\"smoke-item-1\"}}")
test "$code" = "201"
CONV_ID=$(rg -o '"conversation_id":"[^"]+"' /tmp/chat-conv.out | head -1 | cut -d'"' -f4)
test -n "$CONV_ID"
echo "OK POST /api/chat/conversations -> 201 ($CONV_ID)"

# 5) list conversations (auth required -> 401 without token)
code=$(curl -s -o /tmp/chat-conv-list.out -w '%{http_code}' "$BASE_URL/api/chat/conversations" -H "$AUTH")
test "$code" = "200"
code=$(curl -s -o /tmp/chat-noauth.out -w '%{http_code}' "$BASE_URL/api/chat/conversations")
test "$code" = "401"
echo "OK GET /api/chat/conversations 200 (and 401 without token)"

# 6) send + list a message
code=$(curl -s -o /tmp/chat-msg.out -w '%{http_code}' -X POST "$BASE_URL/api/chat/conversations/$CONV_ID/messages" \
  -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"body":"smoke test message"}')
test "$code" = "201"
MSG_ID=$(rg -o '"message_id":"[^"]+"' /tmp/chat-msg.out | head -1 | cut -d'"' -f4)
test -n "$MSG_ID"
code=$(curl -s -o /tmp/chat-msg-list.out -w '%{http_code}' "$BASE_URL/api/chat/conversations/$CONV_ID/messages?limit=5" -H "$AUTH")
test "$code" = "200"
rg -q "$MSG_ID" /tmp/chat-msg-list.out
echo "OK POST + GET messages -> 201 / 200"

# 7) non-participant gets 403 (foreign user's token)
TOKEN_FOREIGN=$(mint_jwt "smoke-eavesdropper" "$JWT_SECRET")
code=$(curl -s -o /tmp/chat-forbidden.out -w '%{http_code}' \
  "$BASE_URL/api/chat/conversations/$CONV_ID/messages" -H "Authorization: Bearer $TOKEN_FOREIGN")
test "$code" = "403"
rg -q 'participants may access' /tmp/chat-forbidden.out
echo "OK non-participant -> 403"

# 8) bad token -> 401
code=$(curl -s -o /tmp/chat-badtoken.out -w '%{http_code}' \
  "$BASE_URL/api/chat/conversations/$CONV_ID/messages" -H 'Authorization: Bearer not.a.jwt')
test "$code" = "401"
echo "OK bad token -> 401"

echo "chat LXS smoke test PASSED"
