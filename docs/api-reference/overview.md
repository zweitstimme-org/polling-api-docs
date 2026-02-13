# API Reference Overview

Complete reference for all API endpoints. Each endpoint includes the URL, parameters, and example responses.

## Base URL

```
https://api.fasttrack29.com
```

## Response Format

All responses are in **JSON format** with a consistent structure:

```json
{
  "items": [...],  // Array of data objects
  "meta": {        // Pagination metadata
    "total": 1000,
    "limit": 100,
    "offset": 0
  }
}
```

## Common Concepts

### Pagination

Large datasets are split into pages using `limit` and `offset`:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `limit` | integer | 100 | Number of items per page (max: 500 for polls, 1000 for raw) |
| `offset` | integer | 0 | Number of items to skip |

**Example**: Get page 2 with 50 items per page
```r
request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    limit = 50,
    offset = 50  # Skip first 50 items
  ) |>
  req_perform()
```

**Iterating through all results**:
```r
library(httr2)
library(purrr)

get_all_polls <- function() {
  all_items <- list()
  offset <- 0
  limit <- 100
  
  repeat {
    response <- request("https://api.fasttrack29.com/v1/polls") |>
      req_url_query(limit = limit, offset = offset) |>
      req_perform() |>
      resp_body_json()
    
    all_items <- c(all_items, response$items)
    
    # Check if we've got all items
    if (length(response$items) < limit) break
    
    offset <- offset + limit
  }
  
  return(all_items)
}
```

### Date Filtering

Most endpoints support date range filtering:

| Parameter | Format | Description |
|-----------|--------|-------------|
| `date_from` | YYYY-MM-DD | Include polls published on or after this date |
| `date_to` | YYYY-MM-DD | Include polls published on or before this date |

**Example**:
```r
request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    date_from = "2024-01-01",
    date_to = "2024-12-31"
  ) |>
  req_perform()
```

### Filtering by IDs

Many endpoints accept ID filters for precise queries:

```r
request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    institute_id = 1,   // Forsa
    election_id = 5     // Bundestagswahl 2021
  ) |>
  req_perform()
```

Find IDs using the [reference endpoints](reference-tables.md).

### Boolean Parameters

Some endpoints accept boolean (true/false) parameters:

```r
request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    include_results = TRUE  // Include party results in response
  ) |>
  req_perform()
```

## Error Responses

The API uses standard HTTP status codes:

| Status | Meaning | Common Causes |
|--------|---------|---------------|
| 200 | OK | Request successful |
| 400 | Bad Request | Invalid parameters |
| 404 | Not Found | Endpoint doesn't exist |
| 422 | Validation Error | Parameter validation failed |
| 500 | Server Error | Something went wrong on our end |

**Validation error example**:
```json
{
  "detail": [
    {
      "loc": ["query", "date_from"],
      "msg": "invalid date format",
      "type": "value_error.date"
    }
  ]
}
```

## Endpoint Categories

| Category | Endpoints | Description |
|----------|-----------|-------------|
| [Polls](polls.md) | `/v1/polls/*` | Cleaned polling data |
| [Raw Polls](raw-polls.md) | `/v1/raw-polls/*` | Original scraped data |
| [Results](results.md) | `/v1/results` | Flattened poll results |
| [Reference](reference-tables.md) | `/v1/reference/*` | Lookup tables |
| [Elections](elections.md) | `/v1/elections/*` | Election metadata |
| [Downloads](downloads.md) | `/v1/download/*` | Bulk data exports |

## Rate Limiting

Currently, the API has generous rate limits for academic use. If you need higher limits, please contact us.

## Testing Endpoints

You can test any endpoint directly in your browser:

```
https://api.fasttrack29.com/v1/polls?limit=5&scope=federal
```

Or use tools like:
- [Postman](https://www.postman.com/)
- [curl](https://curl.se/)
- [httr2 in R](../r-guide/vignette.md)

## Next Steps

Explore the detailed endpoint documentation:

- **[Polls](polls.md)** — Cleaned polling data
- **[Raw Polls](raw-polls.md)** — Original data
- **[Results](results.md)** — Party results
- **[Reference Tables](reference-tables.md)** — Lookups
- **[Elections](elections.md)** — Election info
- **[Downloads](downloads.md)** — Bulk exports
