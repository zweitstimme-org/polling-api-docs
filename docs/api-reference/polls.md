# Polls Endpoint

Access cleaned, standardized polling data ready for analysis.

## List Polls

```
GET /v1/polls
```

Retrieve a list of cleaned polls with optional filtering.

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `limit` | integer | No | 100 | Max rows to return (1-500) |
| `offset` | integer | No | 0 | Rows to skip |
| `scope` | string | No | - | Filter by scope (e.g., "federal", "bayern") |
| `institute_id` | integer | No | - | Filter by institute ID |
| `provider_id` | integer | No | - | Filter by provider ID |
| `election_id` | integer | No | - | Filter by election ID |
| `method_id` | integer | No | - | Filter by method ID |
| `date_from` | date | No | - | Publish date >= this date (YYYY-MM-DD) |
| `date_to` | date | No | - | Publish date <= this date (YYYY-MM-DD) |
| `include_results` | boolean | No | true | Include party result rows |

### Example Request

```r
library(httr2)

# Get recent federal polls
polls <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "federal",
    date_from = "2024-01-01",
    limit = 10,
    include_results = TRUE
  ) |>
  req_perform() |>
  resp_body_json()
```

### Example Response

```json
{
  "items": [
    {
      "id": 12345,
      "raw_id": 12344,
      "publish_date": "2024-01-15",
      "survey_date_start": "2024-01-08",
      "survey_date_end": "2024-01-12",
      "respondents": 2501,
      "scope": "federal",
      "source": "wahlrecht.de",
      "institute_id": 1,
      "institute_name": "Forsa",
      "provider_id": 2,
      "provider_name": "Forsa Institute",
      "election_id": 5,
      "election_type": "Bundestagswahl",
      "method_id": 1,
      "method_name": "Telefon",
      "date_downloaded": "2024-01-15T10:30:00",
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
    "total": 15432,
    "limit": 10,
    "offset": 0
  }
}
```

### Response Fields

**Poll Object**:

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Unique poll identifier |
| `raw_id` | integer \| null | Reference to raw poll |
| `publish_date` | string \| null | Publication date (YYYY-MM-DD) |
| `survey_date_start` | string \| null | Survey start date |
| `survey_date_end` | string \| null | Survey end date |
| `respondents` | integer \| null | Number of respondents |
| `scope` | string \| null | Geographic scope |
| `source` | string \| null | Original source|
| `institute_id` | integer \| null | Institute ID |
| `institute_name` | string \| null | Institute name |
| `provider_id` | integer \| null | Provider ID |
| `provider_name` | string \| null | Provider name |
| `election_id` | integer \| null | Associated election ID |
| `election_type` | string \| null | Type of election |
| `method_id` | integer \| null | Method ID |
| `method_name` | string \| null | Method name |
| `date_downloaded` | string \| null | When data was retrieved |
| `results` | array | Party results (if include_results=true) |

**Result Object**:

| Field | Type | Description |
|-------|------|-------------|
| `party_id` | integer | Party identifier |
| `party_short_name` | string \| null | Short party name (e.g., "CDU/CSU") |
| `party_name` | string \| null | Full party name |
| `percentage` | number | Support percentage |

## Get Single Poll

```
GET /v1/polls/{poll_id}
```

Retrieve a specific poll by its ID.

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `poll_id` | integer | Yes | - | The poll ID |
| `include_results` | boolean | No | true | Include party results |

### Example Request

```r
poll <- request("https://api.fasttrack29.com/v1/polls/12345") |>
  req_url_query(include_results = TRUE) |>
  req_perform() |>
  resp_body_json()
```

### Example Response

```json
{
  "id": 12345,
  "raw_id": 12344,
  "publish_date": "2024-01-15",
  "survey_date_start": "2024-01-08",
  "survey_date_end": "2024-01-12",
  "respondents": 2501,
  "scope": "federal",
  "source": "wahlrecht.de",
  "institute_id": 1,
  "institute_name": "Forsa",
  "provider_id": 2,
  "provider_name": "Forsa Institute",
  "election_id": 5,
  "election_type": "Bundestagswahl",
  "method_id": 1,
  "method_name": "Telefon",
  "date_downloaded": "2024-01-15T10:30:00",
  "results": [
    {
      "party_id": 1,
      "party_short_name": "CDU/CSU",
      "party_name": "Christlich Demokratische Union/Christlich-Soziale Union",
      "percentage": 31.5
    }
  ]
}
```

## Get Poll Results

```
GET /v1/polls/{poll_id}/results
```

Get party results for a specific poll.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `poll_id` | integer | Yes | The poll ID |

### Example Request

```r
results <- request("https://api.fasttrack29.com/v1/polls/12345/results") |>
  req_perform() |>
  resp_body_json()
```

### Example Response

```json
[
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
```

## Common Use Cases

### Get Latest Polls

```r
# Get the 10 most recent federal polls
latest <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "federal",
    limit = 10
  ) |>
  req_perform() |>
  resp_body_json()
```

### Filter by Institute

```r
# First, get institute ID
institutes <- request("https://api.fasttrack29.com/v1/reference/institutes") |>
  req_perform() |>
  resp_body_json()

# Find Forsa's ID (usually 1)
forsa_id <- 1

# Get Forsa polls from 2024
forsa_polls <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    institute_id = forsa_id,
    date_from = "2024-01-01",
    limit = 100
  ) |>
  req_perform() |>
  resp_body_json()
```

### Date Range Query

```r
library(lubridate)

# Get polls from the last 90 days
start_date <- Sys.Date() - 90

recent_polls <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "federal",
    date_from = as.character(start_date),
    limit = 100
  ) |>
  req_perform() |>
  resp_body_json()
```

### Exclude Results for Faster Queries

If you only need metadata (no party percentages):

```r
metadata_only <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "federal",
    limit = 100,
    include_results = FALSE
  ) |>
  req_perform() |>
  resp_body_json()
```

This is faster and returns less data when you don't need the results.

## See Also

- [Raw Polls](raw-polls.md) — Access original data
- [Results](results.md) — Get results in flattened format
- [Reference Tables](reference-tables.md) — Look up IDs
