# Zweitstimme Polling API

Welcome to the **Zweitstimme Polling API** documentation. This API provides comprehensive access to German election polling data, designed specifically for researchers, political scientists, and data analysts.

## What is this API?

The Zweitstimme Polling API is a **RESTful API** that gives you access to:

- **Cleaned polling data** from all major German polling institutes
- **Raw data** as originally published by pollsters
- **Historical data** spanning multiple federal and state elections
- **Reference information** about institutes, parties, and methods

Whether you're studying voting behavior, analyzing pollster accuracy, or tracking party support over time, this API provides the data you need in a structured, accessible format.

## Who is this for?

This documentation is written for **academic researchers** and analysts who:

- Want to work with German polling data programmatically
- Need clean, structured data for statistical analysis
- Use R, Python, or other programming languages
- Are comfortable with basic API concepts (or want to learn!)

No advanced technical knowledge is required—we'll guide you through everything step by step.

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
- **Raw data**: Original data as published by polling institutes

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
- All major German polling institutes (Forsa, INSA, Allensbach, etc.)
- Federal elections and state elections
- Historical data dating back years

## API Endpoints Overview

| Endpoint | Description | Use Case |
|----------|-------------|----------|
| `/v1/polls` | List cleaned polls | General analysis |
| `/v1/raw-polls` | List raw polls | Verify original data |
| `/v1/results` | Get poll results | Party support analysis |
| `/v1/reference/*` | Reference tables | Look up IDs and names |
| `/v1/download/*` | Bulk downloads | Offline analysis |

## Getting Help

- 📖 **[Getting Started Guide](getting-started/introduction.md)** — Learn the basics
- 🔄 **[Data & Pipeline](data-pipeline/index.md)** — Understanding data sources and structure
- 🔧 **[API Reference](api-reference/overview.md)** — Detailed endpoint documentation
- 📊 **[R Vignette](r-guide/vignette.md)** — Practical R examples
- 💡 **[Use Cases](use-cases/time-series.md)** — Real-world analysis examples

## About Zweitstimme

This API is maintained by [zweitstimme.org](https://zweitstimme.org), a project dedicated to providing transparent access to German polling data for research and public discourse.

---

**Ready to start?** Head to the [Getting Started](getting-started/introduction.md) section!
