# Downloads Endpoint

Download bulk data in various formats for offline analysis.


## Available Downloads

### JSON

```
GET /v1/download/json
```

Download all cleaned polls as JSON.

```r
library(httr2)

# Download JSON
download <- request("https://api.fasttrack29.com/v1/download/json") |>
  req_perform()

# Save to file
writeBin(resp_body_raw(download), "polls.json")

# Or load directly into R
polls <- resp_body_json(download)
```

### CSV

```
GET /v1/download/csv
```

Download polls as CSV (flattened format).

```r
# Download CSV
download <- request("https://api.fasttrack29.com/v1/download/csv") |>
  req_perform()

# Save and read
data <- resp_body_string(download)
writeLines(data, "polls.csv")

df <- read.csv("polls.csv")
```

### SQLite

```
GET /v1/download/sqlite
```

Download complete SQLite database.

```r
library(httr2)

# Download SQLite database
download <- request("https://api.fasttrack29.com/v1/download/sqlite") |>
  req_perform()

# Save to file
writeBin(resp_body_raw(download), "polling_data.db")

# Connect with RSQLite
library(RSQLite)
library(DBI)

con <- dbConnect(RSQLite::SQLite(), "polling_data.db")

# List tables
dbListTables(con)

# Query data
polls <- dbGetQuery(con, "SELECT * FROM polls LIMIT 10")

# Close connection
dbDisconnect(con)
```

### Parquet

```
GET /v1/download/parquet
```

Download polls as Apache Parquet (efficient columnar format).

```r
library(httr2)
library(arrow)

# Download Parquet
download <- request("https://api.fasttrack29.com/v1/download/parquet") |>
  req_perform()

# Save and read
writeBin(resp_body_raw(download), "polls.parquet")
df <- read_parquet("polls.parquet")
```

### Raw Data

```
GET /v1/download/raw
```

Download all raw polls as JSON.

```r
raw_data <- request("https://api.fasttrack29.com/v1/download/raw") |>
  req_perform() |>
  resp_body_json()
```

### Results

```
GET /v1/download/results
```

Download flattened poll results as JSON.

```r
results <- request("https://api.fasttrack29.com/v1/download/results") |>
  req_perform() |>
  resp_body_json()
```

## List Available Assets

```
GET /v1/download
```

Get information about available downloads.

```r
assets <- request("https://api.fasttrack29.com/v1/download") |>
  req_perform() |>
  resp_body_json()
```

## Format Comparison

| Format | Best For | R Package | Notes |
|--------|----------|-----------|-------|
| JSON | API integration | jsonlite | Native format |
| CSV | Excel/SPSS | readr | Human-readable |
| SQLite | SQL queries | RSQLite | Full relational database |
| Parquet | Large datasets | arrow | Fast, compressed |

## Download Strategies

### Regular Updates

```r
# Function to update local data
update_local_data <- function() {
  # Download latest SQLite database
  download <- request("https://api.fasttrack29.com/v1/download/sqlite") |>
    req_perform()
  
  # Backup old version
  if (file.exists("polling_data.db")) {
    file.rename("polling_data.db", "polling_data_old.db")
  }
  
  # Save new version
  writeBin(resp_body_raw(download), "polling_data.db")
  
  message("Database updated successfully")
}

# Run update
update_local_data()
```

### Download Specific Date Range

Downloads don't support filtering. For specific ranges, use the API:

```r
# Download recent data via API
recent_polls <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    date_from = "2024-01-01",
    limit = 500
  ) |>
  req_perform() |>
  resp_body_json()

# Save as CSV
library(dplyr)
library(readr)

polls_df <- bind_rows(recent_polls$items)
write_csv(polls_df, "recent_polls.csv")
```

### Working with SQLite

```r
library(RSQLite)
library(DBI)
library(dplyr)

# Connect to downloaded database
con <- dbConnect(RSQLite::SQLite(), "polling_data.db")

# List all tables
tables <- dbListTables(con)
print(tables)

# Query with SQL
polls_2024 <- dbGetQuery(con, 
  "SELECT * FROM polls 
   WHERE publish_date >= '2024-01-01'")

# Query with dplyr
polls_table <- tbl(con, "polls")

recent_polls <- polls_table |>
  filter(publish_date >= "2024-01-01") |>
  collect()

# Complex queries
party_results <- dbGetQuery(con, "
  SELECT 
    p.name as party_name,
    AVG(pr.percentage) as avg_support,
    COUNT(*) as n_polls
  FROM poll_results pr
  JOIN parties p ON pr.party_id = p.id
  WHERE pr.publish_date >= '2024-01-01'
  GROUP BY p.name
  ORDER BY avg_support DESC
")

# Close connection
dbDisconnect(con)
```

## Size Considerations

Download sizes (approximate):

| Format | Size | Notes |
|--------|------|-------|
| JSON | ~50 MB | Uncompressed |
| CSV | ~30 MB | Flattened |
| SQLite | ~40 MB | Includes indexes |
| Parquet | ~10 MB | Compressed |

## Caching

```r
# Cache downloads locally
cache_download <- function(url, cache_file, max_age_hours = 24) {
  # Check if cached file exists and is recent
  if (file.exists(cache_file)) {
    file_age <- difftime(Sys.time(), file.mtime(cache_file), units = "hours")
    if (file_age < max_age_hours) {
      message("Using cached file: ", cache_file)
      return(cache_file)
    }
  }
  
  # Download fresh data
  message("Downloading fresh data...")
  download <- request(url) |>
    req_perform()
  
  writeBin(resp_body_raw(download), cache_file)
  return(cache_file)
}

# Use cache
sqlite_file <- cache_download(
  "https://api.fasttrack29.com/v1/download/sqlite",
  "polling_data.db",
  max_age_hours = 24
)
```

## See Also

- [API Overview](overview.md) — When to use API vs downloads
- [R Vignette](../r-guide/vignette.md) — Working with downloaded data
