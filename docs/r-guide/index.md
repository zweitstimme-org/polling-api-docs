# Working with the Polling API in R

A comprehensive guide to accessing German polling data using R, progressing from simple requests to advanced analysis.

## Prerequisites

```r
install.packages(c("httr2", "dplyr", "ggplot2", "lubridate", "purrr"))

library(httr2)
library(dplyr)
library(ggplot2)
library(lubridate)
library(purrr)
```

---

## Level 1: Simple Requests

### Your First API Call

The simplest possible request - just fetch data and check if it worked:

```r
# Make a basic request
response <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(limit = 5) |>
  req_perform()

# Check if successful
resp_status(response)
# Should return: 200

# Get the data as JSON
polls <- resp_body_json(response)

# See what we received
names(polls)
# [1] "items" "meta"

# How many polls?
length(polls$items)
```

### Fetching Specific Data

Get federal polls with a simple filter:

```r
# Request federal polls
response <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "federal",
    limit = 10
  ) |>
  req_perform()

polls <- resp_body_json(response)

# Look at the first poll
first_poll <- polls$items[[1]]
first_poll$institute_name
first_poll$publish_date
```

### Getting Reference Data

Reference tables are simple lookups:

```r
# Get list of parties
parties <- request("https://api.fasttrack29.com/v1/reference/parties") |>
  req_perform() |>
  resp_body_json()

# View as a simple list
for (party in parties) {
  cat(party$short_name, "=", party$id, "\n")
}
```

---

## Level 2: Working with Data

### Converting to Data Frames

API data comes as nested lists. Let's convert it to a tidy data frame:

```r
# Fetch polls
response <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "federal",
    limit = 20,
    include_results = TRUE
  ) |>
  req_perform()

polls <- resp_body_json(response)

# Method 1: Simple extraction using purrr
polls_df <- map_dfr(polls$items, function(poll) {
  tibble(
    id = poll$id,
    date = as.Date(poll$publish_date),
    institute = poll$institute_name,
    respondents = poll$respondents
  )
})

# View the result
head(polls_df)
```

### Extracting Party Results

Polls contain nested results. Here's how to flatten them:

```r
# Extract all party results from all polls
results_df <- map_dfr(polls$items, function(poll) {
  # For each poll, extract each party result
  map_dfr(poll$results, function(result) {
    tibble(
      poll_id = poll$id,
      date = as.Date(poll$publish_date),
      institute = poll$institute_name,
      party = result$party_short_name,
      percentage = result$percentage
    )
  })
})

# View results
head(results_df)

# Simple summary
results_df |>
  group_by(party) |>
  summarise(
    avg = mean(percentage),
    n = n()
  )
```

### Filtering by Date

Get recent polls using date parameters:

```r
# Calculate date 30 days ago
start_date <- Sys.Date() - 30

# Fetch recent polls
response <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "federal",
    date_from = as.character(start_date),
    limit = 50
  ) |>
  req_perform()

recent_polls <- resp_body_json(response)

# Convert to data frame
recent_df <- map_dfr(recent_polls$items, function(poll) {
  map_dfr(poll$results, function(result) {
    tibble(
      date = as.Date(poll$publish_date),
      party = result$party_short_name,
      percentage = result$percentage
    )
  })
})
```

---

## Level 3: Analysis and Visualization

### Basic Plot: Latest Poll Results

Visualize the most recent poll:

```r
# Get latest poll data
latest_poll <- results_df |>
  filter(date == max(date))

# Simple bar chart
ggplot(latest_poll, aes(x = reorder(party, percentage), y = percentage)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(
    title = "Latest Federal Poll",
    subtitle = paste("Published:", max(latest_poll$date)),
    x = "Party",
    y = "Support (%)"
  ) +
  theme_minimal()
```

### Time Series: Track Party Over Time

Plot how one party's support has changed:

```r
# Filter for one party
cdu_data <- results_df |>
  filter(party == "CDU/CSU") |>
  arrange(date)

# Line plot with trend
ggplot(cdu_data, aes(x = date, y = percentage)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "loess", se = TRUE) +
  labs(
    title = "CDU/CSU Support Over Time",
    x = "Date",
    y = "Support (%)"
  ) +
  theme_minimal()
```

### Multi-Party Comparison

Compare multiple parties on the same plot:

```r
# Get major parties
major_parties <- c("CDU/CSU", "SPD", "Grüne", "AfD")

plot_data <- results_df |>
  filter(party %in% major_parties)

# Faceted plot
ggplot(plot_data, aes(x = date, y = percentage)) +
  geom_point(alpha = 0.3) +
  geom_smooth(method = "loess", se = FALSE) +
  facet_wrap(~party) +
  labs(
    title = "Party Support Trends",
    x = "Date",
    y = "Support (%)"
  ) +
  theme_minimal()
```

### Advanced: Rolling Averages

Smooth out polling noise with moving averages:

```r
library(zoo)

# Calculate 7-poll rolling average
rolling_data <- results_df |>
  filter(party %in% major_parties) |>
  group_by(party) |>
  arrange(date) |>
  mutate(
    rolling_avg = rollmean(percentage, k = 7, fill = NA, align = "right")
  ) |>
  ungroup()

# Plot with rolling average
ggplot(rolling_data, aes(x = date, color = party)) +
  geom_point(aes(y = percentage), alpha = 0.2) +
  geom_line(aes(y = rolling_avg), size = 1) +
  labs(
    title = "Party Support with 7-Poll Rolling Average",
    x = "Date",
    y = "Support (%)",
    color = "Party"
  ) +
  theme_minimal()
```

---

## Helper Functions

### Safe Request Function

Handle errors gracefully:

```r
safe_request <- function(url, ...) {
  tryCatch({
    response <- request(url) |>
      req_url_query(...) |>
      req_perform()
    
    if (resp_status(response) == 200) {
      resp_body_json(response)
    } else {
      warning(paste("Status:", resp_status(response)))
      NULL
    }
  }, error = function(e) {
    message(paste("Error:", e$message))
    NULL
  })
}

# Usage
data <- safe_request(
  "https://api.fasttrack29.com/v1/polls",
  scope = "federal",
  limit = 10
)
```

### Complete Workflow Function

Fetch and transform in one step:

```r
get_poll_data <- function(scope = "federal", days = 30) {
  # Calculate date range
  start <- Sys.Date() - days
  
  # Fetch data
  response <- request("https://api.fasttrack29.com/v1/polls") |>
    req_url_query(
      scope = scope,
      date_from = as.character(start),
      limit = 100
    ) |>
    req_perform()
  
  polls <- resp_body_json(response)
  
  # Transform to tidy format
  map_dfr(polls$items, function(poll) {
    map_dfr(poll$results, function(result) {
      tibble(
        date = as.Date(poll$publish_date),
        institute = poll$institute_name,
        party = result$party_short_name,
        percentage = result$percentage
      )
    })
  })
}

# Usage
data <- get_poll_data("federal", 90)
```

---

## Tips and Best Practices

### 1. Always Check Response Status

```r
response <- request(url) |> req_perform()

if (resp_status(response) != 200) {
  stop("Request failed")
}

data <- resp_body_json(response)
```

### 2. Use simplifyVector for Easier Data

```r
# Returns nested lists (default)
data <- resp_body_json(response)

# Returns data frames where possible
data <- resp_body_json(response, simplifyVector = TRUE)
```

### 3. Filter Early to Save Bandwidth

```r
# Good: Filter at API level
request(url) |>
  req_url_query(scope = "federal", date_from = "2024-01-01")

# Bad: Fetch everything then filter
request(url) |> req_url_query(limit = 10000)
# Then filter in R...
```

### 4. Cache Reference Data

```r
# Reference data rarely changes
parties <- request("https://api.fasttrack29.com/v1/reference/parties") |>
  req_perform() |>
  resp_body_json()

# Save for reuse
saveRDS(parties, "parties_cache.rds")

# Load later
parties <- readRDS("parties_cache.rds")
```

### 5. Handle Missing Data

```r
# Some fields can be NULL
polls_df <- map_dfr(polls$items, function(poll) {
  tibble(
    id = poll$id,
    # Use %||% (null default operator) for missing values
    respondents = poll$respondents %||% NA_integer_
  )
})
```

---

## Quick Reference

### Common API Patterns

```r
# GET request with query parameters
request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(scope = "federal", limit = 10) |>
  req_perform() |>
  resp_body_json()

# Check status
resp_status(response)  # 200 = OK, 404 = Not Found, etc.

# Error handling
tryCatch({
  response <- request(url) |> req_perform()
}, error = function(e) {
  message("Failed: ", e$message)
})
```

### Data Transformation Patterns

```r
# List of polls to data frame
polls_df <- map_dfr(polls$items, ~tibble(
  id = .x$id,
  date = as.Date(.x$publish_date)
))

# Nested results to flat data frame
results_df <- map_dfr(polls$items, function(poll) {
  map_dfr(poll$results, ~tibble(
    poll_id = poll$id,
    party = .x$party_short_name,
    pct = .x$percentage
  ))
})
```

### Visualization Patterns

```r
# Basic bar chart
ggplot(data, aes(x = party, y = percentage)) +
  geom_col() +
  coord_flip()

# Time series
ggplot(data, aes(x = date, y = percentage, color = party)) +
  geom_line()

# Faceted
ggplot(data, aes(x = date, y = percentage)) +
  geom_point() +
  facet_wrap(~party)
```

---

## Next Steps

- **[R Vignette](vignette.md)** — Complete workflow examples with detailed analysis
- **[Use Cases](../use-cases/time-series.md)** — Advanced analysis scenarios
- **[API Reference](../api-reference/overview.md)** — Endpoint documentation
- **[Data & Pipeline](../data-pipeline/index.md)** — Understanding data sources

## Further Reading

- [httr2 documentation](https://httr2.r-lib.org/)
- [ggplot2 documentation](https://ggplot2.tidyverse.org/)
- [purrr documentation](https://purrr.tidyverse.org/)
