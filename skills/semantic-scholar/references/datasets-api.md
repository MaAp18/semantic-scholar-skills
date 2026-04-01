# Semantic Scholar Datasets API Reference

**Base URL**: `https://api.semanticscholar.org/datasets/v1`
**Swagger**: `https://api.semanticscholar.org/datasets/v1/swagger.json`

## Overview

The Datasets API provides bulk download access to the full Semantic Scholar corpus as partitioned files hosted on Amazon S3. Use this API when you need the complete dataset for large-scale research rather than querying individual papers.

> **Note:** Bulk data access may require a separate data access agreement with Semantic Scholar. Contact [api@semanticscholar.org](mailto:api@semanticscholar.org) before attempting large-scale downloads.

## Authentication

- Header: `x-api-key: <your-key>`
- Required for obtaining S3 download URLs. Use the same key as the Academic Graph API.

---

## Endpoints

### `GET /release/`

List all available release identifiers.

**Query parameters**: None

**Response**: Array of date-stamp strings
```json
["2023-08-01", "2023-09-01", "2023-10-01"]
```

---

### `GET /release/{release_id}`

Get metadata for a specific release, including its available datasets.

**Path parameters**:

| Param | Type | Description |
|-------|------|-------------|
| `release_id` | string | **Required.** Date stamp (from `/release/` list) |

**Response**:
```json
{
  "release_id": "2023-08-01",
  "README": "Description of this release...",
  "datasets": [
    { "name": "papers",    "description": "All paper records",  "README": "..." },
    { "name": "authors",   "description": "All author records", "README": "..." },
    { "name": "citations", "description": "Citation edges",     "README": "..." }
  ]
}
```

---

### `GET /release/{release_id}/dataset/{dataset_name}`

Get pre-signed S3 download URLs for all partitions of a dataset in a release.

**Path parameters**:

| Param | Type | Description |
|-------|------|-------------|
| `release_id` | string | **Required.** Release date stamp |
| `dataset_name` | string | **Required.** Dataset name (e.g., `papers`, `authors`, `citations`) |

**Response**:
```json
{
  "name": "papers",
  "description": "...",
  "README": "...",
  "files": [
    "https://s3.amazonaws.com/ai2-s2-research-public/open-corpus/2023-08-01/papers-part0.jsonl.gz",
    "https://s3.amazonaws.com/ai2-s2-research-public/open-corpus/2023-08-01/papers-part1.jsonl.gz"
  ]
}
```

Pre-signed URLs expire — download promptly after calling this endpoint.

---

### `GET /diffs/{start_release_id}/to/{end_release_id}/{dataset_name}`

Get incremental diff files between two releases. Use this to update an existing dataset snapshot without re-downloading the full corpus.

**Path parameters**:

| Param | Type | Description |
|-------|------|-------------|
| `start_release_id` | string | **Required.** Your current release |
| `end_release_id` | string | **Required.** Target release, or `"latest"` for the most recent |
| `dataset_name` | string | **Required.** Dataset to diff |

**Response**:
```json
{
  "dataset": "papers",
  "start_release": "2023-07-01",
  "end_release": "2023-08-01",
  "diffs": [
    {
      "from_release": "2023-07-01",
      "to_release": "2023-08-01",
      "update_files": [
        "https://s3.amazonaws.com/...papers-updates-part0.jsonl.gz"
      ],
      "delete_files": [
        "https://s3.amazonaws.com/...papers-deletes-part0.jsonl.gz"
      ]
    }
  ]
}
```

- `update_files` — JSONL records to upsert (add or replace)
- `delete_files` — IDs to remove from your local copy
- Use `"latest"` for `end_release_id` to always target the newest available release

---

## Common Dataset Names

Verify available datasets by calling `GET /release/{release_id}` — names may change between releases.

| Name | Description |
|------|-------------|
| `papers` | Full paper metadata records |
| `authors` | Author profile records |
| `citations` | Citation edges (source → destination) |
| `paper-ids` | Mapping of paper IDs across identifier systems |
| `embeddings-specter_v1` | SPECTER v1 embeddings (high-dimensional vectors) |
| `embeddings-specter_v2` | SPECTER v2 embeddings |
| `tldrs` | AI-generated paper summaries |

---

## File Format

All dataset files are **JSONL** (one JSON object per line) compressed with **gzip** (`.jsonl.gz`).

```bash
# Inspect the first 5 records of a partition
curl -sL "<presigned-url>" | gunzip | head -5
```

---

## Rate Limits

| Mode | Effective Rate |
|------|----------------|
| API key | 1 req/sec (introductory) |

The Datasets API endpoints themselves are low-frequency (metadata only). S3 downloads are not rate-limited by Semantic Scholar, but large-scale downloads should be parallelized responsibly.

---

## Workflow

1. List available releases: `GET /release/`
2. Pick the latest or check release metadata: `GET /release/{release_id}`
3. Get download URLs for your dataset: `GET /release/{release_id}/dataset/{dataset_name}`
4. Download all partition files from the returned pre-signed URLs
5. For incremental updates: `GET /diffs/{old}/to/latest/{dataset}` and apply update/delete files

---

## Notes

- No pagination on any datasets endpoint — all results returned in a single response
- Pre-signed S3 URLs expire; fetch and start downloading immediately
- Bulk data access may require a separate data access agreement — contact [api@semanticscholar.org](mailto:api@semanticscholar.org)

