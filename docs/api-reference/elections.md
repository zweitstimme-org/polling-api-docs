# Elections Endpoint

Access election summaries and metadata.

## List Election Summaries

```
GET /v1/elections
```

Get all elections with poll counts and latest publish dates.

### Example Request

```r
library(httr2)

elections <- request("https://api.fasttrack29.com/v1/elections") |>
  req_perform() |>
  resp_body_json()
```

### Example Response

```json
[
  {
    "election_id": 1,
    "election_type": "Bundestagswahl",
    "scope": "federal",
    "year": 2021,
    "poll_count": 15432,
    "latest_publish_date": "2024-02-13"
  },
  {
    "election_id": 2,
    "election_type": "Landtagswahl",
    "scope": "bayern",
    "year": 2023,
    "poll_count": 523,
    "latest_publish_date": "2023-10-08"
  },
  {
    "election_id": 3,
    "election_type": "Europawahl",
    "scope": "eu",
    "year": 2024,
    "poll_count": 89,
    "latest_publish_date": "2024-02-13"
  }
]
```

### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `election_id` | integer | Election identifier |
| `election_type` | string | Type of election |
| `scope` | string \| null | Geographic scope |
| `year` | integer \| null | Election year |
| `poll_count` | integer | Number of polls associated |
| `latest_publish_date` | string \| null | Most recent poll publish date |

## Get Single Election Summary

```
GET /v1/elections/{election_id}
```

Get details for a specific election.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `election_id` | integer | Yes | The election ID |

### Example Request

```r
election <- request("https://api.fasttrack29.com/v1/elections/1") |>
  req_perform() |>
  resp_body_json()
```

### Example Response

```json
{
  "election_id": 1,
  "election_type": "Bundestagswahl",
  "scope": "federal",
  "year": 2021,
  "poll_count": 15432,
  "latest_publish_date": "2024-02-13"
}
```

## Common Use Cases

### Find Most Covered Elections

```r
library(httr2)
library(dplyr)

# Get elections sorted by poll count
elections <- request("https://api.fasttrack29.com/v1/elections") |>
  req_perform() |>
  resp_body_json() |>
  bind_rows() |>
  arrange(desc(poll_count))

print(elections)
```

### Find Elections by Scope

```r
# Find all state elections
state_elections <- request("https://api.fasttrack29.com/v1/elections") |>
  req_perform() |>
  resp_body_json() |>
  bind_rows() |>
  filter(election_type == "Landtagswahl")
```

### Check Data Coverage

```r
# See which elections have recent data
current_elections <- request("https://api.fasttrack29.com/v1/elections") |>
  req_perform() |>
  resp_body_json() |>
  bind_rows() |>
  filter(!is.na(latest_publish_date)) |>
  mutate(
    days_since_poll = as.numeric(Sys.Date() - as.Date(latest_publish_date))
  ) |>
  arrange(days_since_poll)
```

### Get Election ID for Filtering

```r
# Find election ID for a specific election
elections <- request("https://api.fasttrack29.com/v1/elections") |>
  req_perform() |>
  resp_body_json() |>
  bind_rows()

bt_2021_id <- elections |>
  filter(election_type == "Bundestagswahl", year == 2021) |>
  pull(election_id)

# Use to filter polls
bt_polls <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(election_id = bt_2021_id) |>
  req_perform() |>
  resp_body_json()
```

## Election Types

Common election types in the database:

| Election Type | Description | Example |
|---------------|-------------|---------|
| `Bundestagswahl` | Federal parliamentary election | Germany-wide |
| `Landtagswahl` | State parliamentary election | Bavaria, NRW, etc. |
| `Europawahl` | European Parliament election | EU-wide |
| `Kommunalwahl` | Local election | Municipal level |

## Scope Values

Common scope values:

| Scope | Description |
|-------|-------------|
| `federal` | Federal Republic of Germany |
| `eu` | European Union |
| `bayern` | Bavaria |
| `nrw` | North Rhine-Westphalia |
| `hessen` | Hesse |
| `bawue` | Baden-Württemberg |

## See Also

- [Polls](polls.md) — Filtering by election_id
- [Reference Tables](reference-tables.md) — Full election details
