#!/usr/bin/env bash
# gateway LXS smoke test — run the binary locally against a small route table.
set -euo pipefail
PORT="${PORT:-8090}"
AUTH_PORT="${AUTH_PORT:-8091}"
SECRET="${SECRET:-test-secret-0123456789abcdef0123456789abcdef0123456789abcdef}"

cat > /tmp/gateway-test.json <<EOF
{
  "roles": { "public": "public", "authenticated": "auth" },
  "routes": [
    {"path": "/public", "upstream": "127.0.0.1:$AUTH_PORT", "level": "public"},
    {"path": "/private", "upstream": "127.0.0.1:$AUTH_PORT", "level": "auth"},
    {"path": "/api/auth/login", "upstream": "127.0.0.1:$AUTH_PORT", "level": "public"},
    {"path": "/api/auth/*", "upstream": "127.0.0.1:$AUTH_PORT", "level": "auth"}
  ]
}
EOF

echo "PORT=$PORT SECRET=$SECRET GATEWAY_CONFIG=/tmp/gateway-test.json"
echo "Run the gateway, then test:"
echo "  curl http://127.0.0.1:$PORT/public          # 200/404 (no route deny test: /nope -> 403)"
echo "  curl http://127.0.0.1:$PORT/private          # 401 (missing token)"
echo "  curl http://127.0.0.1:$PORT/nope             # 403 (deny by default)"
