# Data Pipeline

This document explains how polling data flows through the polling-api system, from raw sources to clean, queryable data via the API.

## Overview

The data pipeline consists of three main stages:

1. **Data Collection (Scrapers)** — Pull data from external sources
2. **Data Processing (Cleaner/ETL)** — Transform and normalize raw data
3. **Data Storage (Database)** — Store clean data for API access

```
┌─────────────────┐     ┌──────────────┐     ┌─────────────┐
│ External        │────▶│ Scrapers     │────▶│ Raw Data    │
│ Sources         │     │ (Collection) │     │ (polls_raw) │
└─────────────────┘     └──────────────┘     └──────┬──────┘
                                                    │
                           ┌──────────────┐        │
                           │ Cleaner/ETL  │◀───────┘
                           │ (Processing) │
                           └──────┬───────┘
                                  │
                                  ▼
                           ┌──────────────┐
                           │ Clean Data   │
                           │ (polls)      │
                           └──────────────┘
```

---

## Stage 1: Data Collection (Scrapers)

### Data Sources

The system collects polling data from multiple German polling aggregators and APIs:

#### 1. Wahlrecht.de

**What it is**: The most comprehensive aggregator of German election polls

**Coverage**:

- Federal elections (Bundestagswahl)
- State elections (Landtagswahlen) for all 16 states
- European Parliament elections

**Data points collected**:

- Institute name (e.g., Forsa, INSA, Forschungsgruppe Wahlen)
- Publication date
- Survey period 
- Number of respondents
- Method (phone, online, mixed)


#### 2. DAWUM API

**What it is**: Structured API providing polling data with consistent formatting

**Coverage**: Most major German polls with standardized fields

**Data points collected**:

- Institute details
- Survey dates
- Party results
- Method information
- Parliament type

#### 3. Manual Sources

Special cases requiring manual data entry or custom parsing for sources not covered by automated scrapers.

### Scraper Architecture

Each scraper follows a consistent pattern:

```
1. Select URLs to process
2. Fetch HTML/data from source
3. Parse into structured format
4. Validate against schema
5. Check for duplicates
6. Store in polls_raw table
```
---

## Stage 2: Data Processing (Cleaner/ETL)

The ETL (Extract, Transform, Load) pipeline processes raw data into a clean, normalized format.

### The Problem with Raw Data

Raw data from different sources has inconsistencies:

| Issue | Example |
|-------|---------|
| Date formats | "24.06.2024", "2024-06-24", "24.06.-26.06.2024" |
| Institute names | "Forsa", "Forsa GmbH", "forsa" |
| Party names | "CDU/CSU", "Union", "CDU" |
| Respondent counts | "1005", "ca. 1000", "n=1005" |
| Missing fields | Some sources don't provide method or respondents |

### ETL Pipeline Steps

```
Raw Poll (polls_raw)
    │
    ▼
┌─────────────────────┐
│ 1. Date Parsing     │
│    - Parse publish  │
│      date           │
│    - Parse survey   │
│      date range     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 2. Respondent       │
│    Extraction       │
│    - Extract count  │
│    - Identify       │
│      method hints   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 3. Entity Mapping   │
│    - Map institute  │
│    - Map provider   │
│    - Map method     │
│    - Map election   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 4. Party Parsing    │
│    - Parse JSON     │
│    - Map parties    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 5. Duplicate Check  │
│    - Check if poll  │
│      already exists │
└──────────┬──────────┘
           │
           ▼
Clean Poll (polls) + Results (poll_results)
```

### Step-by-Step Transformation

#### 1. Date Normalization

**Input**: Raw date strings in various formats
**Output**: Standardized ISO dates (YYYY-MM-DD)

Examples:
- `"24.06.2024"` → `2024-06-24`
- `"24.06.-26.06.2024"` → `survey_date_start: 2024-06-24`, `survey_date_end: 2024-06-26`
- `"01.–05.03.2024"` → `survey_date_start: 2024-03-01`, `survey_date_end: 2024-03-05`

#### 2. Respondent Parsing

**Input**: Strings like `"1005"`, `"ca. 1000"`, `"n=1005"`, `"O • 1005"`
**Output**: Integer count + optional method hint

Special prefixes:
- `"O •"` = Online survey
- `"TOM •"` = Telefon + Online + Mixed
- `"T •"` = Telephone survey

#### 3. Entity Mapping

Maps text names to canonical IDs using JSON reference files:

**Institutes**:
```
"Forsa" → ID 1
"INSA" → ID 2
"Forschungsgruppe Wahlen" → ID 3
```

**Parties**:
```
"CDU/CSU", "Union", "CDU" → ID 1
"SPD" → ID 2
"Grüne", "BÜNDNIS 90/DIE GRÜNEN" → ID 4
```

**Methods**:
```
"Online" → ID 1
"Telefon" → ID 2
"Telefon & Online" → ID 4
```

**Elections**:
```
Scope "federal" → Bundestagswahl
Scope "bayern" → Bayern Landtagswahl
Scope "nrw" → Nordrhein-Westfalen Landtagswahl
```

#### 4. Party Result Parsing

**Input**: JSON string with party percentages
```json
{"CDU/CSU": "32", "SPD": "18", "Grüne": "15", ...}
```

**Output**: Normalized party IDs with float percentages
```
party_id: 1, percentage: 32.0  (CDU/CSU)
party_id: 2, percentage: 18.0  (SPD)
party_id: 4, percentage: 15.0  (Grüne)
```

#### 5. Deduplication

Checks if a poll with the same:
- Publish date
- Institute
- Scope
- Provider

already exists. If yes, updates; if no, creates new.

### Running the Cleaner

```bash
# Run cleaning pipeline on all unprocessed raw polls
pollingapi pipeline:clean

# Check what would be processed (inspect specific raw poll)
pollingapi pipeline:inspect 1234

# Run full pipeline (scrape + clean)
pollingapi pipeline:run
```

---

## Stage 3: Data Storage

### Two-Table System

The database uses a **two-table approach** for data integrity:

#### Raw Data Table (`polls_raw`)

- **Purpose**: Immutable storage of original scraped data
- **Characteristics**: 
  - Never modified after insertion
  - Preserves original formatting
  - Acts as audit trail
  - All fields stored as strings (flexible)

#### Clean Data Table (`polls`)

- **Purpose**: Normalized, queryable data
- **Characteristics**:
  - Standardized formats
  - Foreign key relationships
  - Proper data types (dates, integers, floats)
  - Optimized for API queries

### Data Flow Example

**Raw Data (polls_raw)**:
```
id: 15420
publish_date: "24.06.2024"
institute_id: "forsa"
provider: "Wahlrecht.de"
scope: "federal"
parties: '{"CDU/CSU": "32", "SPD": "18", ...}'
respondents: "O • 1005"
zeitraum: "18.06.-24.06.2024"
```

**Clean Data (polls)**:
```
id: 8923
raw_id: 15420
publish_date: 2024-06-24
institute_id: 1 (Forsa)
provider_id: 1 (Wahlrecht.de)
election_id: 1 (Bundestagswahl)
scope: "federal"
respondents: 1005
method_id: 1 (Online)
survey_date_start: 2024-06-18
survey_date_end: 2024-06-24
```

**Results (poll_results)**:
```
poll_id: 8923, party_id: 1, percentage: 32.0
poll_id: 8923, party_id: 2, percentage: 18.0
poll_id: 8923, party_id: 4, percentage: 15.0
...
```

---

## Data Quality

### Validation Checks

1. **Schema Validation**: All scraped data must match expected structure
2. **Range Checks**: Percentages must be 0-100
3. **Date Validation**: Dates must be parseable and logical
4. **Referential Integrity**: Foreign keys must exist in reference tables
5. **Duplicate Detection**: Prevents identical polls

### Monitoring

```bash
# Check table counts
pollingapi db:tables

# View cleaning statistics
pollingapi pipeline:clean --limit 100
```

## API Access

Once data is cleaned and stored, it's available through the API:

- **Cleaned polls**: `/v1/polls` — Standardized, queryable data
- **Raw polls**: `/v1/raw-polls` — Original data for verification
- **Results**: `/v1/results` — Flattened party results
- **Reference**: `/v1/reference/*` — Lookup tables

See the [API Reference](../api-reference/overview.md) for details.

---

## Summary

| Stage | What Happens | Output |
|-------|--------------|--------|
| **Collection** | Scrapers fetch from sources | Raw data in `polls_raw` |
| **Processing** | ETL normalizes and cleans | Clean data in `polls` |
| **Storage** | Database stores both versions | Queryable via API |

This three-stage approach ensures:
- ✅ **Transparency**: Raw data preserved for verification
- ✅ **Quality**: Cleaning catches errors and inconsistencies
- ✅ **Flexibility**: Can re-process if rules change
- ✅ **Auditability**: Full history of data transformations
