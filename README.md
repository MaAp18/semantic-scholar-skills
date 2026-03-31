# Semantic Scholar Skills

A [Paperclip](https://paperclip.ing) skill repository for interacting with the [Semantic Scholar Academic Graph API](https://api.semanticscholar.org/api-docs/). Enables AI agents to search papers, explore citation networks, discover author profiles, and retrieve paper recommendations from one of the largest academic knowledge bases in existence.

---

## Table of Contents

- [Overview](#overview)
- [Repository Structure](#repository-structure)
- [Quick Start](#quick-start)
- [Environment Variables](#environment-variables)
- [Skill Installation (Paperclip)](#skill-installation-paperclip)
- [API Coverage](#api-coverage)
- [Helper Scripts](#helper-scripts)
- [Usage Examples](#usage-examples)
- [Rate Limits](#rate-limits)
- [Links](#links)

---

## Overview

This repository provides:

- **`skills/semantic-scholar/`** — A Paperclip skill (`SKILL.md`) and reference documentation that teaches AI agents how to use the Semantic Scholar API.
- **`scripts/`** — Shell helper scripts for common API operations, designed for both agent and human use.
- **`examples/`** — Annotated usage examples covering common research workflows.

The skill covers three Semantic Scholar API surfaces:

| API | Purpose |
|-----|---------|
| Academic Graph API | Paper search, citation graphs, author profiles |
| Recommendations API | Discover related papers from seed paper(s) |
| Datasets API | Bulk downloads for offline analysis |

---

## Repository Structure

```
semantic-scholar-skills/
├── README.md
├── .gitignore
├── skills/
│   └── semantic-scholar/
│       ├── SKILL.md                        # Main skill document for Paperclip
│       └── references/
│           ├── academic-graph-api.md       # Academic Graph API reference
│           ├── recommendations-api.md      # Recommendations API reference
│           └── datasets-api.md            # Datasets API reference
├── scripts/
│   ├── search-papers.sh                   # Search papers by keyword/query
│   ├── get-paper.sh                       # Get details for a specific paper
│   ├── search-authors.sh                  # Search authors by name
│   ├── get-citations.sh                   # Get citations for a paper
│   └── get-recommendations.sh             # Get paper recommendations
└── examples/
    └── usage-examples.md                  # Annotated research workflow examples
```

---

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/MaAp18/semantic-scholar-skills.git
cd semantic-scholar-skills
```

### 2. Set your API key

```bash
export SEMANTIC_SCHOLAR_API_KEY=YOUR_API_KEY
```

> **Note:** The API works without a key (unauthenticated) but at reduced rate limits. See [Rate Limits](#rate-limits).

### 3. Run a paper search

```bash
chmod +x scripts/*.sh
./scripts/search-papers.sh "transformer attention mechanism"
```

### 4. Import the skill into Paperclip (see [Skill Installation](#skill-installation-paperclip))

---

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `SEMANTIC_SCHOLAR_API_KEY` | No | API key for higher rate limits. Omit or leave blank for unauthenticated access. |

**Security:** Never commit your API key to source control. Always set it via environment variable or a secrets manager. See `.gitignore` for excluded patterns.

---

## Skill Installation (Paperclip)

### Import from GitHub URL

In your Paperclip company, import this repository as a skill source:

```
https://github.com/MaAp18/semantic-scholar-skills
```

Paperclip will discover the skill at `skills/semantic-scholar/SKILL.md` automatically.

### Assign to an agent

After importing, assign the `semantic-scholar` skill to any agent that needs academic research capabilities:

```
POST /api/agents/{agentId}/skills/sync
{
  "desiredSkills": ["semantic-scholar"]
}
```

Or use the Paperclip UI: **Agent settings → Skills → Add skill → semantic-scholar**.

### Verify installation

The agent should have access to the skill documentation and be able to make requests to `https://api.semanticscholar.org/graph/v1/`.

---

## API Coverage

### Academic Graph API

Base URL: `https://api.semanticscholar.org/graph/v1`

| Operation | Endpoint | Script |
|-----------|----------|--------|
| Search papers | `GET /paper/search` | `search-papers.sh` |
| Get paper details | `GET /paper/{paperId}` | `get-paper.sh` |
| Get paper citations | `GET /paper/{paperId}/citations` | `get-citations.sh` |
| Get paper references | `GET /paper/{paperId}/references` | `get-citations.sh` |
| Batch paper lookup | `POST /paper/batch` | — |
| Search authors | `GET /author/search` | `search-authors.sh` |
| Get author details | `GET /author/{authorId}` | — |
| Get author papers | `GET /author/{authorId}/papers` | — |

**Paper ID formats accepted:** `{paperId}`, `DOI:{doi}`, `ARXIV:{arxivId}`, `MAG:{magId}`, `PMID:{pubmedId}`, `PMCID:{pmcId}`, `URL:{url}`, `CorpusId:{corpusId}`

### Recommendations API

Base URL: `https://api.semanticscholar.org/recommendations/v1`

| Operation | Endpoint | Script |
|-----------|----------|--------|
| Single-paper recommendations | `GET /papers/forpaper/{paperId}` | `get-recommendations.sh` |
| Multi-paper recommendations | `POST /papers/` | — |

### Datasets API

Base URL: `https://api.semanticscholar.org/datasets/v1`

| Operation | Endpoint |
|-----------|----------|
| List available releases | `GET /releases` |
| Get release details | `GET /release/{releaseId}` |
| List datasets in release | `GET /release/{releaseId}/dataset` |
| Get dataset download links | `GET /release/{releaseId}/dataset/{datasetName}` |

See `skills/semantic-scholar/references/datasets-api.md` for full details on bulk downloads.

---

## Helper Scripts

All scripts read `SEMANTIC_SCHOLAR_API_KEY` from the environment. If not set, requests are made unauthenticated.

### `search-papers.sh`

Search for papers by keyword or natural language query.

```bash
./scripts/search-papers.sh "QUERY" [LIMIT] [FIELDS]
```

| Argument | Default | Description |
|----------|---------|-------------|
| `QUERY` | (required) | Search query string |
| `LIMIT` | `10` | Number of results (max 100) |
| `FIELDS` | `paperId,title,year,authors` | Comma-separated fields to return |

### `get-paper.sh`

Retrieve full details for a specific paper.

```bash
./scripts/get-paper.sh "PAPER_ID" [FIELDS]
```

Accepts any supported paper ID format (DOI, arXiv ID, Semantic Scholar ID, etc.).

### `search-authors.sh`

Search for authors by name.

```bash
./scripts/search-authors.sh "AUTHOR_NAME" [LIMIT]
```

### `get-citations.sh`

Get citations or references for a paper.

```bash
./scripts/get-citations.sh "PAPER_ID" [citations|references] [LIMIT]
```

### `get-recommendations.sh`

Get paper recommendations based on a seed paper.

```bash
./scripts/get-recommendations.sh "PAPER_ID" [LIMIT]
```

---

## Usage Examples

See [`examples/usage-examples.md`](examples/usage-examples.md) for annotated workflows covering:

- Finding papers on a research topic
- Exploring citation networks
- Discovering an author's publication history
- Getting paper recommendations from a seed paper
- Batch lookups and bulk operations
- Troubleshooting common errors

---

## Rate Limits

| Mode | Rate Limit |
|------|-----------|
| Unauthenticated | 1 request/second |
| Authenticated (with API key) | 10 requests/second (default) |

Requests exceeding the rate limit receive a `429 Too Many Requests` response. Implement exponential backoff when retrying.

To request a higher rate limit, contact Semantic Scholar at [api@semanticscholar.org](mailto:api@semanticscholar.org).

---

## Links

- [Semantic Scholar API Docs](https://api.semanticscholar.org/api-docs/)
- [Semantic Scholar API Explorer](https://api.semanticscholar.org/api-docs/graph)
- [Semantic Scholar Website](https://www.semanticscholar.org/)
- [Paperclip Documentation](https://paperclip.ing/docs)
- [Report an issue](https://github.com/MaAp18/semantic-scholar-skills/issues)

---

> **Security reminder:** Never commit API keys, tokens, or other secrets to this repository. Use environment variables or a secrets manager. The `.gitignore` excludes common secret file patterns, but always review before committing.

