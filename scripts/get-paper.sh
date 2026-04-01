#!/usr/bin/env bash
# get-paper.sh — Fetch a paper by any Semantic Scholar-supported ID type.
# Reads API key from $SEMANTIC_SCHOLAR_API_KEY (optional; rate-limited without one).
# Outputs clean JSON to stdout.

set -euo pipefail

GRAPH_API="https://api.semanticscholar.org/graph/v1"
DEFAULT_FIELDS="paperId,title,abstract,year,authors,venue,citationCount,referenceCount,isOpenAccess,openAccessPdf,fieldsOfStudy,publicationDate,externalIds"

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <paper_id>

Fetch a paper by any supported ID type. Supported formats:
  <sha>             40-character Semantic Scholar ID (default)
  CorpusId:<id>     Corpus integer ID
  DOI:<doi>         Digital Object Identifier
  ARXIV:<id>        arXiv ID (e.g. ARXIV:2303.08774)
  MAG:<id>          Microsoft Academic Graph ID
  ACL:<id>          ACL Anthology ID
  PMID:<id>         PubMed ID
  PMCID:<id>        PubMed Central ID
  URL:<url>         Paper URL

OPTIONS:
  --fields <fields> Comma-separated fields to return
                    (default: $DEFAULT_FIELDS)
  --batch <file>    Batch mode: read IDs from file (one per line), max 500
  -h, --help        Show this help

ENVIRONMENT:
  SEMANTIC_SCHOLAR_API_KEY  API key for higher rate limits (optional)

EXAMPLES:
  $(basename "$0") 649def34f8be52c8b66281af98ae884c09aef38b
  $(basename "$0") "ARXIV:2303.08774"
  $(basename "$0") "DOI:10.18653/v1/N18-3011"
  $(basename "$0") --fields "paperId,title,tldr" "ARXIV:1706.03762"
  $(basename "$0") --batch ids.txt
EOF
  exit 0
}

PAPER_ID=""
FIELDS="$DEFAULT_FIELDS"
BATCH_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage ;;
    --fields) FIELDS="$2"; shift 2 ;;
    --batch) BATCH_FILE="$2"; shift 2 ;;
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

# Batch mode
if [[ -n "$BATCH_FILE" ]]; then
  if [[ ! -f "$BATCH_FILE" ]]; then
    echo "Error: batch file not found: $BATCH_FILE" >&2
    exit 1
  fi

  # Read IDs, filter blank lines, take max 500
  mapfile -t IDS < <(grep -v '^[[:space:]]*$' "$BATCH_FILE" | head -500)

  if [[ ${#IDS[@]} -eq 0 ]]; then
    echo "Error: no IDs found in $BATCH_FILE" >&2
    exit 1
  fi

  # Build JSON array of IDs
  IDS_JSON=$(printf '%s\n' "${IDS[@]}" | python3 -c "import json, sys; print(json.dumps({'ids': [l.strip() for l in sys.stdin]}))")
  URL="${GRAPH_API}/paper/batch?fields=${FIELDS}"
  curl_post "$URL" "$IDS_JSON"
  exit 0
fi

# Single paper mode
if [[ -z "$PAPER_ID" ]]; then
  echo "Error: paper_id is required." >&2
  echo "Run '$(basename "$0") --help' for usage." >&2
  exit 1
fi

# URL-encode the paper ID (handles colons, slashes in DOI/URL types)
ENCODED_ID=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$PAPER_ID" 2>/dev/null || printf '%s' "$PAPER_ID" | sed 's| |%20|g')

URL="${GRAPH_API}/paper/${ENCODED_ID}?fields=${FIELDS}"
curl_get "$URL"
