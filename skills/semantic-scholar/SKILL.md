---
name: semantic-scholar
---

# Semantic Scholar Skill

Search academic literature, retrieve paper details, analyze citations, and explore author profiles using the Semantic Scholar API.

## Authentication

Set `SEMANTIC_SCHOLAR_API_KEY` in the environment to use an authenticated key (higher rate limits). Without it, the API works in rate-limited mode (shared unauthenticated pool, ~1 req/sec effective).

**Header**: `x-api-key: $SEMANTIC_SCHOLAR_API_KEY`
**Base URL**: `https://api.semanticscholar.org/graph/v1`

## Core Capabilities

### Paper Search

**Relevance search** — ranked full-text search across all papers:
```
GET /paper/search?query=<terms>&fields=<fields>&offset=<n>&limit=<n>
```
Supports filters: `publicationTypes`, `openAccessPdf`, `minCitationCount`, `publicationDateOrYear`, `year`, `venue`, `fieldsOfStudy`. Max 1,000 results total (100 per page).

**Bulk search** — unranked keyword search with cursor pagination, up to 10M papers:
```
GET /paper/search/bulk?query=<terms>&fields=<fields>&sort=<field:order>&token=<cursor>
```
Boolean syntax: `+` (AND), `|` (OR), `-` (NOT), `"..."` (phrase), `*` (wildcard), `~N` (fuzzy). Sortable by `paperId`, `citationCount`, `publicationDate`. 1,000 papers per page.

**Title match** — returns the single best-matching paper for a title string:
```
GET /paper/search/match?query=<title>
```

**Snippet search** — full-text search over 500-word paper chunks:
```
GET /snippet/search?query=<terms>&fields=<snippet_fields>&limit=<n>
```

**Autocomplete** — query completion suggestions for partial titles:
```
GET /paper/autocomplete?query=<partial_title>
```

### Paper Details

Fetch a single paper by any supported identifier:
```
GET /paper/{paper_id}?fields=<fields>
```

Supported ID formats:
- `{SHA}` — 40-char Semantic Scholar ID (default)
- `CorpusId:{id}`
- `DOI:{doi}`
- `ARXIV:{id}` (e.g. `ARXIV:2303.08774`)
- `MAG:{id}`
- `ACL:{id}`
- `PMID:{id}`
- `PMCID:{id}`
- `URL:{url}`

**Batch fetch** — up to 500 papers at once:
```
POST /paper/batch?fields=<fields>
Body: { "ids": ["id1", "id2", ...] }
```

### Citations and References

**Papers that cite this paper** (incoming citations):
```
GET /paper/{paper_id}/citations?fields=<fields>&offset=<n>&limit=<n>
```

**Papers cited by this paper** (outgoing references):
```
GET /paper/{paper_id}/references?fields=<fields>&offset=<n>&limit=<n>
```

Both endpoints return up to 1,000 results per page. Citation/reference edge fields include `isInfluential`, `contexts`, `intents`.

### Author Search and Profiles

**Search authors by name**:
```
GET /author/search?query=<name>&fields=<fields>&offset=<n>&limit=<n>
```

**Author profile**:
```
GET /author/{author_id}?fields=<fields>
```

**Author's papers**:
```
GET /author/{author_id}/papers?fields=<fields>&offset=<n>&limit=<n>
```

**Batch author fetch** — up to 1,000 authors at once:
```
POST /author/batch?fields=<fields>
Body: { "ids": ["id1", "id2", ...] }
```

### Batch Operations

Use batch endpoints to avoid repeated single-item requests. They share the same `fields` parameter as single-item endpoints.

- `/paper/batch` — max 500 paper IDs per request
- `/author/batch` — max 1,000 author IDs per request

### Recommendations

Base URL: `https://api.semanticscholar.org/recommendations/v1`

**Single-seed recommendations**:
```
GET /papers/forpaper/{paper_id}?fields=<fields>&limit=<n>&from=recent|all-cs
```

**Multi-seed recommendations** (positive + negative examples):
```
POST /papers/?fields=<fields>&limit=<n>
Body: { "positivePaperIds": [...], "negativePaperIds": [...] }
```

Max 500 recommendations per request.

## Common Field Lists

**Paper basics**: `paperId,title,abstract,year,authors`
**Paper full**: `paperId,title,abstract,year,venue,publicationDate,citationCount,referenceCount,isOpenAccess,openAccessPdf,fieldsOfStudy,authors`
**Author basics**: `authorId,name,paperCount,citationCount,hIndex`
**Citation edge**: `isInfluential,contexts,intents,citingPaper.paperId,citingPaper.title,citingPaper.year`
**Reference edge**: `isInfluential,contexts,intents,citedPaper.paperId,citedPaper.title,citedPaper.year`

## Pagination

Most endpoints use offset/limit:
```json
{ "offset": 0, "next": 100, "data": [...] }
```
`next` is absent when there are no more pages.

Bulk search uses cursor pagination:
```json
{ "total": "99999", "token": "abc...", "data": [...] }
```
`token` is absent on the last page.

## Date/Year Filters

The `publicationDateOrYear` and `year` parameters accept:
- `2024` — specific year
- `2020:2024` — year range
- `2020-01:2024-06` — date range
- `2020:` — after year (open-ended)
- `:2020` — before year (open-ended)

## Rate Limits

| Mode | Limit |
|------|-------|
| Unauthenticated | ~1 req/sec (shared pool with all unauthenticated users) |
| API key | 1 req/sec (introductory; higher tiers available on request) |

Without an API key the effective rate is very low due to shared pool. Always set `SEMANTIC_SCHOLAR_API_KEY` when available.

## Error Handling

- `400` — malformed query, unsupported fields, or response > 10 MB
- `404` — paper or author not found
- `403` — invalid or expired API key (fall back to unauthenticated mode)

## Full Reference Docs

See `references/` for detailed endpoint tables:
- `references/academic-graph-api.md` — Graph API endpoint reference
- `references/recommendations-api.md` — Recommendations API reference
- `references/datasets-api.md` — Datasets bulk download API reference
