#!/usr/bin/env bash
# search-papers.sh — Search Semantic Scholar papers by query with optional filters.
# Reads API key from $SEMANTIC_SCHOLAR_API_KEY (optional; rate-limited without one).
# Outputs clean JSON to stdout.

set -euo pipefail

GRAPH_API="https://api.semanticscholar.org/graph/v1"
DEFAULT_FIELDS="paperId,title,abstract,year,authors,citationCount,isOpenAccess,openAccessPdf"
DEFAULT_LIMIT=10

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <query>

Search Semantic Scholar papers by query string.

OPTIONS:
  --fields <f>        Comma-separated fields to return (default: $DEFAULT_FIELDS)
  --limit <n>         Results per page (default: $DEFAULT_LIMIT, max: 100)
  --offset <n>        Pagination offset (default: 0, max: 9900)
  --year <range>      Year or year range, e.g. "2020", "2018:2023", "2020:"
  --pub-types <types> Comma-separated publication types, e.g. "JournalArticle,Conference"
  --fields-of-study <f> Comma-separated academic fields, e.g. "Computer Science,Biology"
  --min-citations <n> Minimum citation count
  --open-access       Filter to open-access papers only
  --venue <venues>    Comma-separated venue names
  --bulk              Use bulk (cursor-based) search instead of relevance search
  --sort <field:order> Sort for bulk search (e.g. "citationCount:desc")
  --token <cursor>    Continuation token for bulk search pagination
  -h, --help          Show this help

ENVIRONMENT:
  SEMANTIC_SCHOLAR_API_KEY  API key for higher rate limits (optional)

EXAMPLES:
  $(basename "$0") "attention is all you need"
  $(basename "$0") --limit 5 --year "2020:2024" "transformer architecture"
  $(basename "$0") --fields-of-study "Computer Science" --min-citations 100 "neural networks"
  $(basename "$0") --bulk --sort "citationCount:desc" --limit 50 "BERT"
EOF
  exit 0
}

# Defaults
QUERY=""
FIELDS="$DEFAULT_FIELDS"
LIMIT="$DEFAULT_LIMIT"
OFFSET=0
YEAR=""
PUB_TYPES=""
FIELDS_OF_STUDY=""
MIN_CITATIONS=""
OPEN_ACCESS=false
VENUE=""
BULK=false
SORT="paperId:asc"
TOKEN=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage ;;
    --fields) FIELDS="$2"; shift 2 ;;
    --limit) LIMIT="$2"; shift 2 ;;
    --offset) OFFSET="$2"; shift 2 ;;
    --year) YEAR="$2"; shift 2 ;;
    --pub-types) PUB_TYPES="$2"; shift 2 ;;
    --fields-of-study) FIELDS_OF_STUDY="$2"; shift 2 ;;
    --min-citations) MIN_CITATIONS="$2"; shift 2 ;;
    --open-access) OPEN_ACCESS=true; shift ;;
    --venue) VENUE="$2"; shift 2 ;;
    --bulk) BULK=true; shift ;;
    --sort) SORT="$2"; shift 2 ;;
    --token) TOKEN="$2"; shift 2 ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *) QUERY="$1"; shift ;;
  esac
done

if [[ -z "$QUERY" ]]; then
  echo "Error: query is required." >&2
  echo "Run '$(basename "$0") --help' for usage." >&2
  exit 1
fi

# URL-encode helper (using Python if available, otherwise basic sed)
urlencode() {
  python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$1" 2>/dev/null \
    || printf '%s' "$1" | sed 's/ /%20/g; s/&/%26/g; s/+/%2B/g; s/:/%3A/g; s/"/%22/g'
}

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

ENCODED_QUERY=$(urlencode "$QUERY")

if [[ "$BULK" == "true" ]]; then
  ENDPOINT="${GRAPH_API}/paper/search/bulk"
  URL="${ENDPOINT}?query=${ENCODED_QUERY}&fields=${FIELDS}&sort=${SORT}&limit=${LIMIT}"
  [[ -n "$YEAR" ]] && URL="${URL}&year=$(urlencode "$YEAR")"
  [[ -n "$PUB_TYPES" ]] && URL="${URL}&publicationTypes=$(urlencode "$PUB_TYPES")"
  [[ -n "$FIELDS_OF_STUDY" ]] && URL="${URL}&fieldsOfStudy=$(urlencode "$FIELDS_OF_STUDY")"
  [[ -n "$MIN_CITATIONS" ]] && URL="${URL}&minCitationCount=${MIN_CITATIONS}"
  [[ "$OPEN_ACCESS" == "true" ]] && URL="${URL}&openAccessPdf"
  [[ -n "$VENUE" ]] && URL="${URL}&venue=$(urlencode "$VENUE")"
  [[ -n "$TOKEN" ]] && URL="${URL}&token=$(urlencode "$TOKEN")"
else
  ENDPOINT="${GRAPH_API}/paper/search"
  URL="${ENDPOINT}?query=${ENCODED_QUERY}&fields=${FIELDS}&limit=${LIMIT}&offset=${OFFSET}"
  [[ -n "$YEAR" ]] && URL="${URL}&year=$(urlencode "$YEAR")"
  [[ -n "$PUB_TYPES" ]] && URL="${URL}&publicationTypes=$(urlencode "$PUB_TYPES")"
  [[ -n "$FIELDS_OF_STUDY" ]] && URL="${URL}&fieldsOfStudy=$(urlencode "$FIELDS_OF_STUDY")"
  [[ -n "$MIN_CITATIONS" ]] && URL="${URL}&minCitationCount=${MIN_CITATIONS}"
  [[ "$OPEN_ACCESS" == "true" ]] && URL="${URL}&openAccessPdf"
  [[ -n "$VENUE" ]] && URL="${URL}&venue=$(urlencode "$VENUE")"
fi

curl_get "$URL"
