# Semantic Scholar Academic Graph API Reference

**Base URL**: `https://api.semanticscholar.org/graph/v1`
**Swagger**: `https://api.semanticscholar.org/graph/v1/swagger.json`

## Authentication

- Header: `x-api-key: <your-key>`
- Optional but strongly recommended. Without it, requests share a rate-limited unauthenticated pool.
- Obtain a key by request from Semantic Scholar support.

## General Behavior

- Default response (no `fields`): `paperId` + `title` for papers; `authorId` + `name` for authors.
- Nested field access uses dot notation: `authors.name`, `citations.title`.
- Max response size: **10 MB** per request.
- Paginated list responses: `{ "offset": int, "next": int, "data": [...] }` — `next` is absent on the last page.
- Search responses include `"total"`.
- Bulk search uses a `token` cursor instead of `offset`.

---

## Paper Endpoints

### `GET /paper/{paper_id}`

Get full details for a single paper.

**Path parameter — `paper_id`** (supports multiple ID types):

| Format | Example |
|--------|---------|
| `{SHA}` (40-char hex, default) | `649def34f8be52c8b66281af98ae884c09aef38b` |
| `CorpusId:{id}` | `CorpusId:215416146` |
| `DOI:{doi}` | `DOI:10.18653/v1/N18-3011` |
| `ARXIV:{id}` | `ARXIV:2303.08774` |
| `MAG:{id}` | `MAG:112218234` |
| `ACL:{id}` | `ACL:W12-3903` |
| `PMID:{id}` | `PMID:19872477` |
| `PMCID:{id}` | `PMCID:2323736` |
| `URL:{url}` | `URL:https://arxiv.org/abs/2106.15928v1` |

**Query parameters**:

| Param | Type | Description |
|-------|------|-------------|
| `fields` | string | Comma-separated paper field names |

---

### `POST /paper/batch`

Get details for up to **500** papers at once.

**Query parameters**:

| Param | Type | Description |
|-------|------|-------------|
| `fields` | string | Comma-separated paper field names |

**Request body**:
```json
{ "ids": ["paperId1", "DOI:10.1234/foo", "ARXIV:2303.00001"] }
```

**Limits**: Max 9,999 citations in a single response.

---

### `GET /paper/search`

Relevance-ranked full-text search.

**Query parameters**:

| Param | Type | Default | Max | Description |
|-------|------|---------|-----|-------------|
| `query` | string | — | — | **Required.** Search terms |
| `fields` | string | — | — | Comma-separated field names |
| `offset` | integer | 0 | 9,900 | Pagination start |
| `limit` | integer | 100 | 100 | Results per page |
| `publicationTypes` | string | — | — | Comma-separated publication type filter |
| `openAccessPdf` | flag | — | — | No value needed; filters to open-access papers |
| `minCitationCount` | string | — | — | Minimum citation count |
| `publicationDateOrYear` | string | — | — | Date range (see formats below) |
| `year` | string | — | — | Year or year range |
| `venue` | string | — | — | Comma-separated venue names |
| `fieldsOfStudy` | string | — | — | Comma-separated academic fields |

**Max total results**: 1,000 (limit × offset cannot exceed 9,900).

---

### `GET /paper/search/bulk`

Unranked bulk keyword search with cursor pagination. Not relevance-ranked. Supports up to 10 million total results.

**Query parameters**:

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `query` | string | — | **Required.** Boolean syntax supported |
| `fields` | string | — | Comma-separated field names |
| `token` | string | — | Cursor for next page (from previous response) |
| `sort` | string | `paperId:asc` | `field:order`. Sortable fields: `paperId`, `citationCount`, `publicationDate` |
| `publicationTypes` | string | — | Same as `/paper/search` |
| `openAccessPdf` | flag | — | — |
| `minCitationCount` | string | — | — |
| `publicationDateOrYear` | string | — | — |
| `year` | string | — | — |
| `venue` | string | — | — |
| `fieldsOfStudy` | string | — | — |

**Boolean query syntax**:
- `+` — AND (default between terms)
- `|` — OR
- `-` — NOT
- `"..."` — phrase match
- `*` — wildcard (suffix only)
- `~N` — fuzzy (N = edit distance)

**Results per page**: 1,000 max. Nested fields (`citations`, `references`) unavailable.

**Response**:
```json
{ "total": "1234567", "token": "abc123...", "data": [...] }
```
`token` is absent on the last page.

---

### `GET /paper/search/match`

Returns the single best-matching paper for a title string.

**Query parameters**: Same as `/paper/search` plus `fields`.

---

### `GET /paper/autocomplete`

Returns query completion suggestions for a partial title.

**Query parameters**:

| Param | Type | Description |
|-------|------|-------------|
| `query` | string | **Required.** Max 100 characters |

---

### `GET /paper/{paper_id}/authors`

List authors of a paper.

**Query parameters**:

| Param | Type | Default | Max |
|-------|------|---------|-----|
| `fields` | string | — | — |
| `offset` | integer | 0 | — |
| `limit` | integer | 100 | 1,000 |

---

### `GET /paper/{paper_id}/citations`

Get papers that cite this paper (incoming citations).

**Query parameters**:

| Param | Type | Default | Max | Description |
|-------|------|---------|-----|-------------|
| `fields` | string | — | — | Citation edge and paper fields |
| `offset` | integer | 0 | — | — |
| `limit` | integer | 100 | 1,000 | — |
| `publicationDateOrYear` | string | — | — | Filter by publication date range |

---

### `GET /paper/{paper_id}/references`

Get papers cited by this paper (outgoing references).

**Query parameters**:

| Param | Type | Default | Max |
|-------|------|---------|-----|
| `fields` | string | — | — |
| `offset` | integer | 0 | — |
| `limit` | integer | 100 | 1,000 |

---

## Author Endpoints

### `GET /author/{author_id}`

Get details for a single author.

**Query parameters**: `fields` (comma-separated author fields).

---

### `POST /author/batch`

Get details for up to **1,000** authors at once.

**Query parameters**: `fields`

**Request body**:
```json
{ "ids": ["authorId1", "authorId2"] }
```

---

### `GET /author/search`

Search authors by name.

**Query parameters**:

| Param | Type | Default | Max |
|-------|------|---------|-----|
| `query` | string | — | — |
| `fields` | string | — | — |
| `offset` | integer | 0 | — |
| `limit` | integer | 100 | 1,000 |

---

### `GET /author/{author_id}/papers`

Get all papers by an author.

**Query parameters**:

| Param | Type | Default | Max | Description |
|-------|------|---------|-----|-------------|
| `fields` | string | — | — | — |
| `offset` | integer | 0 | — | — |
| `limit` | integer | 100 | 1,000 | — |
| `publicationDateOrYear` | string | — | — | Date range filter |

---

## Snippet Endpoint

### `GET /snippet/search`

Full-text search over ~500-word paper chunks. Returns the highest-ranked snippet per matching paper.

**Query parameters**:

| Param | Type | Default | Max | Description |
|-------|------|---------|-----|-------------|
| `query` | string | — | — | **Required.** Plain text only |
| `fields` | string | — | — | Snippet field names |
| `limit` | integer | 10 | 1,000 | Results |
| `paperIds` | string | — | ~100 | Comma-separated paper IDs to restrict to |
| `authors` | string | — | 10 | Comma-separated author names (AND, fuzzy) |
| `minCitationCount` | string | — | — | — |
| `insertedBefore` | string | — | — | `YYYY-MM-DD` |
| `publicationDateOrYear` | string | — | — | — |
| `year` | string | — | — | — |
| `venue` | string | — | — | — |
| `fieldsOfStudy` | string | — | — | — |

---

## Available Fields

### Paper Fields

> **Tip:** For most tasks, use the prebuilt field sets in `SKILL.md` (`paperId,title,abstract,year,authors` for basics; `paperId,title,abstract,year,venue,publicationDate,citationCount,referenceCount,isOpenAccess,openAccessPdf,fieldsOfStudy,authors` for full detail). Request only the fields you need — responses exceeding 10 MB will return a `400` error.

```
paperId               corpusId              externalIds
url                   title                 abstract
venue                 publicationVenue      year
referenceCount        citationCount         influentialCitationCount
isOpenAccess          openAccessPdf         fieldsOfStudy
s2FieldsOfStudy       publicationTypes      publicationDate
journal               citationStyles        authors
citations             references            embedding
tldr                  textAvailability
```

**Nested paper fields** (dot notation):

```
authors.authorId        authors.name          authors.affiliations
authors.homepage        authors.paperCount    authors.citationCount
authors.hIndex

citations.paperId       citations.title       citations.abstract
citations.authors       citations.url         citations.venue
citations.year          citations.citationCount citations.isInfluential
citations.contexts      citations.intents

references.paperId      references.title      references.abstract
references.authors      references.url        references.venue
references.year         references.citationCount references.isInfluential
references.contexts     references.intents

embedding.specter_v1    embedding.specter_v2
```

### Author Fields

```
authorId    externalIds   url         name
affiliations homepage     paperCount  citationCount
hIndex      papers
```

**Nested author fields**:

```
papers.paperId    papers.title    papers.year
papers.authors    papers.abstract papers.url
papers.citationCount              papers.venue
```

### Citation/Reference Edge Fields

```
contexts          intents           contextsWithIntent
isInfluential

citingPaper.{any BasePaper field}   (citations endpoint)
citedPaper.{any BasePaper field}    (references endpoint)
```

### Snippet Fields

```
snippet.text
snippet.snippetKind
snippet.section
snippet.snippetOffset.start
snippet.snippetOffset.end
snippet.annotations.refMentions.start
snippet.annotations.refMentions.end
snippet.annotations.refMentions.matchedPaperCorpusId
snippet.annotations.sentences.start
snippet.annotations.sentences.end
```

---

## Filter Values

### `publicationTypes`

```
Review, JournalArticle, CaseReport, ClinicalTrial, Conference, Dataset,
Editorial, LettersAndComments, MetaAnalysis, News, Study, Book, BookSection
```

### `fieldsOfStudy`

Values are **case-sensitive** and must match exactly. Pass multiple values as a comma-separated string.

```
Computer Science, Medicine, Chemistry, Biology, Materials Science, Physics,
Geology, Psychology, Art, History, Geography, Sociology, Business,
Political Science, Economics, Philosophy, Mathematics, Engineering,
Environmental Science, Agricultural and Food Sciences, Education, Law, Linguistics
```

### Date Format (`publicationDateOrYear` / `year`)

| Format | Example |
|--------|---------|
| Specific date | `2019-03-05` |
| Month | `2019-03` |
| Year | `2019` |
| Date range | `2016-03-05:2020-06-06` |
| After date | `2015-01:` |
| Before date | `:2015-01` |
| Year range | `2015:2020` |

---

## Response Structures

**Single item**:
```json
{ "paperId": "abc123", "title": "...", ... }
```

**Paginated list**:
```json
{ "offset": 0, "next": 100, "data": [ {...}, ... ] }
```

**Search results**:
```json
{ "total": "12345", "offset": 0, "next": 100, "data": [ {...}, ... ] }
```

**Bulk search (cursor)**:
```json
{ "total": "99999", "token": "abc123...", "data": [ {...}, ... ] }
```

---

## Rate Limits

| Mode | Effective Rate |
|------|----------------|
| Unauthenticated | ~1 req/sec (shared across ALL unauthenticated users) |
| API key (introductory) | 1 req/sec dedicated |
| Higher tiers | Contact Semantic Scholar support |

## Error Codes

| Code | Meaning |
|------|---------|
| `400` | Bad query, unsupported fields, or response > 10 MB |
| `403` | Invalid or expired API key |
| `404` | Paper or author not found |

