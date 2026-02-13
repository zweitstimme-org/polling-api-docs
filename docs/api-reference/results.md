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

## Common Use Cases

### Time Series Analysis

```r
library(httr2)
library(dplyr)
library(purrr)
library(ggplot2)

# Get all CDU/CSU results from 2024
cdu_results <- request("https://api.fasttrack29.com/v1/results") |>
  req_url_query(
    scope = "federal",
    party_id = 1,  # CDU/CSU
    date_from = "2024-01-01",
    date_to = "2024-12-31",
    limit = 500
  ) |>
  req_perform() |>
  resp_body_json()

# Convert to data frame
poll_data <- map_dfr(cdu_results$items, function(item) {
  cdu_result <- item$results[[1]]  # First result is CDU/CSU
  tibble(
    date = as.Date(item$publish_date),
    party = cdu_result$party_short_name,
    percentage = cdu_result$percentage
  )
})

# Plot time series
ggplot(poll_data, aes(x = date, y = percentage)) +
  geom_line() +
  geom_point() +
  labs(
    title = "CDU/CSU Support in 2024",
    x = "Date",
    y = "Percentage"
  ) +
  theme_minimal()
```

### Compare Multiple Parties

```r
# Get results for major parties
parties_of_interest <- c(1, 2, 3, 5)  # CDU/CSU, SPD, Grüne, AfD

all_results <- map_dfr(parties_of_interest, function(party_id) {
  response <- request("https://api.fasttrack29.com/v1/results") |>
    req_url_query(
      scope = "federal",
      party_id = party_id,
      date_from = "2024-01-01",
      limit = 100
    ) |>
    req_perform() |>
    resp_body_json()
  
  map_dfr(response$items, function(item) {
    result <- item$results[[1]]
    tibble(
      date = as.Date(item$publish_date),
      party = result$party_short_name,
      percentage = result$percentage
    )
  })
})

# Plot comparison
ggplot(all_results, aes(x = date, y = percentage, color = party)) +
  geom_line() +
  geom_point() +
  labs(
    title = "Party Support Comparison",
    x = "Date",
    y = "Percentage",
    color = "Party"
  ) +
  theme_minimal()
```

### Calculate Party Averages by Institute

```r
library(httr2)
library(dplyr)
library(purrr)

# Get results for all polls in 2024
all_results <- request("https://api.fasttrack29.com/v1/results") |>
  req_url_query(
    scope = "federal",
    date_from = "2024-01-01",
    limit = 500
  ) |>
  req_perform() |>
  resp_body_json()

# Flatten and analyze
analysis_data <- map_dfr(all_results$items, function(item) {
  # Get institute info from reference (or include in query)
  map_dfr(item$results, function(result) {
    tibble(
      poll_id = item$poll_id,
      date = as.Date(item$publish_date),
      institute_id = item$institute_id,
      party = result$party_short_name,
      percentage = result$percentage
    )
  })
})

# Calculate averages by institute
institute_averages <- analysis_data |>
  group_by(institute_id, party) |>
  summarise(
    avg_support = mean(percentage, na.rm = TRUE),
    n_polls = n(),
    .groups = 'drop'
  ) |>
  arrange(desc(avg_support))

print(institute_averages)
```

### Track Specific Party Over Time

```r
# Get SPD results for the last year
library(lubridate)

start_date <- Sys.Date() - 365

spd_results <- request("https://api.fasttrack29.com/v1/results") |>
  req_url_query(
    scope = "federal",
    party_id = 2,  # SPD
    date_from = as.character(start_date),
    limit = 500
  ) |>
  req_perform() |>
  resp_body_json()

# Create trend analysis
spd_data <- map_dfr(spd_results$items, function(item) {
  result <- item$results[[1]]
  tibble(
    date = as.Date(item$publish_date),
    percentage = result$percentage
  )
}) |>
  arrange(date)

# Calculate rolling average
spd_data <- spd_data |>
  mutate(
    rolling_avg = zoo::rollmean(percentage, k = 5, fill = NA, align = "right")
  )

# Plot
ggplot(spd_data, aes(x = date)) +
  geom_point(aes(y = percentage), alpha = 0.5) +
  geom_line(aes(y = rolling_avg), color = "red", size = 1) +
  labs(
    title = "SPD Support - Individual Polls vs 5-Poll Average",
    x = "Date",
    y = "Percentage"
  ) +
  theme_minimal()
```

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
