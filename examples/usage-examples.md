# Semantic Scholar Skill — Usage Examples

Annotated research workflow examples for AI agents and human users. All examples use placeholder values — replace with real queries and IDs.

> **Security:** Never include real API keys in examples, scripts, or issue comments. Always use `YOUR_API_KEY` or environment variables.

---

## Table of Contents

1. [Finding Papers on a Topic](#1-finding-papers-on-a-topic)
2. [Getting Citation Networks](#2-getting-citation-networks)
3. [Discovering an Author Profile and Publications](#3-discovering-an-author-profile-and-publications)
4. [Getting Paper Recommendations](#4-getting-paper-recommendations)
5. [Batch Paper Lookups](#5-batch-paper-lookups)
6. [Working with Different Paper ID Formats](#6-working-with-different-paper-id-formats)
7. [Troubleshooting Common Errors](#7-troubleshooting-common-errors)

---

## 1. Finding Papers on a Topic

### Using the helper script

```bash
export SEMANTIC_SCHOLAR_API_KEY=YOUR_API_KEY

# Search for recent papers on a topic
./scripts/search-papers.sh "large language model reasoning" 10

# Request specific fields
./scripts/search-papers.sh "CRISPR gene editing" 5 "paperId,title,year,authors,abstract,citationCount"
```

### Direct API call

```bash
curl -H "x-api-key: $SEMANTIC_SCHOLAR_API_KEY" \
  "https://api.semanticscholar.org/graph/v1/paper/search?query=transformer+attention+mechanism&limit=5&fields=paperId,title,year,authors,citationCount"
```

**Example response (truncated):**

```json
{
  "total": 12847,
  "offset": 0,
  "next": 5,
  "data": [
    {
      "paperId": "204e3073870fae3d05bcbc2f6a8e263d9b72e776",
      "title": "Attention Is All You Need",
      "year": 2017,
      "authors": [
        { "authorId": "1689989", "name": "A. Vaswani" }
      ],
      "citationCount": 82341
    }
  ]
}
```

### Filtering by year range

```bash
curl -H "x-api-key: $SEMANTIC_SCHOLAR_API_KEY" \
  "https://api.semanticscholar.org/graph/v1/paper/search?query=protein+folding+deep+learning&year=2022-2024&limit=10&fields=paperId,title,year,citationCount"
```

### Sorting results

Use `sort` to order by `citationCount` or `publicationDate`:

```bash
curl -H "x-api-key: $SEMANTIC_SCHOLAR_API_KEY" \
  "https://api.semanticscholar.org/graph/v1/paper/search?query=reinforcement+learning&sort=citationCount&limit=10&fields=paperId,title,citationCount"
```

---

## 2. Getting Citation Networks

### Get citations for a paper (papers that cite it)

```bash
# Using script
./scripts/get-citations.sh "204e3073870fae3d05bcbc2f6a8e263d9b72e776" citations 20

# Direct API call
curl -H "x-api-key: $SEMANTIC_SCHOLAR_API_KEY" \
  "https://api.semanticscholar.org/graph/v1/paper/204e3073870fae3d05bcbc2f6a8e263d9b72e776/citations?fields=paperId,title,year,citationCount&limit=20"
```

**Example response (truncated):**

```json
{
  "offset": 0,
  "next": 20,
  "data": [
    {
      "citingPaper": {
        "paperId": "1c7ce169c44e01f15c87c4e5f2e4e2ab1b99b6c4",
        "title": "BERT: Pre-training of Deep Bidirectional Transformers for Language Understanding",
        "year": 2018,
        "citationCount": 54321
      }
    }
  ]
}
```

### Get references for a paper (papers it cites)

```bash
curl -H "x-api-key: $SEMANTIC_SCHOLAR_API_KEY" \
  "https://api.semanticscholar.org/graph/v1/paper/204e3073870fae3d05bcbc2f6a8e263d9b72e776/references?fields=paperId,title,year&limit=20"
```

### Using DOI or arXiv ID

```bash
# By DOI
curl -H "x-api-key: $SEMANTIC_SCHOLAR_API_KEY" \
  "https://api.semanticscholar.org/graph/v1/paper/DOI:10.48550/arXiv.1706.03762/citations?limit=10&fields=paperId,title,year"

# By arXiv ID
curl -H "x-api-key: $SEMANTIC_SCHOLAR_API_KEY" \
  "https://api.semanticscholar.org/graph/v1/paper/ARXIV:1706.03762/citations?limit=10&fields=paperId,title,year"
```

### Paginating through all citations

```bash
OFFSET=0
LIMIT=100

while true; do
  RESULT=$(curl -s -H "x-api-key: $SEMANTIC_SCHOLAR_API_KEY" \
    "https://api.semanticscholar.org/graph/v1/paper/PAPER_ID/citations?fields=paperId,title,year&limit=$LIMIT&offset=$OFFSET")
  
  echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); [print(p['citingPaper']['title']) for p in d['data']]"
  
  # Check if there are more results
  NEXT=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('next', 'done'))")
  [ "$NEXT" = "done" ] && break
  OFFSET=$NEXT
done
```

---

## 3. Discovering an Author Profile and Publications

### Search for an author

```bash
# Using script
./scripts/search-authors.sh "Yoshua Bengio" 5

# Direct API call
curl -H "x-api-key: $SEMANTIC_SCHOLAR_API_KEY" \
  "https://api.semanticscholar.org/graph/v1/author/search?query=Yoshua+Bengio&limit=5&fields=authorId,name,affiliations,paperCount,citationCount,hIndex"
```

**Example response:**

```json
{
  "total": 3,
  "offset": 0,
  "data": [
    {
      "authorId": "1751762",
      "name": "Yoshua Bengio",
      "affiliations": ["Université de Montréal"],
      "paperCount": 523,
      "citationCount": 312841,
      "hIndex": 143
    }
  ]
}
```

### Get an author's papers

```bash
curl -H "x-api-key: $SEMANTIC_SCHOLAR_API_KEY" \
  "https://api.semanticscholar.org/graph/v1/author/1751762/papers?fields=paperId,title,year,citationCount&limit=20&sort=citationCount"
```

### Get full author details

```bash
curl -H "x-api-key: $SEMANTIC_SCHOLAR_API_KEY" \
  "https://api.semanticscholar.org/graph/v1/author/AUTHOR_ID?fields=authorId,name,affiliations,paperCount,citationCount,hIndex,papers"
```

---

## 4. Getting Paper Recommendations

### Single-paper recommendations

Given one seed paper, get related papers:

```bash
# Using script
./scripts/get-recommendations.sh "204e3073870fae3d05bcbc2f6a8e263d9b72e776" 10

# Direct API call
curl -H "x-api-key: $SEMANTIC_SCHOLAR_API_KEY" \
  "https://api.semanticscholar.org/recommendations/v1/papers/forpaper/204e3073870fae3d05bcbc2f6a8e263d9b72e776?limit=10&fields=paperId,title,year,authors,citationCount"
```

**Example response (truncated):**

```json
{
  "recommendedPapers": [
    {
      "paperId": "9405cc0d6169988371b2755e573cc28650d14dfe",
      "title": "Improving Language Understanding by Generative Pre-Training",
      "year": 2018,
      "citationCount": 9832
    }
  ]
}
```

### Multi-paper recommendations

Provide a pool of positive seed papers and optionally negative papers:

```bash
curl -s -X POST \
  -H "x-api-key: $SEMANTIC_SCHOLAR_API_KEY" \
  -H "Content-Type: application/json" \
  "https://api.semanticscholar.org/recommendations/v1/papers/?limit=10&fields=paperId,title,year,citationCount" \
  -d '{
    "positivePaperIds": [
      "204e3073870fae3d05bcbc2f6a8e263d9b72e776",
      "9405cc0d6169988371b2755e573cc28650d14dfe"
    ],
    "negativePaperIds": [
      "PAPER_ID_TO_EXCLUDE"
    ]
  }'
```

---

## 5. Batch Paper Lookups

Look up details for up to 500 papers in a single request:

```bash
curl -s -X POST \
  -H "x-api-key: $SEMANTIC_SCHOLAR_API_KEY" \
  -H "Content-Type: application/json" \
  "https://api.semanticscholar.org/graph/v1/paper/batch?fields=paperId,title,year,citationCount" \
  -d '{
    "ids": [
      "204e3073870fae3d05bcbc2f6a8e263d9b72e776",
      "DOI:10.1038/s41586-021-03819-2",
      "ARXIV:2005.14165"
    ]
  }'
```

**Example response:**

```json
[
  {
    "paperId": "204e3073870fae3d05bcbc2f6a8e263d9b72e776",
    "title": "Attention Is All You Need",
    "year": 2017,
    "citationCount": 82341
  },
  {
    "paperId": "abc123...",
    "title": "Highly accurate protein structure prediction with AlphaFold",
    "year": 2021,
    "citationCount": 12456
  }
]
```

> **Note:** If an ID is not found, `null` is returned at that position in the array.

---

## 6. Working with Different Paper ID Formats

Semantic Scholar accepts multiple paper identifier formats:

| Format | Example |
|--------|---------|
| Semantic Scholar ID | `204e3073870fae3d05bcbc2f6a8e263d9b72e776` |
| DOI | `DOI:10.48550/arXiv.1706.03762` |
| arXiv | `ARXIV:1706.03762` |
| PubMed | `PMID:33691126` |
| PubMed Central | `PMCID:PMC8015313` |
| URL | `URL:https://arxiv.org/abs/1706.03762` |
| Corpus ID | `CorpusId:13756489` |

```bash
# All equivalent — fetching "Attention Is All You Need"
curl "https://api.semanticscholar.org/graph/v1/paper/204e3073870fae3d05bcbc2f6a8e263d9b72e776?fields=title"
curl "https://api.semanticscholar.org/graph/v1/paper/DOI:10.48550/arXiv.1706.03762?fields=title"
curl "https://api.semanticscholar.org/graph/v1/paper/ARXIV:1706.03762?fields=title"
```

---

## 7. Troubleshooting Common Errors

### `400 Bad Request`

**Cause:** Invalid query parameters or malformed request body.

**Check:**
- Query string is URL-encoded (spaces as `+` or `%20`)
- `fields` values are valid (see API docs for valid field names per endpoint)
- `limit` is within the allowed range (max 100 for search, max 500 for batch)

```bash
# Wrong — spaces in query not encoded
curl ".../paper/search?query=machine learning"

# Correct
curl ".../paper/search?query=machine+learning"
```

### `401 Unauthorized`

**Cause:** API key is invalid or malformed.

**Check:**
- Key is passed as the `x-api-key` header (not `Authorization: Bearer`)
- Key is set correctly: `export SEMANTIC_SCHOLAR_API_KEY=YOUR_KEY`
- Try removing the key entirely — unauthenticated access may still work at lower rate limits

```bash
# Correct header format
curl -H "x-api-key: $SEMANTIC_SCHOLAR_API_KEY" "..."
```

### `403 Forbidden`

**Cause:** API key exists but is inactive, expired, or lacking permissions for the requested endpoint.

**Resolution:**
- Verify the key is active at [semanticscholar.org](https://www.semanticscholar.org/)
- The Datasets API requires a separate, approved API key
- Contact [api@semanticscholar.org](mailto:api@semanticscholar.org) to request access

### `404 Not Found`

**Cause:** Paper ID or author ID does not exist in the Semantic Scholar database.

**Check:**
- Verify the ID format prefix (e.g., `DOI:`, `ARXIV:`) matches the actual ID type
- Some papers (preprints, conference papers) may not be indexed
- Try searching by title to find the correct ID

```bash
# Find the correct Semantic Scholar ID by title
curl "https://api.semanticscholar.org/graph/v1/paper/search?query=EXACT+PAPER+TITLE&fields=paperId,title" | python3 -m json.tool
```

### `429 Too Many Requests`

**Cause:** Rate limit exceeded.

**Resolution:**
- Unauthenticated: max 1 request/second. Add delays between requests.
- Authenticated: max 10 requests/second. Implement exponential backoff.
- For bulk workloads, use the Batch endpoint or Datasets API.

```bash
# Simple retry with backoff
for i in 1 2 3; do
  RESULT=$(curl -s -o /dev/null -w "%{http_code}" -H "x-api-key: $SEMANTIC_SCHOLAR_API_KEY" "YOUR_URL")
  [ "$RESULT" = "200" ] && break
  echo "Got $RESULT, waiting $((i * 2))s..."
  sleep $((i * 2))
done
```

### Empty `data` array

**Cause:** Search returned no results.

**Try:**
- Broaden the search query (fewer words, more general terms)
- Remove year filters
- Try alternative spellings or terminology

### Fields not returned

**Cause:** Some fields are optional and only appear when data exists.

- `abstract` may be `null` for older or restricted papers
- `tldr` (AI-generated summary) is not available for all papers
- `openAccessPdf` is only present when an open-access version is indexed

Always write defensive code that checks for `null` before accessing nested fields.

