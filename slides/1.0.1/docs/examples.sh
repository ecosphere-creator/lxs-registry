#!/usr/bin/env bash
# slides LXS smoke test — golden request→response pairs.
# Usage: BASE_URL=<http://host:port/api> TOKEN=<jwt> ./examples.sh
# Runs against a pulled binary or a live estate URL; every curl must succeed
# and return the documented shape or the script exits non-zero.
#
# Only endpoints that need no state (health, public catalog) are required.
# If TOKEN is set, the authenticated create/fetch/delete round-trip also runs.
set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1:9015/api}"
TOKEN="${TOKEN:-}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# 1) health
code=$(curl -s -o "$tmp/health.out" -w '%{http_code}' "$BASE_URL/health")
test "$code" = "200"
grep -q '"status":"UP"' "$tmp/health.out"
echo "OK health -> 200 {\"status\":\"UP\"}"

# 2) public catalog (no auth) — must be a JSON array (possibly empty)
code=$(curl -s -o "$tmp/catalog.out" -w '%{http_code}' "$BASE_URL/book/catalog")
test "$code" = "200"
grep -q '^\[' "$tmp/catalog.out"
echo "OK GET /book/catalog -> 200 (JSON array)"

if [ -n "$TOKEN" ]; then
  AUTH=(-H "Authorization: Bearer $TOKEN")

  # 3) create a draft deck (POST /book -> 201, ownerId forced server-side)
  code=$(curl -s -o "$tmp/create.out" -w '%{http_code}' \
    "${AUTH[@]}" -H "Content-Type: application/json" \
    -d '{"name":"Smoke Deck","status":"draft"}' \
    "$BASE_URL/book")
  test "$code" = "201"
  deck_id=$(python3 -c "import json,sys;print(json.load(open('$tmp/create.out'))['id'])")
  test -n "$deck_id"
  echo "OK POST /book -> 201 (deck $deck_id)"

  # 4) fetch the created deck (GET /book/:id -> 200)
  code=$(curl -s -o "$tmp/get.out" -w '%{http_code}' \
    "${AUTH[@]}" "$BASE_URL/book/$deck_id")
  test "$code" = "200"
  echo "OK GET /book/:id -> 200"

  # 5) delete it (DELETE /book/:id -> 204)
  code=$(curl -s -o "$tmp/delete.out" -w '%{http_code}' \
    -X DELETE "${AUTH[@]}" "$BASE_URL/book/$deck_id")
  test "$code" = "204"
  echo "OK DELETE /book/:id -> 204"
else
  echo "SKIP authenticated round-trip (set TOKEN=... to run it)"
fi

echo "ALL SLIDES SMOKE TESTS PASSED"
