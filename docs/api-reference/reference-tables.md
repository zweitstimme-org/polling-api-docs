# Reference Tables

Lookup tables for institutes, parties, methods, elections, and other reference data.

## Overview

Reference tables provide the "dictionary" for understanding poll data. Use these endpoints to:

- Look up ID values for filtering
- Get official names and descriptions
- Understand relationships between entities

## List All Reference Data

```
GET /v1/reference/all
```

Get all reference tables in a single request.

### Example Request

```r
library(httr2)

# Get all reference data at once
ref <- request("https://api.fasttrack29.com/v1/reference/all") |>
  req_perform() |>
  resp_body_json()

# Access different tables
names(ref)
# [1] "institutes" "parties" "providers" "methods" "elections" "taskers"
```

### Example Response

```json
{
  "institutes": [
    {
      "id": 1,
      "name": "Forsa",
      "description": "Forsa Institute for Social Research"
    }
  ],
  "parties": [
    {
      "id": 1,
      "name": "Christlich Demokratische Union/Christlich-Soziale Union",
      "short_name": "CDU/CSU",
      "color": "#000000"
    }
  ],
  "providers": [
    {
      "id": 1,
      "name": "Forsa",
      "description": null
    }
  ],
  "methods": [
    {
      "id": 1,
      "name": "Telefon",
      "description": "Telephone interviews"
    }
  ],
  "elections": [
    {
      "id": 1,
      "election_type": "Bundestagswahl",
      "year": 2021,
      "scope": "federal",
      "date": "2021-09-26"
    }
  ],
  "taskers": [
    {
      "id": 1,
      "name": "n-tv/die Welt",
      "type": "media"
    }
  ]
}
```

## Institutes

```
GET /v1/reference/institutes
```

Get all polling institutes.

### Example Request

```r
institutes <- request("https://api.fasttrack29.com/v1/reference/institutes") |>
  req_perform() |>
  resp_body_json()

# Display as table
library(dplyr)
inst_df <- bind_rows(institutes)
print(inst_df)
```

### Example Response

```json
[
  {
    "id": 1,
    "name": "Forsa",
    "description": "Forsa Institute for Social Research and Statistical Analysis"
  },
  {
    "id": 2,
    "name": "INSA",
    "description": "INSA Consult GmbH"
  },
  {
    "id": 3,
    "name": "Allensbach",
    "description": "Institut für Demoskopie Allensbach"
  }
]
```

### Using Institute IDs

```r
# Find Forsa ID
forsa_id <- institutes |>
  bind_rows() |>
  filter(name == "Forsa") |>
  pull(id)

# Use in query
forsa_polls <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(institute_id = forsa_id) |>
  req_perform() |>
  resp_body_json()
```

## Parties

```
GET /v1/reference/parties
```

Get all political parties.

### Example Request

```r
parties <- request("https://api.fasttrack29.com/v1/reference/parties") |>
  req_perform() |>
  resp_body_json()
```

### Example Response

```json
[
  {
    "id": 1,
    "name": "Christlich Demokratische Union/Christlich-Soziale Union",
    "short_name": "CDU/CSU",
    "color": "#000000"
  },
  {
    "id": 2,
    "name": "Sozialdemokratische Partei Deutschlands",
    "short_name": "SPD",
    "color": "#E3000F"
  },
  {
    "id": 3,
    "name": "Bündnis 90/Die Grünen",
    "short_name": "Grüne",
    "color": "#1AA024"
  },
  {
    "id": 4,
    "name": "Freie Demokratische Partei",
    "short_name": "FDP",
    "color": "#FFE300"
  },
  {
    "id": 5,
    "name": "Alternative für Deutschland",
    "short_name": "AfD",
    "color": "#0489DB"
  },
  {
    "id": 6,
    "name": "Die Linke",
    "short_name": "Linke",
    "color": "#BE3075"
  }
]
```

### Using Party Colors

```r
library(dplyr)
library(ggplot2)

# Create color mapping
party_colors <- parties |>
  bind_rows() |>
  select(short_name, color) |>
  deframe()

# Use in plot
ggplot(data, aes(x = date, y = percentage, color = party)) +
  geom_line() +
  scale_color_manual(values = party_colors)
```

## Providers

```
GET /v1/reference/providers
```

Get all data providers (often same as institutes, but can differ).

### Example Response

```json
[
  {
    "id": 1,
    "name": "Forsa",
    "description": null
  },
  {
    "id": 2,
    "name": "INSA",
    "description": null
  }
]
```

## Methods

```
GET /v1/reference/methods
```

Get all survey methodologies.

### Example Response

```json
[
  {
    "id": 1,
    "name": "Telefon",
    "description": "Telephone interviews"
  },
  {
    "id": 2,
    "name": "Online",
    "description": "Online survey"
  },
  {
    "id": 3,
    "name": "Tel+Online",
    "description": "Mixed mode: telephone and online"
  }
]
```

## Elections

```
GET /v1/reference/elections
```

Get all elections.

### Example Response

```json
[
  {
    "id": 1,
    "election_type": "Bundestagswahl",
    "year": 2021,
    "scope": "federal",
    "date": "2021-09-26"
  },
  {
    "id": 2,
    "election_type": "Europawahl",
    "year": 2024,
    "scope": "eu",
    "date": "2024-06-09"
  },
  {
    "id": 3,
    "election_type": "Landtagswahl",
    "year": 2023,
    "scope": "bayern",
    "date": "2023-10-08"
  }
]
```

### Finding Election IDs

```r
# Find Bundestagswahl 2021
elections <- request("https://api.fasttrack29.com/v1/reference/elections") |>
  req_perform() |>
  resp_body_json()

bt_2021 <- elections |>
  bind_rows() |>
  filter(election_type == "Bundestagswahl", year == 2021)

bt_2021_id <- bt_2021$id
```

## Taskers

```
GET /v1/reference/taskers
```

Get all taskers (media outlets that commission polls).

### Example Response

```json
[
  {
    "id": 1,
    "name": "n-tv/die Welt",
    "type": "media"
  },
  {
    "id": 2,
    "name": "Bild",
    "type": "media"
  }
]
```

## Common Use Cases

### Build Lookup Tables

```r
library(httr2)
library(dplyr)

# Get all reference data
ref <- request("https://api.fasttrack29.com/v1/reference/all") |>
  req_perform() |>
  resp_body_json()

# Create lookup functions
get_institute_name <- function(id) {
  ref$institutes |>
    bind_rows() |>
    filter(id == !!id) |>
    pull(name)
}

get_party_color <- function(id) {
  ref$parties |>
    bind_rows() |>
    filter(id == !!id) |>
    pull(color)
}

# Use lookups
get_institute_name(1)  # Returns: "Forsa"
get_party_color(1)     # Returns: "#000000"
```

### Create ID Mappings

```r
# Create mappings for easy reference
institute_map <- ref$institutes |>
  bind_rows() |>
  select(id, name) |>
  deframe()

party_map <- ref$parties |>
  bind_rows() |>
  select(id, short_name) |>
  deframe()

# Use in analysis
institute_map["1"]  # Returns: "Forsa"
party_map["1"]      # Returns: "CDU/CSU"
```

### Validate Filter Values

```r
# Check if scope is valid before querying
valid_scopes <- ref$elections |>
  bind_rows() |>
  pull(scope) |>
  unique()

my_scope <- "federal"
if (my_scope %in% valid_scopes) {
  # Proceed with query
  polls <- request("https://api.fasttrack29.com/v1/polls") |>
    req_url_query(scope = my_scope) |>
    req_perform()
} else {
  stop("Invalid scope. Valid options: ", paste(valid_scopes, collapse = ", "))
}
```

## Data Dictionary

Quick reference for all reference tables:

| Table | Fields | Use For |
|-------|--------|---------|
| **Institutes** | id, name, description | Filtering by pollster |
| **Parties** | id, name, short_name, color | Party identification, visualization |
| **Providers** | id, name, description | Data source tracking |
| **Methods** | id, name, description | Methodology analysis |
| **Elections** | id, election_type, year, scope, date | Election-specific queries |
| **Taskers** | id, name, type | Media commissioning analysis |

## Caching Reference Data

Since reference data changes infrequently, cache it locally:

```r
# Save reference data
ref <- request("https://api.fasttrack29.com/v1/reference/all") |>
  req_perform() |>
  resp_body_json()

saveRDS(ref, "reference_data.rds")

# Load cached data
ref <- readRDS("reference_data.rds")
```

## See Also

- [Polls](polls.md) — Using reference IDs in queries
- [Results](results.md) — Filtering by party_id
- [Data Model](../getting-started/data-model.md) — Understanding relationships
