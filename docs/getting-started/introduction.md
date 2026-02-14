# Introduction

This guide will help you understand and use the Zweitstimme Polling API, even if you've never worked with APIs before.

## Why Use This API?

If you're researching German elections, you might be used to:

- Manually copying data from PDFs
- Cleaning messy Excel files
- Combining data from different sources

**This API automates all of that.** Instead of hours of manual work, you can get clean, structured data with a few lines of code.

## What Data is Available?

### Polls
Individual polling results with metadata:

- Which institute conducted the poll
- When it was published
- How many people were surveyed
- Party support percentages

### Cleaned vs Raw Data

**Cleaned Data** (`/v1/polls`):

- Standardized party names
- Normalized dates
- Consistent institute naming
- Ready for analysis

**Raw Data** (`/v1/raw-polls`):

- Original data as published
- Useful for verification
- Includes additional metadata

### Reference Tables

Lookup tables to understand the data:

- **Institutes**: Polling organizations (Forsa, INSA, etc.)
- **Parties**: Political parties with official names and colors
- **Methods**: Survey methodologies (phone, online, etc.)
- **Elections**: Election dates and scopes

## How Do I Access It?

You can access the API using any programming language. This documentation focuses on **R**.

### In R

```r
library(httr2)

# Simple request
request("https://api.fasttrack29.com/v1/polls") |>
  req_perform() |>
  resp_body_json()
```

### In Python

```python
import requests

response = requests.get("https://api.fasttrack29.com/v1/polls")
data = response.json()
```

### In Your Browser

You can also test endpoints directly in your browser:
```
https://api.fasttrack29.com/v1/polls?limit=5
```

## Understanding the Response

API responses come in **JSON format**, which looks like this:

```json
{
  "items": [
    {
      "id": 12345,
      "publish_date": "2024-01-15",
      "institute_name": "Forsa",
      "results": [
        {"party_short_name": "CDU/CSU", "percentage": 31.5},
        {"party_short_name": "SPD", "percentage": 16.0}
      ]
    }
  ],
  "meta": {
    "total": 15432,
    "limit": 100,
    "offset": 0
  }
}
```

## Next Steps

1. **[Your First Request](first-request.md)** — Make your first API call
2. **[Understanding the Data](data-model.md)** — Learn about the data structure
3. **[Data & Pipeline](../data-pipeline/index.md)** — Understand data sources and processing
4. **[API Reference](../api-reference/overview.md)** — Explore all endpoints

## Q and A

**Do I need an API key?**
No! The API is currently open and doesn't require authentication.

**Is it free?**
Yes, the API is free for academic and research use.

**Can I download all data at once?**
Yes! Use the `/v1/download` endpoints for bulk downloads in various formats.

