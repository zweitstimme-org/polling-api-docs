# Results Endpoint

Access poll results in a flattened format, optimized for analysis.

## When to Use Results Endpoint

The `/v1/results` endpoint is useful when you:

- Need results across multiple polls in one query
- Want to filter by specific parties
- Are building time series or comparative analyses
- Prefer flat data structure over nested results

## List Results

```
GET /v1/results
```

Retrieve poll results with filters and pagination.

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `limit` | integer | No | 100 | Max rows to return (1-500) |
| `offset` | integer | No | 0 | Rows to skip |
| `scope` | string | No | - | Filter by scope (e.g., "federal", "bayern") |
| `institute_id` | integer | No | - | Filter by institute ID |
| `provider_id` | integer | No | - | Filter by provider ID |
| `election_id` | integer | No | - | Filter by election ID |
| `party_id` | integer | No | - | Filter by party ID |
| `date_from` | date | No | - | Publish date >= this date (YYYY-MM-DD) |
| `date_to` | date | No | - | Publish date <= this date (YYYY-MM-DD) |

### Example Request

```r
library(httr2)

# Get results for CDU/CSU in 2024
results <- request("https://api.fasttrack29.com/v1/results") |>
  req_url_query(
    scope = "federal",
    party_id = 1,  # CDU/CSU
    date_from = "2024-01-01",
    date_to = "2024-12-31",
    limit = 100
  ) |>
  req_perform() |>
  resp_body_json()
```

### Example Response

```json
{
  "items": [
    {
      "poll_id": 12345,
      "raw_id": 12344,
      "publish_date": "2024-01-15",
      "scope": "federal",
      "institute_id": 1,
      "provider_id": 2,
      "election_id": 5,
      "results": [
        {
          "party_id": 1,
          "party_short_name": "CDU/CSU",
          "party_name": "Christlich Demokratische Union/Christlich-Soziale Union",
          "percentage": 31.5
        },
        {
          "party_id": 2,
          "party_short_name": "SPD",
          "party_name": "Sozialdemokratische Partei Deutschlands",
          "percentage": 16.0
        }
      ]
    }
  ],
  "meta": {
    "total": 15000,
    "limit": 100,
    "offset": 0
  }
}
```

### Response Fields

**Result Item**:

| Field | Type | Description |
|-------|------|-------------|
| `poll_id` | integer | Poll identifier |
| `raw_id` | integer \| null | Reference to raw poll |
| `publish_date` | string \| null | Publication date |
| `scope` | string \| null | Geographic scope |
| `institute_id` | integer \| null | Institute ID |
| `provider_id` | integer \| null | Provider ID |
| `election_id` | integer \| null | Election ID |
| `results` | array | Party results for this poll |

**Note**: Unlike `/v1/polls`, this endpoint always includes results.

## Comparison with Polls Endpoint

| Feature | /v1/polls | /v1/results |
|---------|-----------|-------------|
| Includes full poll metadata | Yes | Limited |
| Includes results | Optional (include_results param) | Always |
| Can filter by party_id | No | Yes |
| Best for | Detailed poll info | Bulk result analysis |
| Response structure | Nested | Flattened |

## Working with Large Datasets

The results endpoint supports pagination for large queries:

```r
get_all_results <- function(party_id, date_from) {
  all_items <- list()
  offset <- 0
  limit <- 500
  
  repeat {
    response <- request("https://api.fasttrack29.com/v1/results") |>
      req_url_query(
        scope = "federal",
        party_id = party_id,
        date_from = date_from,
        limit = limit,
        offset = offset
      ) |>
      req_perform() |>
      resp_body_json()
    
    all_items <- c(all_items, response$items)
    
    if (length(response$items) < limit) break
    offset <- offset + limit
    
    # Be nice to the API
    Sys.sleep(0.1)
  }
  
  return(all_items)
}

# Get all CDU/CSU results since 2020
all_cdu <- get_all_results(1, "2020-01-01")
```

## See Also

- [Polls](polls.md) — Get polls with full metadata
- [Reference Tables](reference-tables.md) — Look up party IDs
- [Use Cases: Time Series](../use-cases/time-series.md) — More examples
