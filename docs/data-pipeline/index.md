# Data & Pipeline

Understanding how polling data flows from sources to your analysis.

## What's in This Section

This section explains the complete data journey:

### [Data Pipeline](pipeline.md)
How data moves from external sources through processing to the API:
- Data sources (Wahlrecht.de, DAWUM API)
- Scraping process
- Cleaning and normalization (ETL)
- Quality assurance

### [Database Schema](schema.md)
Understanding the database structure:
- Table relationships
- Reference tables (lookup dictionaries)
- Main data tables
- Field descriptions

## Why This Matters

Understanding the data pipeline helps you:

1. **Trust the data** — Know where it comes from and how it's processed
2. **Handle edge cases** — Understand why some fields might be missing
3. **Debug issues** — Trace problems back to their source
4. **Interpret results** — Know the limitations and quirks of the data

## Quick Overview

```
External Sources → Scrapers → Raw Data → ETL Pipeline → Clean Data → API
```

**Key Points**:
- Data comes from multiple German polling aggregators
- Raw data is preserved unchanged (audit trail)
- Cleaning normalizes formats and standardizes names
- Quality checks ensure data integrity
- API serves cleaned, queryable data

## For Researchers

You don't need to understand every technical detail to use the API. But knowing:
- **Data sources** → Helps you cite and validate
- **Cleaning process** → Explains why formats are standardized
- **Schema** → Helps you write better queries

Will make you a more effective user of the data.

---

Ready to dive in? Start with the [Data Pipeline](pipeline.md) to understand the journey your data takes.
