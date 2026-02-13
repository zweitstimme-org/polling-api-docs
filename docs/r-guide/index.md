# Working with the Polling API in R

This guide shows you how to use the Zweitstimme Polling API with R and the `httr2` package. We'll cover practical examples for academic research.

## Prerequisites

You'll need these R packages:

```r
install.packages(c("httr2", "dplyr", "purrr", "ggplot2", "lubridate", "tidyr"))
```

Load them:

```r
library(httr2)
library(dplyr)
library(purrr)
library(ggplot2)
library(lubridate)
library(tidyr)
```

## Basic API Calls

### Your First Request

Let's start with a simple request to get recent federal polls:

```r
# Create the request
response <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "federal",
    limit = 5
  ) |>
  req_perform()

# Check status
resp_status(response)  # Should be 200

# Parse JSON response
polls_data <- resp_body_json(response)

# See what we got
names(polls_data)
# [1] "items" "meta"

# Number of polls returned
length(polls_data$items)
```

### Understanding the Response

The response has two parts:

1. **`items`**: The actual poll data (array of polls)
2. **`meta`**: Pagination info (total, limit, offset)

```r
# Look at first poll structure
str(polls_data$items[[1]])

# Pagination info
polls_data$meta
```

### Extracting Data into a Data Frame

Convert the nested JSON into a tidy data frame:

```r
# Extract poll metadata
polls_df <- map_dfr(polls_data$items, function(poll) {
  tibble(
    id = poll$id,
    publish_date = as.Date(poll$publish_date),
    institute = poll$institute_name,
    respondents = poll$respondents,
    scope = poll$scope
  )
})

print(polls_df)
```

### Working with Results

Polls include party results. Let's extract them:

```r
# Get results from all polls
all_results <- map_dfr(polls_data$items, function(poll) {
  # For each poll, extract all party results
  map_dfr(poll$results, function(result) {
    tibble(
      poll_id = poll$id,
      publish_date = as.Date(poll$publish_date),
      institute = poll$institute_name,
      party = result$party_short_name,
      percentage = result$percentage
    )
  })
})

print(all_results)
```

## Filtering Data

### By Date Range

Get polls from a specific time period:

```r
# Get polls from last 30 days
start_date <- Sys.Date() - 30

recent_polls <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "federal",
    date_from = as.character(start_date),
    limit = 100
  ) |>
  req_perform() |>
  resp_body_json()

# Extract to data frame
recent_df <- map_dfr(recent_polls$items, function(poll) {
  map_dfr(poll$results, function(result) {
    tibble(
      publish_date = as.Date(poll$publish_date),
      institute = poll$institute_name,
      party = result$party_short_name,
      percentage = result$percentage
    )
  })
})
```

### By Institute

First, find the institute ID:

```r
# Get institutes
institutes <- request("https://api.fasttrack29.com/v1/reference/institutes") |>
  req_perform() |>
  resp_body_json()

# Find Forsa
forsa <- institutes |>
  bind_rows() |>
  filter(name == "Forsa")

forsa_id <- forsa$id

# Get Forsa polls
forsa_polls <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    institute_id = forsa_id,
    scope = "federal",
    limit = 100
  ) |>
  req_perform() |>
  resp_body_json()
```

### By Party

Use the `/v1/results` endpoint to filter by party:

```r
# Get CDU/CSU results (party_id = 1)
cdu_results <- request("https://api.fasttrack29.com/v1/results") |>
  req_url_query(
    scope = "federal",
    party_id = 1,
    date_from = "2024-01-01",
    limit = 100
  ) |>
  req_perform() |>
  resp_body_json()

# Extract to data frame
cdu_df <- map_dfr(cdu_results$items, function(item) {
  result <- item$results[[1]]  # First (and only) result
  tibble(
    date = as.Date(item$publish_date),
    party = result$party_short_name,
    percentage = result$percentage
  )
})
```

## Visualization Examples

### Time Series Plot

Plot party support over time:

```r
# Get data for major parties
major_parties <- c(1, 2, 3, 5)  # CDU/CSU, SPD, Grüne, AfD

all_data <- map_dfr(major_parties, function(party_id) {
  response <- request("https://api.fasttrack29.com/v1/results") |>
    req_url_query(
      scope = "federal",
      party_id = party_id,
      date_from = "2024-01-01",
      limit = 100
    ) |>
    req_perform() |>
    resp_body_json()
  
  map_dfr(response$items, function(item) {
    result <- item$results[[1]]
    tibble(
      date = as.Date(item$publish_date),
      party = result$party_short_name,
      percentage = result$percentage
    )
  })
})

# Plot
ggplot(all_data, aes(x = date, y = percentage, color = party)) +
  geom_line(alpha = 0.3) +
  geom_smooth(method = "loess", se = FALSE) +
  labs(
    title = "Party Support Trends in 2024",
    x = "Date",
    y = "Support (%)",
    color = "Party"
  ) +
  theme_minimal() +
  scale_y_continuous(limits = c(0, NA))
```

### Comparing Institutes

Compare how different pollsters rate a party:

```r
# Get all polls for CDU/CSU in 2024
cdu_data <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "federal",
    date_from = "2024-01-01",
    limit = 200
  ) |>
  req_perform() |>
  resp_body_json()

# Extract CDU/CSU results by institute
cdu_by_institute <- map_dfr(cdu_data$items, function(poll) {
  # Find CDU/CSU result in this poll
  cdu_result <- poll$results |>
    keep(~ .$party_id == 1) |>
    first()
  
  if (!is.null(cdu_result)) {
    tibble(
      date = as.Date(poll$publish_date),
      institute = poll$institute_name,
      percentage = cdu_result$percentage
    )
  }
})

# Box plot by institute
ggplot(cdu_by_institute, aes(x = reorder(institute, percentage, median), 
                              y = percentage)) +
  geom_boxplot() +
  coord_flip() +
  labs(
    title = "CDU/CSU Support by Polling Institute (2024)",
    x = "Institute",
    y = "Support (%)"
  ) +
  theme_minimal()
```

### Heatmap of Party Support

```r
# Get recent data
polls <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "federal",
    date_from = "2024-01-01",
    limit = 100
  ) |>
  req_perform() |>
  resp_body_json()

# Create matrix
heatmap_data <- map_dfr(polls$items, function(poll) {
  map_dfr(poll$results, function(result) {
    tibble(
      month = floor_date(as.Date(poll$publish_date), "month"),
      party = result$party_short_name,
      percentage = result$percentage
    )
  })
}) |>
  group_by(month, party) |>
  summarise(avg = mean(percentage), .groups = 'drop') |>
  pivot_wider(names_from = party, values_from = avg)

# Plot heatmap
heatmap_data |>
  pivot_longer(-month, names_to = "party", values_to = "percentage") |>
  ggplot(aes(x = month, y = party, fill = percentage)) +
  geom_tile() +
  scale_fill_gradient(low = "white", high = "steelblue") +
  labs(
    title = "Average Party Support by Month",
    x = "Month",
    y = "Party",
    fill = "Support (%)"
  ) +
  theme_minimal()
```

## Working with Reference Data

### Get Party Colors

```r
# Get parties reference
parties <- request("https://api.fasttrack29.com/v1/reference/parties") |>
  req_perform() |>
  resp_body_json() |>
  bind_rows()

# Create color palette
party_colors <- parties |>
  select(short_name, color) |>
  deframe()

# Use in plots
ggplot(data, aes(x = date, y = percentage, color = party)) +
  geom_line() +
  scale_color_manual(values = party_colors)
```

### Create Lookup Functions

```r
# Cache reference data
ref <- request("https://api.fasttrack29.com/v1/reference/all") |>
  req_perform() |>
  resp_body_json()

# Helper functions
get_party_name <- function(id) {
  ref$parties |>
    bind_rows() |>
    filter(id == !!id) |>
    pull(short_name)
}

get_institute_name <- function(id) {
  ref$institutes |>
    bind_rows() |>
    filter(id == !!id) |>
    pull(name)
}

# Use them
get_party_name(1)  # "CDU/CSU"
get_institute_name(1)  # "Forsa"
```

## Advanced Techniques

### Paginating Through Large Datasets

```r
get_all_polls <- function(filters = list()) {
  all_items <- list()
  offset <- 0
  limit <- 500
  
  repeat {
    # Build request with filters
    req <- request("https://api.fasttrack29.com/v1/polls")
    
    # Add filter parameters
    for (name in names(filters)) {
      req <- req |> req_url_query(!!name := filters[[name]])
    }
    
    # Add pagination
    req <- req |> req_url_query(limit = limit, offset = offset)
    
    # Perform request
    response <- req |>
      req_perform() |>
      resp_body_json()
    
    all_items <- c(all_items, response$items)
    
    # Check if done
    if (length(response$items) < limit) break
    
    offset <- offset + limit
    message("Fetched ", offset, " polls...")
    
    # Be nice to the API
    Sys.sleep(0.1)
  }
  
  return(all_items)
}

# Get all 2024 federal polls
all_2024_polls <- get_all_polls(list(
  scope = "federal",
  date_from = "2024-01-01"
))
```

### Error Handling

```r
safe_api_call <- function(url, ...) {
  tryCatch({
    response <- request(url) |>
      req_url_query(...) |>
      req_perform()
    
    if (resp_status(response) == 200) {
      return(resp_body_json(response))
    } else {
      warning("API returned status: ", resp_status(response))
      return(NULL)
    }
  }, error = function(e) {
    warning("API call failed: ", e$message)
    return(NULL)
  })
}

# Use safe call
data <- safe_api_call(
  "https://api.fasttrack29.com/v1/polls",
  scope = "federal",
  limit = 10
)
```

### Caching Results

```r
library(memoise)

# Create cached version of API call
get_polls_cached <- memoise(function(...) {
  request("https://api.fasttrack29.com/v1/polls") |>
    req_url_query(...) |>
    req_perform() |>
    resp_body_json()
}, cache = cache_filesystem(".api_cache"))

# First call hits the API
data1 <- get_polls_cached(scope = "federal", limit = 10)

# Second call uses cache (instant!)
data2 <- get_polls_cached(scope = "federal", limit = 10)
```

## Complete Workflow Example

Here's a complete workflow for analyzing party trends:

```r
library(httr2)
library(dplyr)
library(purrr)
library(ggplot2)
library(lubridate)

# Step 1: Get reference data
parties <- request("https://api.fasttrack29.com/v1/reference/parties") |>
  req_perform() |>
  resp_body_json() |>
  bind_rows()

# Step 2: Get polls for analysis period
polls <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "federal",
    date_from = "2024-01-01",
    limit = 200
  ) |>
  req_perform() |>
  resp_body_json()

# Step 3: Transform to tidy format
tidy_polls <- map_dfr(polls$items, function(poll) {
  map_dfr(poll$results, function(result) {
    tibble(
      date = as.Date(poll$publish_date),
      institute = poll$institute_name,
      party_id = result$party_id,
      party = result$party_short_name,
      percentage = result$percentage
    )
  })
})

# Step 4: Calculate rolling averages
analysis <- tidy_polls |>
  group_by(party) |>
  arrange(date) |>
  mutate(
    rolling_avg = zoo::rollmean(percentage, k = 5, fill = NA, align = "right")
  ) |>
  ungroup()

# Step 5: Visualize
ggplot(analysis, aes(x = date)) +
  geom_point(aes(y = percentage, color = party), alpha = 0.3, size = 1) +
  geom_line(aes(y = rolling_avg, color = party), size = 1) +
  facet_wrap(~party, ncol = 2) +
  labs(
    title = "German Party Support Trends in 2024",
    subtitle = "Individual polls (points) and 5-poll rolling average (line)",
    x = "Date",
    y = "Support (%)",
    color = "Party"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

# Step 6: Summary statistics
summary_stats <- tidy_polls |>
  group_by(party) |>
  summarise(
    n_polls = n(),
    mean = mean(percentage),
    median = median(percentage),
    sd = sd(percentage),
    min = min(percentage),
    max = max(percentage),
    .groups = 'drop'
  ) |>
  arrange(desc(mean))

print(summary_stats)
```

## Helper Functions

### Safe API Requests

Handle errors gracefully:

```r
safe_api_request <- function(req) {
  tryCatch(
    {
      response <- req_perform(req)
      
      # Check status code
      status <- resp_status(response)
      if (status != 200) {
        warning(paste("API returned status:", status))
        return(NULL)
      }
      
      resp_body_json(response, simplifyVector = TRUE)
    },
    error = function(e) {
      message(paste("Error making request:", conditionMessage(e)))
      return(NULL)
    }
  )
}

# Usage
response <- safe_api_request(
  request("https://api.fasttrack29.com/v1/polls") |> 
    req_url_query(limit = 10)
)
```

### Rate Limiting

Add delay between requests to be respectful:

```r
make_delayed_request <- function(req, delay = 0.5) {
  Sys.sleep(delay)
  req_perform(req)
}

# Batch request with delays
fetch_multiple_pages <- function(n_pages = 5) {
  all_data <- list()
  
  for (i in 1:n_pages) {
    response <- request("https://api.fasttrack29.com/v1/polls") |>
      req_url_query(
        limit = 100,
        offset = (i - 1) * 100
      ) |>
      make_delayed_request(delay = 0.5)
    
    data <- resp_body_json(response, simplifyVector = TRUE)
    all_data[[i]] <- data$items
    
    message(paste("Fetched page", i, "of", n_pages))
  }
  
  bind_rows(all_data)
}
```

### Get Party ID by Name

```r
get_party_id <- function(party_name) {
  ref_data <- request("https://api.fasttrack29.com/v1/reference/all") |>
    req_perform() |>
    resp_body_json(simplifyVector = TRUE)
  
  parties <- as_tibble(ref_data$parties)
  
  # Search by short name or full name
  match <- parties |>
    filter(
      short_name == party_name | 
      name == party_name |
      grepl(party_name, name, ignore.case = TRUE)
    )
  
  if (nrow(match) == 0) {
    stop(paste("Party not found:", party_name))
  }
  
  return(match$id[1])
}

# Usage
cdu_id <- get_party_id("CDU/CSU")
spd_id <- get_party_id("SPD")
```

### Coalition Analysis

Analyze if a coalition would have majority:

```r
analyze_coalition <- function(poll_id, coalition_parties) {
  # Get specific poll
  response <- request("https://api.fasttrack29.com/v1/polls") |>
    req_url_path(paste0("/", poll_id)) |>
    req_perform()
  
  poll_data <- resp_body_json(response, simplifyVector = TRUE)
  
  # Extract results
  results <- as_tibble(poll_data$results)
  
  # Calculate coalition total
  coalition_sum <- results |>
    filter(party_id %in% coalition_parties) |>
    pull(percentage) |>
    sum()
  
  # Check if majority (>50%)
  majority <- coalition_sum > 50
  
  list(
    poll_id = poll_id,
    total = coalition_sum,
    majority = majority,
    parties = results |> filter(party_id %in% coalition_parties)
  )
}

# Example: CDU/CSU + SPD (Grand Coalition)
analyze_coalition(8923, c(1, 2))  # CDU/CSU + SPD
```

## Using simplifyVector

The `simplifyVector = TRUE` parameter in `resp_body_json()` automatically converts JSON arrays to R vectors/matrices when possible, making data easier to work with:

```r
# Without simplifyVector (returns nested lists)
data <- resp_body_json(response)

# With simplifyVector (returns data frames where possible)
data <- resp_body_json(response, simplifyVector = TRUE)
```

## Tips and Best Practices

1. **Always check response status** before parsing
2. **Use filters** to minimize data transfer
3. **Cache reference data** - it rarely changes
4. **Handle missing data** - some fields can be NULL
5. **Respect rate limits** - add small delays between requests
6. **Use appropriate data types** - convert dates, factors as needed
7. **Use simplifyVector** for easier data manipulation
8. **Implement error handling** for robust scripts

## Further Reading

- [httr2 documentation](https://httr2.r-lib.org/)
- [API Reference](../api-reference/overview.md)
- [Use Cases](../use-cases/time-series.md)
- [Data & Pipeline](../data-pipeline/index.md) - Understanding data sources
