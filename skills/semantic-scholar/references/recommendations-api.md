# Semantic Scholar Recommendations API Reference

**Base URL**: `https://api.semanticscholar.org/recommendations/v1`
**Swagger**: `https://api.semanticscholar.org/recommendations/v1/swagger.json`

## Overview

The Recommendations API suggests papers related to one or more seed papers. It supports both single-seed and multi-seed (positive/negative example) recommendation modes.

## Authentication

- Header: `x-api-key: <your-key>`
- Optional; same key as the Academic Graph API.
- Without a key, requests share a rate-limited unauthenticated pool.

---

## Endpoints

### `GET /papers/forpaper/{paper_id}`

Get recommended papers for a single seed paper.

**Path parameter**:

| Param | Type | Description |
|-------|------|-------------|
| `paper_id` | string | **Required.** Semantic Scholar paper ID (SHA format only — not DOI/ARXIV) |

**Query parameters**:

| Param | Type | Default | Max | Description |
|-------|------|---------|-----|-------------|
| `fields` | string | — | — | Comma-separated paper field names |
| `limit` | integer | 100 | 500 | Number of recommendations to return |
| `from` | string | `recent` | — | Recommendation pool: `recent` or `all-cs` |

**`from` values**:
- `recent` — recommendations drawn from recently published papers (any field)
- `all-cs` — recommendations drawn from all Computer Science papers only. **Do not use for non-CS research topics.**

---

### `POST /papers/`

Get recommendations based on positive and negative example paper lists. Useful when you want recommendations in between several known relevant papers while excluding known irrelevant ones.

**Query parameters**:

| Param | Type | Default | Max | Description |
|-------|------|---------|-----|-------------|
| `fields` | string | — | — | Comma-separated paper field names |
| `limit` | integer | 100 | 500 | Number of recommendations to return |

**Request body**:
```json
{
  "positivePaperIds": ["paperId1", "paperId2"],
  "negativePaperIds": ["paperId3", "paperId4"]
}
```

- `positivePaperIds` — papers representative of what you want
- `negativePaperIds` — papers representative of what you do not want (optional)

---

## Available Fields

Same as the Academic Graph API `BasePaper` fields:

```
paperId, corpusId, externalIds, url, title, abstract, venue, publicationVenue,
year, referenceCount, citationCount, influentialCitationCount, isOpenAccess,
openAccessPdf, fieldsOfStudy, s2FieldsOfStudy, publicationTypes, publicationDate,
journal, citationStyles, authors
```

**Nested author fields**: `authors.authorId`, `authors.name`

---

## Response Structure

```json
{
  "recommendedPapers": [
    {
      "paperId": "abc123",
      "title": "Example Paper Title",
      "year": 2023,
      "authors": [{"authorId": "123", "name": "..."}]
    }
  ]
}
```

---

## Limits

- Max recommendations per request: **500** (`limit` param)
- Max response size: **10 MB**

---

## Rate Limits

Same as the Academic Graph API:

| Mode | Effective Rate |
|------|----------------|
| Unauthenticated | ~1 req/sec (shared pool) |
| API key (introductory) | 1 req/sec dedicated |

---

## Usage Examples

Single-seed recommendations (10 papers, basic fields):

```bash
curl -H "x-api-key: $SEMANTIC_SCHOLAR_API_KEY" \
  "https://api.semanticscholar.org/recommendations/v1/papers/forpaper/649def34f8be52c8b66281af98ae884c09aef38b?fields=paperId,title,year,citationCount&limit=10&from=recent"
```

Multi-seed recommendations (positive examples only):

```bash
curl -s -X POST \
  -H "x-api-key: $SEMANTIC_SCHOLAR_API_KEY" \
  -H "Content-Type: application/json" \
  "https://api.semanticscholar.org/recommendations/v1/papers/?fields=paperId,title,year&limit=20" \
  -d '{"positivePaperIds": ["abc123", "def456"]}'
```

