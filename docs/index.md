# Zweitstimmeorg Polling API

Welcome to the **Zweitstimmeorg's Polling API** documentation. This API provides comprehensive access to German election polling data.

## What Is this API?

The Zweitstimme Polling API is a **RESTful API** that gives you access to:

- **Cleaned polling data** from most major German polling institutes
- **Raw data** as originally published by aggregators and polling institutes
- **Historical data** spanning multiple federal and state elections
- **Reference information** about institutes, parties, and methods


## Who Is this For?

This documentation is written for **academic researchers** and analysts who:

- Want to work with German polling data programmatically
- Need clean, structured data for statistical analysis
- Use R, Python, or other programming languages

## I Know what I'm doing

In that case: the complete documentation is also available here:
[https://api.fasttrack29.com/docs](https://api.fasttrack29.com/docs)

## Quick Start

```r
library(httr2)

# Get the latest 10 federal polls
request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "federal",
    limit = 10
  ) |>
  req_perform() |>
  resp_body_json()
```

## Key Features

### Clean & Raw Data
Choose between:

- **Cleaned data**: Standardized and normalized for easy analysis
- **Raw data**: Original data as published by polling institutes/ aggregators and intermediates


### Flexible Queries
Filter by:

- Date ranges
- Geographic scope (federal, state, local)
- Polling institute
- Political party
- Survey methodology

### Multiple Formats
Access data via:

- **API endpoints** for programmatic access
- **Bulk downloads** in JSON, CSV, SQLite, or Parquet

### Comprehensive Coverage

- Most major German polling institutes
- Federal elections and state elections EU election data
- Historical data dating back years

## API Endpoints Overview

| Endpoint | Description | 
|----------|-------------|
| `/v1/polls` | List cleaned polls |
| `/v1/raw-polls` | List raw polls |
| `/v1/results` | Get poll results |
| `/v1/reference/*` | Reference tables |
| `/v1/download/*` | Bulk downloads |

## Getting Help

- **[Getting Started Guide](getting-started/introduction.md)** — The basics
- **[Data & Pipeline](data-pipeline/index.md)** — Understanding data sources and structure
- **[API Reference](api-reference/overview.md)** — Detailed endpoint documentation
- **[R Vignette](r-guide/vignette.md)** — R examples

## About Zweitstimmeorg

This API is maintained by [zweitstimme.org](https://zweitstimme.org).

