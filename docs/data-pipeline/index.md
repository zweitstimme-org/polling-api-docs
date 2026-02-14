# Data & Pipeline

Understanding how polling data flows from sources to your analysis.

## What's in This Section

### [Database Schema](schema.md)
Understanding the database structure:

- Table relationships
- Reference tables (lookup dictionaries)
- Main data tables
- Field descriptions


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

