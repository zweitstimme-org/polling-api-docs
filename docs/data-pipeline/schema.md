# Database Schema

## The Big Picture

Think of the database like a well-organized filing system. Instead of one giant pile of papers, we have **separate filing cabinets** (tables) for different types of information, with **index cards** (relationships) showing how they connect.

```
┌─────────────────────────────────────────────────────────────┐
│                     DATABASE STRUCTURE                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Reference Tables (The "Dictionaries")                      │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐      │
│  │Institutes│ │ Parties  │ │Elections │ │ Methods  │      │
│  │(Who)     │ │(Whom)    │ │(What)    │ │(How)     │      │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘      │
│       │            │            │            │             │
│       └────────────┴────────────┴────────────┘             │
│                    │                                       │
│                    ▼                                       │
│  Main Tables (The "Data")                                  │
│  ┌──────────────────────────────┐                          │
│  │         Polls                │                          │
│  │  (The actual surveys)        │                          │
│  └──────────────┬───────────────┘                          │
│                 │                                          │
│                 ▼                                          │
│  ┌──────────────────────────────┐                          │
│  │      Poll Results            │                          │
│  │  (Party percentages)         │                          │
│  └──────────────────────────────┘                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Cleaned vs Raw Data

Before diving into the schema, it's important to understand that the database stores data at two levels:

### Cleaned Data

**Purpose**: Ready-to-analyze polling data

**Characteristics**:

- Standardized party names (e.g., always "CDU/CSU", never "Union")
- Consistent date formats (ISO 8601)
- Normalized institute names
- Resolved foreign keys (institute_id → institute_name)

**Stored in**: `polls` table and `poll_results` table

### Raw Data

**Purpose**: Original data as published by sources

**Characteristics**:

- Original text and formatting
- Extra metadata not in cleaned data
- Original party abbreviations


**Stored in**: `polls_raw` table

---

## Reference Tables (The Dictionaries)

These tables are like dictionaries or lookup tables. They define the "vocabulary" used in the main data.

### 1. Institutes (Who conducted the poll?)

**What it contains**: List of polling organizations

| Field | Description | Example |
|-------|-------------|---------|
| `id` | Unique number | 1, 2, 3... |
| `name` | Institute name | "Forsa", "INSA", "Forschungsgruppe Wahlen" |


**API Access**: `GET /v1/reference/institutes`

### 2. Parties (Whom was polled?)

**What it contains**: Political parties and their standard identifiers

| Field | Description | Example |
|-------|-------------|---------|
| `id` | Unique number | 1, 2, 4, 5... |
| `name` | Full party name | "Christlich Demokratische Union Deutschlands" |


**API Access**: `GET /v1/reference/parties`

### 3. Elections (What was being polled?)

**What it contains**: Types of elections and their details

| Field | Description | Example |
|-------|-------------|---------|
| `id` | Unique number | 1, 2, 10... |
| `election_type` | What kind | "Bundestagswahl", "Landtagswahl" |
| `year` | Election year | 2025, 2024 |
| `scope` | Geographic scope | "federal", "bayern", "nrw" |
| `date` | Election date | 2025-02-23 |

**API Access**: `GET /v1/reference/elections` and `GET /v1/elections`

### 4. Methods (How was it conducted?)

**What it contains**: Survey methodologies

| Field | Description | Example |
|-------|-------------|---------|
| `id` | Unique number | 1, 2, 4... |
| `name` | Method name | "Online", "Telefon", "Telefon & Online" |
| `description` | Details | "Online survey via panel" |

**API Access**: `GET /v1/reference/methods`

### 5. Providers (Where did we get the data?)

**What it contains**: Data aggregators and sources

| Field | Description | Example |
|-------|-------------|---------|
| `id` | Unique number | 1, 2... |
| `name` | Source name | "Wahlrecht.de", "DAWUM" |
| `description` | Details | "Polling aggregator website" |

**API Access**: `GET /v1/reference/providers`

---

## Main Tables (The Actual Data)

### Polls (The Survey Records)

**What it contains**: Each row represents one published poll/survey


| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `id` | integer | Unique poll ID | 8923 |
| `raw_id` | integer | Link to raw data | 15420 |
| `publish_date` | date | When published | 2024-06-24 |
| `survey_date_start` | date | Survey start | 2024-06-18 |
| `survey_date_end` | date | Survey end | 2024-06-24 |
| `respondents` | integer | Sample size | 1005 |
| `institute_id` | integer | Who conducted it | 1 (Forsa) |
| `provider_id` | integer | Where we got it | 1 (Wahlrecht.de) |
| `election_id` | integer | What election | 1 (Bundestagswahl) |
| `method_id` | integer | How conducted | 1 (Online) |
| `scope` | text | Geographic area | "federal", "bayern" |
| `source` | text | Original URL | "https://wahlrecht.de/..." |

**Key Relationships**:
- `institute_id` → links to **Institutes** table
- `provider_id` → links to **Providers** table
- `election_id` → links to **Elections** table
- `method_id` → links to **Methods** table
- `raw_id` → links to **polls_raw** table

**API Access**: `GET /v1/polls` and `GET /v1/polls/{id}`

### Poll Results (The Party Percentages)

**What it contains**: Each row represents one party's result in one poll


| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `id` | integer | Unique result ID | 15420 |
| `poll_id` | integer | Which poll | 8923 |
| `party_id` | integer | Which party | 1 (CDU/CSU) |
| `percentage` | decimal | Result | 32.0 |

**Key Relationships**:
- `poll_id` → links to **Polls** table
- `party_id` → links to **Parties** table


**API Access**: Results are included in poll responses (`include_results=true`) or via `GET /v1/polls/{id}/results`

### Raw Polls (Original Data)

**What it contains**: Original scraped data, preserved exactly as received

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `id` | integer | Unique raw ID | 15420 |
| `publish_date` | text | Original date string | "24.06.2024" |
| `survey_date_start` | text | Original start date | "18.06.2024" |
| `survey_date_end` | text | Original end date | "24.06.2024" |
| `respondents` | text | Original respondent string | "O • 1005" |
| `zeitraum` | text | Survey period in German | "18.06.-24.06.2024" |
| `parties` | text | Raw party results JSON | '{"CDU/CSU": "32", ...}' |
| `institute_id` | text | Original institute name | "forsa" |
| `provider` | text | Original provider name | "Wahlrecht.de" |
| `scope` | text | Geographic scope | "federal" |
| `source` | text | Source URL | "https://wahlrecht.de/..." |

**API Access**: `GET /v1/raw-polls` and `GET /v1/raw-polls/{id}`

---

## How Tables Connect (Relationships)

### Visual Diagram

```
┌──────────────────┐         ┌──────────────────┐
│    Institutes    │         │     Parties      │
│    (Who)         │         │    (Whom)        │
│  ┌──────────┐    │         │  ┌──────────┐    │
│  │ id: 1    │    │         │  │ id: 1    │    │
│  │ Forsa    │    │         │  │ CDU/CSU  │    │
│  └──────────┘    │         │  └──────────┘    │
│        ▲         │         │        ▲         │
└────────┼─────────┘         └────────┼─────────┘
         │                            │
         │         ┌──────────────────┴──────────────────┐
         │         │            Polls                    │
         │         │  ┌──────────────────────────────┐   │
         │         │  │ id: 8923                     │   │
         │         │  │ institute_id: 1 ─────────────┼───┘
         │         │  │ (conducted by Forsa)         │
         │         │  └──────────────────────────────┘   │
         │         │                 │                   │
         │         └─────────────────┼───────────────────┘
         │                           │
         │         ┌─────────────────┴───────────────────┐
         │         │         Poll Results                │
         │         │  ┌──────────────────────────────┐   │
         │         │  │ id: 15420                    │   │
         │         │  │ poll_id: 8923 ───────────────┼───┘
         │         │  │ party_id: 1 ───────────────┐ │
         │         │  │ percentage: 32.0           │ │
         └─────────┼──┼────────────────────────────┘ │
                   │  └──────────────────────────────┘
                   │
         ┌─────────┴──────────┐
         │      Parties       │
         │  ┌──────────────┐  │
         └──┤ id: 1        │  │
            │ CDU/CSU      │  │
            └──────────────┘  │
            └─────────────────┘
```

---

## Data Quality Notes

### What You Can Rely On

- ✅ **Poll dates**: All dates are standardized to YYYY-MM-DD format
- ✅ **Party percentages**: Stored as decimals (32.0 = 32%)
- ✅ **Relationships**: Foreign keys are validated (no broken links)
- ✅ **Deduplication**: Duplicate polls are prevented

### What to Watch Out For

⚠️ **Missing data**: Some fields can be NULL (empty)

  - Not all sources provide respondent counts
  - Some polls lack method information
  - Survey dates are sometimes estimated

⚠️ **Scope variations**: 

  - "federal" = Germany-wide
  - State codes (e.g., "bayern", "nrw") = state-specific

---

## Quick Reference Table

| If you want to know... | Look in table... | And join with... | API Endpoint |
|------------------------|------------------|------------------|--------------|
| What polls exist? | `polls` | - | `/v1/polls` |
| Who conducted a poll? | `polls` | `institutes` | `/v1/polls` |
| What were the results? | `poll_results` | `polls` + `parties` | `/v1/results` |
| What parties exist? | `parties` | - | `/v1/reference/parties` |
| What elections are covered? | `elections` | - | `/v1/elections` |
| How was a poll conducted? | `polls` | `methods` | `/v1/polls` |
| Original source data? | `polls_raw` | - | `/v1/raw-polls` |

---

See the [API Reference](../api-reference/overview.md) for detailed endpoint documentation.
