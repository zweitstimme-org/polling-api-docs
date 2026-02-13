# Your First Request

Let's make your first API request! We'll use R with the `httr2` package, but the concepts apply to any programming language.

## Prerequisites

### Installing R and httr2

If you haven't already, install the httr2 package:

```r
install.packages("httr2")
```

Load it in your R session:

```r
library(httr2)
```

## Making a Simple Request

The most basic request fetches polls without any filters:

```r
library(httr2)

# Create and perform the request
response <- request("https://api.fasttrack29.com/v1/polls") |>
  req_perform()

# Check if it worked
resp_status(response)
# Should return: 200

# Get the data
data <- resp_body_json(response)

# See what we got
names(data)
# [1] "items" "meta"
```

## Understanding the Response

The response has two main parts:

### 1. Items (the actual data)

```r
# Look at the first poll
first_poll <- data$items[[1]]

names(first_poll)
# [1] "id"              "raw_id"          "publish_date"   
# [4] "survey_date_start" "survey_date_end" "respondents"    
# [7] "scope"           "source"          "institute_id"   
# [10] "institute_name"  "provider_id"     "provider_name"  
# [13] "election_id"     "election_type"   "method_id"      
# [16] "method_name"     "date_downloaded" "results"

# See the results
first_poll$results
# [[1]]
# $party_id
# [1] 1
# $party_short_name
# [1] "CDU/CSU"
# $party_name
# [1] "Christlich Demokratische Union/Christlich-Soziale Union"
# $percentage
# [1] 31.5
```

### 2. Metadata (pagination info)

```r
data$meta
# $total
# [1] 15432
# $limit
# [1] 100
# $offset
# [1] 0
```

This tells you:
- **total**: 15,432 polls total in the database
- **limit**: You got 100 polls (the default)
- **offset**: Starting from the first poll (0)

## Adding Filters

Real research usually requires filtering. Let's get only federal polls:

```r
federal_polls <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "federal",
    limit = 10
  ) |>
  req_perform() |>
  resp_body_json()

# Check how many we got
length(federal_polls$items)
```

## Filtering by Date

Get polls from the last 30 days:

```r
library(lubridate)

# Calculate date 30 days ago
start_date <- Sys.Date() - 30

recent_polls <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "federal",
    date_from = as.character(start_date),
    limit = 100
  ) |>
  req_perform() |>
  resp_body_json()
```

## Combining Multiple Filters

You can combine filters to get very specific data:

```r
specific_polls <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "federal",
    date_from = "2024-01-01",
    date_to = "2024-12-31",
    limit = 50
  ) |>
  req_perform() |>
  resp_body_json()
```

## Working with Results

Let's convert the results to a data frame for analysis:

```r
library(dplyr)
library(purrr)

# Extract results from all polls
all_results <- map_dfr(data$items, function(poll) {
  if (!is.null(poll$results)) {
    map_dfr(poll$results, function(result) {
      tibble(
        poll_id = poll$id,
        publish_date = poll$publish_date,
        institute = poll$institute_name,
        party = result$party_short_name,
        percentage = result$percentage
      )
    })
  }
})

# View the results
head(all_results)

# Quick summary
all_results |>
  group_by(party) |>
  summarise(
    avg_support = mean(percentage, na.rm = TRUE),
    n_polls = n()
  ) |>
  arrange(desc(avg_support))
```

## Troubleshooting

### Common Errors

**404 Not Found**
```r
# Wrong endpoint
request("https://api.fasttrack29.com/v1/poll")  # Missing 's'
```
Make sure your URL is exactly correct.

**400 Bad Request**
```r
# Invalid date format
request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(date_from = "01-15-2024")  # Wrong format!
```
Use `YYYY-MM-DD` format for dates.

**No Results**
```r
# Too restrictive filters
request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "nonexistent_scope"
  ) |>
  req_perform()
```
Try removing filters one by one to find the issue.

### Debugging Tips

1. **Check the URL being sent:**
```r
req <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(scope = "federal")

# See the actual URL
req$url
```

2. **Inspect the raw response:**
```r
response <- req_perform(req)
resp_body_string(response)  # See raw JSON
```

3. **Check rate limits:**
```r
resp_headers(response)$`x-ratelimit-remaining`
```

## Next Steps

Now that you can make basic requests, learn more about:

- **[Understanding the Data](data-model.md)** — Deep dive into the data structure
- **[Pagination](../api-reference/overview.md#pagination)** — Handling large result sets
- **[Reference Tables](../api-reference/reference-tables.md)** — Using lookup tables
