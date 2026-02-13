# Raw Polls Endpoint

Access original polling data as scraped from sources, before any cleaning or normalization.

## When to Use Raw Polls

Raw polls are useful for:

- **Verification**: Check the original data against cleaned results
- **Debugging**: Understand data quality issues
- **Additional metadata**: Access fields not in cleaned data
- **Research**: Study how pollsters present their data

## List Raw Polls

```
GET /v1/raw-polls
```

Retrieve raw poll data with optional filtering.

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `limit` | integer | No | 100 | Max rows to return (1-1000) |
| `offset` | integer | No | 0 | Rows to skip |
| `source` | string | No | - | Filter by source |
| `scope` | string | No | - | Filter by scope |
| `provider` | string | No | - | Filter by provider name |

### Example Request

```r
library(httr2)

# Get raw polls from specific source
raw_polls <- request("https://api.fasttrack29.com/v1/raw-polls") |>
  req_url_query(
    source = "wahlrecht.de",
    limit = 10
  ) |>
  req_perform() |>
  resp_body_json()
```

### Example Response

```json
{
  "items": [
    {
      "id": 12344,
      "publish_date": "15.01.2024",
      "survey_date_start": null,
      "survey_date_end": null,
      "respondents": "2.501",
      "zeitraum": "8.-12. Januar 2024",
      "parties": "Union 31,5 %, SPD 16 %, Grüne 14 %, FDP 5 %, AfD 20 %, Linke 4 %, Sonstige 9,5 %",
      "institute_id": "forsa",
      "provider": "Forsa",
      "tasker": "n-tv/die Welt",
      "source": "https://wahlrecht.de",
      "scope": "federal",
      "election_id": "5",
      "method_id": "1",
      "date_downloaded": "2024-01-15T10:30:00"
    }
  ],
  "meta": {
    "total": 25000,
    "limit": 10,
    "offset": 0
  }
}
```

### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Unique raw poll identifier |
| `publish_date` | string \| null | Publication date (original format) |
| `survey_date_start` | string \| null | Survey start date |
| `survey_date_end` | string \| null | Survey end date |
| `respondents` | string \| null | Number of respondents (as text) |
| `zeitraum` | string \| null | Survey period in German (e.g., "8.-12. Januar 2024") |
| `parties` | string \| null | Raw party results text |
| `institute_id` | string \| null | Institute identifier (original format) |
| `provider` | string \| null | Provider name (original format) |
| `tasker` | string \| null | Media outlet that commissioned poll |
| `source` | string \| null | Source URL |
| `scope` | string \| null | Geographic scope |
| `election_id` | string \| null | Associated election ID |
| `method_id` | string \| null | Method identifier |
| `date_downloaded` | string \| null | When data was retrieved |

### Key Differences from Cleaned Data

| Aspect | Cleaned | Raw |
|--------|---------|-----|
| Dates | Standardized (YYYY-MM-DD) | Original format (varies) |
| Numbers | Numeric | Often strings (e.g., "2.501") |
| Party names | Standardized | As published |
| Institute names | Standardized | As published |
| Results | Structured JSON | Free text |

## Get Single Raw Poll

```
GET /v1/raw-polls/{raw_id}
```

Retrieve a specific raw poll by its ID.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `raw_id` | integer | Yes | The raw poll ID |

### Example Request

```r
raw_poll <- request("https://api.fasttrack29.com/v1/raw-polls/12344") |>
  req_perform() |>
  resp_body_json()
```

## Get Latest Raw Polls

```
GET /v1/raw-polls/latest/100
```

Get the 100 most recently added raw polls. This is useful for checking the latest data imports.

### Example Request

```r
latest_raw <- request("https://api.fasttrack29.com/v1/raw-polls/latest/100") |>
  req_perform() |>
  resp_body_json()
```

### Example Response

```json
[
  {
    "id": 25001,
    "publish_date": "13.02.2024",
    "zeitraum": "5.-9. Februar 2024",
    "parties": "Union 31 %, SPD 15 %, Grüne 14 %, FDP 5 %, AfD 21 %, Linke 4 %, Sonstige 10 %",
    "institute_id": "forsa",
    "provider": "Forsa",
    "tasker": "n-tv/die Welt",
    "source": "https://wahlrecht.de"
  },
  {
    "id": 25000,
    "publish_date": "12.02.2024",
    "zeitraum": "5.-8. Februar 2024",
    "parties": "Union 30 %, SPD 16 %, Grüne 15 %, FDP 4 %, AfD 22 %, Linke 3 %, Sonstige 10 %",
    "institute_id": "insa",
    "provider": "INSA",
    "tasker": "Bild",
    "source": "https://wahlrecht.de"
  }
]
```

## Common Use Cases

### Verify Cleaned Data

```r
# Get a cleaned poll
cleaned <- request("https://api.fasttrack29.com/v1/polls/12345") |>
  req_perform() |>
  resp_body_json()

# Get the corresponding raw poll
raw <- request(paste0("https://api.fasttrack29.com/v1/raw-polls/", cleaned$raw_id)) |>
  req_perform() |>
  resp_body_json()

# Compare
cat("Cleaned:", cleaned$publish_date, "\n")
cat("Raw:", raw$publish_date, "\n")
cat("Cleaned:", cleaned$institute_name, "\n")
cat("Raw:", raw$provider, "\n")
```

### Find Original Source

```r
# Get raw poll to find original URL
raw <- request("https://api.fasttrack29.com/v1/raw-polls/12344") |>
  req_perform() |>
  resp_body_json()

# Open in browser (RStudio)
rstudioapi::viewer(raw$source)
```

### Check Data Quality

```r
# Get recent raw polls
raw_polls <- request("https://api.fasttrack29.com/v1/raw-polls") |>
  req_url_query(limit = 100) |>
  req_perform() |>
  resp_body_json()

# Check for missing fields
missing_dates <- sapply(raw_polls$items, function(p) is.null(p$publish_date))
cat("Polls missing dates:", sum(missing_dates), "\n")

# Check date formats
unique_formats <- unique(sapply(raw_polls$items, function(p) {
  if (!is.null(p$publish_date)) {
    nchar(p$publish_date)
  } else {
    NA
  }
}))
cat("Date length variations:", paste(unique_formats, collapse = ", "), "\n")
```

### Extract Original Text

```r
# Get raw poll with German period description
raw <- request("https://api.fasttrack29.com/v1/raw-polls/12344") |>
  req_perform() |>
  resp_body_json()

# Access original text
cat("Survey period:", raw$zeitraum, "\n")
cat("Raw results:", raw$parties, "\n")
cat("Commissioned by:", raw$tasker, "\n")
```

## Relationship to Cleaned Data

Each cleaned poll references its raw source:

```
┌─────────────────┐         ┌─────────────────┐
│  Cleaned Poll   │         │   Raw Poll      │
│    (id: 100)    │────────▶│   (id: 99)      │
│  raw_id: 99     │         │                 │
└─────────────────┘         └─────────────────┘
```

You can always trace back from cleaned to raw using the `raw_id` field.

## Pagination Notes

Raw polls endpoint supports larger `limit` values (up to 1000) compared to cleaned polls (500), since raw data is often needed in bulk for verification purposes.

## See Also

- [Polls](polls.md) — Cleaned, standardized data
- [Data Model](../getting-started/data-model.md) — Understanding the structure
