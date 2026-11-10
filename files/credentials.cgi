#!/bin/bash
# Look up one team in the lab credentials file and print its cluster, user, and password.
set -u

CREDENTIALS_FILE="${CREDENTIALS_FILE:-/var/www/credentials/credentials.yaml}"

html_escape() {
  sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g'
}

read_request_body() {
  if [[ "${REQUEST_METHOD:-}" == "POST" && "${CONTENT_LENGTH:-0}" =~ ^[0-9]+$ && "${CONTENT_LENGTH:-0}" -gt 0 && "${CONTENT_LENGTH:-0}" -le 200 ]]; then
    IFS= read -r -n "$CONTENT_LENGTH" body || true
    printf '%s' "$body"
    return
  fi
  printf '%s' "${QUERY_STRING:-}"
}

field_value() {
  local key="$1" line value
  line=$(grep -F "team.credentials.team${TEAM}.${key}:" "$CREDENTIALS_FILE" | head -n 1 || true)
  value=${line#*:}
  value=$(printf '%s' "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
  printf '%s' "$value"
}

page_start() {
  local status="$1"
  printf 'Status: %s\r\n' "$status"
  printf 'Content-Type: text/html; charset=utf-8\r\n'
  printf 'Cache-Control: no-store\r\n'
  printf '\r\n'
  cat <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Team credentials</title>
</head>
<body>
<h1>Team credentials</h1>
<p>Enter the team number you were given.</p>
<form method="post" action="/cgi-bin/credentials.cgi">
  <label for="team">Team number</label>
  <input id="team" name="team" inputmode="numeric" pattern="[0-9]+" autocomplete="off" required>
  <button type="submit">Show credentials</button>
</form>
EOF
}

page_end() {
  printf '</body>\n</html>\n'
}

payload=$(read_request_body)
raw=$(printf '%s' "$payload" | tr '&' '\n' | sed -n 's/^team=//p' | head -n 1)
raw=${raw//+/ }

if [[ -z "$raw" ]]; then
  page_start "200 OK"
  page_end
  exit 0
fi

if [[ ! "$raw" =~ ^[0-9]{1,4}$ ]]; then
  page_start "400 Bad Request"
  printf '<p>Enter a team number.</p>\n'
  page_end
  exit 0
fi

TEAM=$(printf '%02d' "$((10#$raw))")
if [[ "$TEAM" == "00" ]]; then
  page_start "400 Bad Request"
  printf '<p>Enter a team number.</p>\n'
  page_end
  exit 0
fi

if [[ ! -r "$CREDENTIALS_FILE" ]]; then
  page_start "500 Internal Server Error"
  printf '<p>The credentials file is not available.</p>\n'
  page_end
  exit 0
fi

cid=$(field_value cid)
uid=$(field_value uid)
password=$(field_value password)

page_start "200 OK"
if [[ -z "$cid" || -z "$uid" || -z "$password" ]]; then
  printf '<p>No complete credentials are stored for team %s.</p>\n' "$(printf '%s' "$TEAM" | html_escape)"
  page_end
  exit 0
fi

printf '<h2>Team %s</h2>\n' "$(printf '%s' "$TEAM" | html_escape)"
printf '<dl>\n'
printf '<dt>Cluster ID</dt><dd><code>%s</code></dd>\n' "$(printf '%s' "$cid" | html_escape)"
printf '<dt>User ID</dt><dd><code>%s</code></dd>\n' "$(printf '%s' "$uid" | html_escape)"
printf '<dt>Password</dt><dd><code>%s</code></dd>\n' "$(printf '%s' "$password" | html_escape)"
printf '</dl>\n'
page_end
