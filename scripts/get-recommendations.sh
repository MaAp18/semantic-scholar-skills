#!/usr/bin/env bash
# get-recommendations.sh — Get paper recommendations from Semantic Scholar.
# Reads API key from $SEMANTIC_SCHOLAR_API_KEY (optional; rate-limited without one).
# Outputs clean JSON to stdout.

set -euo pipefail

RECOMMENDATIONS_API="https://api.semanticscholar.org/recommendations/v1"
DEFAULT_FIELDS="paperId,title,abstract,year,authors,citationCount,isOpenAccess"
DEFAULT_LIMIT=10

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <paper_id>
   or: $(basename "$0") [OPTIONS] --positive <id1,id2,...> [--negative <id3,id4,...>]

Get paper recommendations from Semantic Scholar.

Single-seed mode: provide one <paper_id> (40-char SHA only for this endpoint)
Multi-seed mode:  provide --positive and optionally --negative paper ID lists

OPTIONS:
  --positive <ids>    Comma-separated positive seed paper IDs (multi-seed mode)
  --negative <ids>    Comma-separated negative example paper IDs (optional)
  --fields <fields>   Comma-separated paper fields to return
                      (default: $DEFAULT_FIELDS)
  --limit <n>         Number of recommendations (default: $DEFAULT_LIMIT, max: 500)
  --from <pool>       Recommendation pool for single-seed mode (default: recent)
                      Values: recent | all-cs
  -h, --help          Show this help

ENVIRONMENT:
  SEMANTIC_SCHOLAR_API_KEY  API key for higher rate limits (optional)

NOTES:
  - Single-seed mode requires the 40-character Semantic Scholar SHA paper ID.
  - Multi-seed mode uses POST /papers/ with JSON body.
  - No pagination; increase --limit to get more results (max 500).

EXAMPLES:
  $(basename "$0") 649def34f8be52c8b66281af98ae884c09aef38b
  $(basename "$0") --limit 20 --from all-cs "649def34f8be52c8b66281af98ae884c09aef38b"
  $(basename "$0") --positive "paperId1,paperId2" --negative "paperId3"
  $(basename "$0") --positive "paperId1,paperId2" --limit 50 --fields "paperId,title,year"
EOF
  exit 0
}

PAPER_ID=""
POSITIVE_IDS=""
NEGATIVE_IDS=""
FIELDS="$DEFAULT_FIELDS"
LIMIT="$DEFAULT_LIMIT"
FROM="recent"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage ;;
    --positive) POSITIVE_IDS="$2"; shift 2 ;;
    --negative) NEGATIVE_IDS="$2"; shift 2 ;;
    --fields) FIELDS="$2"; shift 2 ;;
    --limit) LIMIT="$2"; shift 2 ;;
    --from) FROM="$2"; shift 2 ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *) PAPER_ID="$1"; shift ;;
  esac
done

# Build auth header
AUTH_HEADER=""
if [[ -n "${SEMANTIC_SCHOLAR_API_KEY:-}" ]]; then
  AUTH_HEADER="x-api-key: ${SEMANTIC_SCHOLAR_API_KEY}"
fi

curl_get() {
  local url="$1"
  local tmpfile
  tmpfile=$(mktemp)
  local args=(-s -o "$tmpfile" -w '%{http_code}')
  [[ -n "$AUTH_HEADER" ]] && args+=(-H "$AUTH_HEADER")
  local http_code exit_status=0
  http_code=$(curl "${args[@]}" "$url")
  if [[ "$http_code" -lt 200 || "$http_code" -ge 300 ]]; then
    echo "Error: API request failed (HTTP ${http_code})" >&2
    exit_status=1
  else
    cat "$tmpfile"
  fi
  rm -f "$tmpfile"
  return "$exit_status"
}

curl_post() {
  local url="$1"
  local body="$2"
  local tmpfile
  tmpfile=$(mktemp)
  local args=(-s -o "$tmpfile" -w '%{http_code}' -H "Content-Type: application/json" -d "$body")
  [[ -n "$AUTH_HEADER" ]] && args+=(-H "$AUTH_HEADER")
  local http_code exit_status=0
  http_code=$(curl "${args[@]}" "$url")
  if [[ "$http_code" -lt 200 || "$http_code" -ge 300 ]]; then
    echo "Error: API request failed (HTTP ${http_code})" >&2
    exit_status=1
  else
    cat "$tmpfile"
  fi
  rm -f "$tmpfile"
  return "$exit_status"
}

# Multi-seed mode
if [[ -n "$POSITIVE_IDS" ]]; then
  # Convert comma-separated IDs to JSON arrays
  POSITIVE_JSON=$(python3 -c "
import json, sys
ids = [i.strip() for i in sys.argv[1].split(',') if i.strip()]
print(json.dumps(ids))
" "$POSITIVE_IDS")

  if [[ -n "$NEGATIVE_IDS" ]]; then
    NEGATIVE_JSON=$(python3 -c "
import json, sys
ids = [i.strip() for i in sys.argv[1].split(',') if i.strip()]
print(json.dumps(ids))
" "$NEGATIVE_IDS")
  else
    NEGATIVE_JSON="[]"
  fi

  BODY=$(python3 -c "
import json, sys
body = {
    'positivePaperIds': json.loads(sys.argv[1]),
    'negativePaperIds': json.loads(sys.argv[2]),
}
print(json.dumps(body))
" "$POSITIVE_JSON" "$NEGATIVE_JSON")

  URL="${RECOMMENDATIONS_API}/papers/?fields=${FIELDS}&limit=${LIMIT}"
  curl_post "$URL" "$BODY"
  exit 0
fi

# Single-seed mode
if [[ -z "$PAPER_ID" ]]; then
  echo "Error: paper_id is required (or use --positive for multi-seed mode)." >&2
  echo "Run '$(basename "$0") --help' for usage." >&2
  exit 1
fi

URL="${RECOMMENDATIONS_API}/papers/forpaper/${PAPER_ID}?fields=${FIELDS}&limit=${LIMIT}&from=${FROM}"
curl_get "$URL"
