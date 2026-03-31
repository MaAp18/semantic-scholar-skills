#!/usr/bin/env bash
# get-citations.sh — Get citing papers (incoming citations) or references (outgoing) for a paper.
# Reads API key from $SEMANTIC_SCHOLAR_API_KEY (optional; rate-limited without one).
# Supports pagination for large citation sets.
# Outputs clean JSON to stdout.

set -euo pipefail

GRAPH_API="https://api.semanticscholar.org/graph/v1"
DEFAULT_FIELDS="isInfluential,contexts,citingPaper.paperId,citingPaper.title,citingPaper.year,citingPaper.authors,citingPaper.citationCount"
DEFAULT_REF_FIELDS="isInfluential,contexts,citedPaper.paperId,citedPaper.title,citedPaper.year,citedPaper.authors,citedPaper.citationCount"
DEFAULT_LIMIT=100

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <paper_id>

Get citations for a paper. By default, returns incoming citations (papers that cite this one).

<paper_id> can be any supported ID type:
  <sha>              40-char Semantic Scholar ID
  CorpusId:<id>      Corpus ID
  DOI:<doi>          e.g. DOI:10.18653/v1/N18-3011
  ARXIV:<id>         e.g. ARXIV:1706.03762
  PMID:<id>, PMCID:<id>, MAG:<id>, ACL:<id>, URL:<url>

OPTIONS:
  --references        Return outgoing references instead of incoming citations
  --fields <fields>   Comma-separated edge+paper fields to return
                      (citation default:  $DEFAULT_FIELDS)
                      (reference default: $DEFAULT_REF_FIELDS)
  --limit <n>         Results per page (default: $DEFAULT_LIMIT, max: 1000)
  --offset <n>        Pagination offset (default: 0)
  --all               Fetch ALL pages automatically (outputs JSON array)
  --pub-date <range>  Filter by publication date range (citations only)
                      e.g. "2020:2024", "2022:", ":2023-06"
  -h, --help          Show this help

ENVIRONMENT:
  SEMANTIC_SCHOLAR_API_KEY  API key for higher rate limits (optional)

EXAMPLES:
  $(basename "$0") "ARXIV:1706.03762"
  $(basename "$0") --references "ARXIV:1706.03762"
  $(basename "$0") --all --limit 1000 "649def34f8be52c8b66281af98ae884c09aef38b"
  $(basename "$0") --pub-date "2022:" "DOI:10.18653/v1/N18-3011"
EOF
  exit 0
}

PAPER_ID=""
MODE="citations"   # or "references"
FIELDS=""
LIMIT="$DEFAULT_LIMIT"
OFFSET=0
FETCH_ALL=false
PUB_DATE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage ;;
    --references) MODE="references"; shift ;;
    --fields) FIELDS="$2"; shift 2 ;;
    --limit) LIMIT="$2"; shift 2 ;;
    --offset) OFFSET="$2"; shift 2 ;;
    --all) FETCH_ALL=true; shift ;;
    --pub-date) PUB_DATE="$2"; shift 2 ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *) PAPER_ID="$1"; shift ;;
  esac
done

if [[ -z "$PAPER_ID" ]]; then
  echo "Error: paper_id is required." >&2
  echo "Run '$(basename "$0") --help' for usage." >&2
  exit 1
fi

# Set default fields based on mode
if [[ -z "$FIELDS" ]]; then
  if [[ "$MODE" == "citations" ]]; then
    FIELDS="$DEFAULT_FIELDS"
  else
    FIELDS="$DEFAULT_REF_FIELDS"
  fi
fi

# URL-encode helper
urlencode() {
  python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$1" 2>/dev/null \
    || printf '%s' "$1" | sed 's/ /%20/g; s/:/%3A/g'
}

ENCODED_ID=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$PAPER_ID" 2>/dev/null || printf '%s' "$PAPER_ID")

# Build auth header
AUTH_HEADER=""
if [[ -n "${SEMANTIC_SCHOLAR_API_KEY:-}" ]]; then
  AUTH_HEADER="x-api-key: ${SEMANTIC_SCHOLAR_API_KEY}"
fi

curl_get() {
  local url="$1"
  if [[ -n "$AUTH_HEADER" ]]; then
    curl -sf -H "$AUTH_HEADER" "$url"
  else
    curl -sf "$url"
  fi
}

BASE_URL="${GRAPH_API}/paper/${ENCODED_ID}/${MODE}?fields=${FIELDS}&limit=${LIMIT}"
[[ "$MODE" == "citations" && -n "$PUB_DATE" ]] && BASE_URL="${BASE_URL}&publicationDateOrYear=$(urlencode "$PUB_DATE")"

if [[ "$FETCH_ALL" == "true" ]]; then
  # Fetch all pages and combine into a JSON array
  ALL_DATA="[]"
  CURRENT_OFFSET=0
  TOTAL_FETCHED=0

  while true; do
    URL="${BASE_URL}&offset=${CURRENT_OFFSET}"
    RESPONSE=$(curl_get "$URL")
    PAGE_DATA=$(echo "$RESPONSE" | python3 -c "import json, sys; d=json.load(sys.stdin); print(json.dumps(d.get('data', [])))")
    PAGE_COUNT=$(echo "$PAGE_DATA" | python3 -c "import json, sys; print(len(json.load(sys.stdin)))")

    if [[ "$PAGE_COUNT" -eq 0 ]]; then
      break
    fi

    ALL_DATA=$(python3 -c "
import json, sys
existing = json.loads(sys.argv[1])
new = json.loads(sys.argv[2])
existing.extend(new)
print(json.dumps(existing))
" "$ALL_DATA" "$PAGE_DATA")

    TOTAL_FETCHED=$((TOTAL_FETCHED + PAGE_COUNT))
    NEXT=$(echo "$RESPONSE" | python3 -c "import json, sys; d=json.load(sys.stdin); print(d.get('next', ''))" 2>/dev/null || echo "")

    if [[ -z "$NEXT" ]]; then
      break
    fi
    CURRENT_OFFSET="$NEXT"
  done

  echo "$ALL_DATA"
else
  URL="${BASE_URL}&offset=${OFFSET}"
  curl_get "$URL"
fi
