# Understanding the Data Model

To use the API effectively, you need to understand how the data is organized. This guide provides a high-level overview. For detailed technical information, see the [Data & Pipeline](../data-pipeline/index.md) section.

## Overview

The API provides polling data at different levels of processing:

```
┌─────────────────────────────────────────────────────┐
│                    API Structure                    │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────┐      ┌──────────────┐             │
│  │ Cleaned Data │      │   Raw Data   │             │
│  │  /v1/polls   │      │ /v1/raw-polls│             │
│  └──────┬───────┘      └──────┬───────┘             │
│         │                     │                     │
│         └──────────┬──────────┘                     │
│                    │                                │
│         ┌──────────▼──────────┐                     │
│         │   Reference Tables  │                     │
│         │ /v1/reference/*     │                     │
│         └─────────────────────┘                     │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## Cleaned Vs Raw Data

### Cleaned Data (`/v1/polls`)

**Purpose**: Ready-to-analyze polling data

**Characteristics**:

- Standardized party names (e.g., always "CDU/CSU", never "Union")
- Consistent date formats (ISO 8601)
- Normalized institute names
- Resolved foreign keys (institute_id → institute_name)


### Raw Data (`/v1/raw-polls`)

**Purpose**: Original data as scraped from sources

**Characteristics**:

- Original text and formatting
- Extra metadata not in cleaned data
- Unprocessed dates (might be ranges like "12-18 Jan")
- Original party abbreviations


## The Poll Object

Each poll contains:

### Metadata

| Field | Description | Example |
|-------|-------------|---------|
| `id` | Unique identifier | 12345 |
| `publish_date` | Publication date | "2024-01-15" |
| `survey_date_start` | Survey start | "2024-01-08" |
| `survey_date_end` | Survey end | "2024-01-12" |
| `respondents` | Sample size | 2501 |
| `institute_name` | Who conducted it | "Forsa" |
| `scope` | Geographic level | "federal", "bayern" |
| `methods`| Method used for the survey| "telefon"|

### Results

Party support percentages:

```json
{
  "results": [
    {
      "party_short_name": "CDU/CSU",
      "percentage": 31.5
    },
    {
      "party_short_name": "SPD",
      "percentage": 16.0
    }
  ]
}
```

## Reference Tables

Reference tables act as dictionaries:

- **Institutes**: Who conducted the polls (Forsa → ID 1)
- **Parties**: Political parties with names in short & long and their ID
- **Methods**: Survey methodologies
- **Elections**: Types of elections covered

These help you filter and understand the data without memorizing IDs.

## Relationships

The tables connect through IDs:

```
Poll Table                 Reference Tables
    ├── id: 12345
    ├── institute_id: 1 ───────▶ institutes.id: 1 → "Forsa"
    ├── election_id: 5 ────────▶ elections.id: 5 → "Bundestagswahl 2021"
    └── results:               
        ├── party_id: 1 ───────▶ parties.id: 1 → "CDU/CSU"
        └── party_id: 2 ───────▶ parties.id: 2 → "SPD"
```

## Scopes Explained

| Scope | Description | Example Use Case |
|-------|-------------|------------------|
| `federal` | Federal Republic of Germany | National polls |
| `bayern` | Bavaria | State elections |
| `nrw` | North Rhine-Westphalia | State elections |
| `eu` | European Union | EU Parliament polls |


## For More Detail

This was a high-level overview. For comprehensive documentation on:

- **Data sources and processing** → See [Data Pipeline](../data-pipeline/pipeline.md)
- **Complete database schema** → See [Database Schema](../data-pipeline/schema.md)
- **API endpoints** → See [API Reference](../api-reference/overview.md)

## Next Steps

- **[Your First Request](first-request.md)** — Make your first API call
- **[API Reference](../api-reference/overview.md)** — Detailed endpoint documentation
- **[R Vignette](../r-guide/vignette.md)** — Practical analysis examples
- **[Data & Pipeline](../data-pipeline/index.md)** — Understanding data sources and structure
