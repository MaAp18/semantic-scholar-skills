#!/usr/bin/env bash
# search-authors.sh — Find authors by name on Semantic Scholar.
# Reads API key from $SEMANTIC_SCHOLAR_API_KEY (optional; rate-limited without one).
# Outputs clean JSON to stdout.

set -euo pipefail

GRAPH_API="https://api.semanticscholar.org/graph/v1"
DEFAULT_FIELDS="authorId,name,affiliations,homepage,paperCount,citationCount,hIndex"
DEFAULT_LIMIT=10

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <name>

Search Semantic Scholar for authors by name.

OPTIONS:
  --fields <fields> Comma-separated author fields to return
                    (default: $DEFAULT_FIELDS)
  --limit <n>       Results per page (default: $DEFAULT_LIMIT, max: 1000)
  --offset <n>      Pagination offset (default: 0)
  --papers          Also include author's papers in the response (adds papers field)
  --paper-fields <f> Comma-separated paper fields to include when --papers is set
                    (default: paperId,title,year,citationCount)
  --get <author_id> Instead of searching, fetch a specific author by ID
  --author-papers <author_id>
                    List all papers by a specific author ID
  --pub-date <range> Filter author's papers by date (e.g. "2020:2024")
  -h, --help        Show this help

ENVIRONMENT:
  SEMANTIC_SCHOLAR_API_KEY  API key for higher rate limits (optional)

EXAMPLES:
  $(basename "$0") "Yoshua Bengio"
  $(basename "$0") --limit 5 "Geoffrey Hinton"
  $(basename "$0") --papers --paper-fields "paperId,title,year" "Yann LeCun"
  $(basename "$0") --get 1741101
  $(basename "$0") --author-papers 1741101 --pub-date "2018:2024"
EOF
  exit 0
}

QUERY=""
FIELDS="$DEFAULT_FIELDS"
LIMIT="$DEFAULT_LIMIT"
OFFSET=0
INCLUDE_PAPERS=false
PAPER_FIELDS="paperId,title,year,citationCount"
GET_AUTHOR_ID=""
AUTHOR_PAPERS_ID=""
PUB_DATE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage ;;
    --fields) FIELDS="$2"; shift 2 ;;
    --limit) LIMIT="$2"; shift 2 ;;
    --offset) OFFSET="$2"; shift 2 ;;
    --papers) INCLUDE_PAPERS=true; shift ;;
    --paper-fields) PAPER_FIELDS="$2"; shift 2 ;;
    --get) GET_AUTHOR_ID="$2"; shift 2 ;;
    --author-papers) AUTHOR_PAPERS_ID="$2"; shift 2 ;;
    --pub-date) PUB_DATE="$2"; shift 2 ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *) QUERY="$1"; shift ;;
  esac
done

# URL-encode helper
urlencode() {
  python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$1" 2>/dev/null \
    || printf '%s' "$1" | sed 's/ /%20/g'
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

# --get: fetch a specific author profile
if [[ -n "$GET_AUTHOR_ID" ]]; then
  EXTRA_FIELDS="$FIELDS"
  if [[ "$INCLUDE_PAPERS" == "true" ]]; then
    EXTRA_FIELDS="${EXTRA_FIELDS},papers"
    URL="${GRAPH_API}/author/${GET_AUTHOR_ID}?fields=${EXTRA_FIELDS}"
  else
    URL="${GRAPH_API}/author/${GET_AUTHOR_ID}?fields=${EXTRA_FIELDS}"
  fi
  curl_get "$URL"
  exit 0
fi

# --author-papers: list papers by a specific author
if [[ -n "$AUTHOR_PAPERS_ID" ]]; then
  URL="${GRAPH_API}/author/${AUTHOR_PAPERS_ID}/papers?fields=${PAPER_FIELDS}&limit=${LIMIT}&offset=${OFFSET}"
  [[ -n "$PUB_DATE" ]] && URL="${URL}&publicationDateOrYear=$(urlencode "$PUB_DATE")"
  curl_get "$URL"
  exit 0
fi

# Search by name
if [[ -z "$QUERY" ]]; then
  echo "Error: name query is required." >&2
  echo "Run '$(basename "$0") --help' for usage." >&2
  exit 1
fi

SEARCH_FIELDS="$FIELDS"
if [[ "$INCLUDE_PAPERS" == "true" ]]; then
  SEARCH_FIELDS="${SEARCH_FIELDS},papers"
fi

ENCODED_QUERY=$(urlencode "$QUERY")
URL="${GRAPH_API}/author/search?query=${ENCODED_QUERY}&fields=${SEARCH_FIELDS}&limit=${LIMIT}&offset=${OFFSET}"
curl_get "$URL"
