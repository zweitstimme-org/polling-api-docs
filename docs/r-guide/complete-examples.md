# Complete Workflow Examples

This section demonstrates complete end-to-end workflows for common research scenarios using the Zweitstimme Polling API with R.

## Prerequisites

```r
install.packages(c("httr2", "dplyr", "purrr", "ggplot2", "lubridate", "zoo"))

library(httr2)
library(dplyr)
library(purrr)
library(ggplot2)
library(lubridate)
library(zoo)
```

## Example 1: Basic Data Retrieval

Fetch recent federal polls and convert to a tidy format:

```r
# Fetch polls
response <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "federal",
    limit = 10,
    include_results = TRUE
  ) |>
  req_perform()

polls_data <- resp_body_json(response)

# Convert to tidy data frame
polls_summary <- map_dfr(polls_data$items, function(poll) {
  tibble(
    id = poll$id,
    publish_date = as.Date(poll$publish_date),
    institute = poll$institute_name,
    respondents = as.integer(poll$respondents %||% NA),
    scope = poll$scope
  )
})

head(polls_summary)
```

## Example 2: Time Series Analysis

Track party support over the past year with rolling averages:

```r
# Calculate date range
start_date <- Sys.Date() - 365

# Fetch polls
response <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "federal",
    date_from = as.character(start_date),
    limit = 500
  ) |>
  req_perform()

polls <- resp_body_json(response)

# Convert to tidy format
tidy_data <- map_dfr(polls$items, function(poll) {
  map_dfr(poll$results, function(result) {
    tibble(
      date = as.Date(poll$publish_date),
      party = result$party_short_name,
      percentage = result$percentage
    )
  })
})

# Calculate rolling averages
major_parties <- c("CDU/CSU", "SPD", "Grüne", "AfD")

rolling_data <- tidy_data |>
  filter(party %in% major_parties) |>
  group_by(party) |>
  arrange(date) |>
  mutate(
    rolling_avg = rollmean(percentage, k = 7, fill = NA, align = "right")
  ) |>
  ungroup()

# Plot
ggplot(rolling_data, aes(x = date, color = party)) +
  geom_point(aes(y = percentage), alpha = 0.2, size = 0.8) +
  geom_line(aes(y = rolling_avg), size = 1) +
  labs(
    title = "Party Support Trends with 7-Poll Rolling Average",
    x = "Date",
    y = "Support (%)",
    color = "Party"
  ) +
  theme_minimal() +
  scale_y_continuous(limits = c(0, NA))
```

## Example 3: Comparing Polling Institutes

Analyze systematic differences between institutes (house effects):

```r
# Fetch data
response <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "federal",
    date_from = "2024-01-01",
    limit = 300
  ) |>
  req_perform()

polls <- resp_body_json(response)

# Extract data
tidy_polls <- map_dfr(polls$items, function(poll) {
  map_dfr(poll$results, function(result) {
    tibble(
      date = as.Date(poll$publish_date),
      institute = poll$institute_name,
      party = result$party_short_name,
      percentage = result$percentage
    )
  })
})

# Calculate averages by institute
major_parties <- c("CDU/CSU", "SPD", "Grüne", "AfD")

institute_comparison <- tidy_polls |>
  filter(party %in% major_parties) |>
  group_by(institute, party) |>
  summarise(
    avg_support = mean(percentage),
    n_polls = n(),
    .groups = 'drop'
  ) |>
  filter(n_polls >= 5)

# Plot comparison
ggplot(institute_comparison, aes(x = reorder(institute, avg_support), 
                                  y = avg_support, 
                                  fill = party)) +
  geom_col(position = "dodge") +
  coord_flip() +
  facet_wrap(~party, scales = "free_x") +
  labs(
    title = "Average Party Support by Polling Institute",
    subtitle = "Institutes with 5+ polls",
    x = "Institute",
    y = "Average Support (%)",
    fill = "Party"
  ) +
  theme_minimal() +
  theme(legend.position = "none")
```

## Example 4: Coalition Analysis

Determine which coalitions would have majority support:

```r
# Get latest poll
response <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "federal",
    limit = 1,
    include_results = TRUE
  ) |>
  req_perform()

latest <- resp_body_json(response)

# Extract results
results <- map_dfr(latest$items[[1]]$results, function(r) {
  tibble(
    party = r$party_short_name,
    party_id = r$party_id,
    percentage = r$percentage
  )
})

# Define coalitions
coalitions <- list(
  "CDU/CSU + SPD" = c(1, 2),
  "CDU/CSU + Grüne" = c(1, 4),
  "CDU/CSU + Grüne + FDP" = c(1, 4, 3),
  "SPD + Grüne" = c(2, 4),
  "SPD + Grüne + FDP" = c(2, 4, 3)
)

# Calculate coalition support
coalition_sums <- map_dfr(names(coalitions), function(name) {
  party_ids <- coalitions[[name]]
  total <- results |>
    filter(party_id %in% party_ids) |>
    pull(percentage) |>
    sum()
  
  tibble(
    coalition = name,
    total_support = total,
    majority = total > 50
  )
})

# Display results
coalition_sums |>
  arrange(desc(total_support))
```

## Example 5: Exporting Data

Download and export data for use in other tools:

```r
# Fetch data
response <- request("https://api.fasttrack29.com/v1/results") |>
  req_url_query(
    scope = "federal",
    date_from = "2024-01-01",
    limit = 1000
  ) |>
  req_perform()

data <- resp_body_json(response)

# Convert to flat data frame
flat_data <- map_dfr(data$items, function(item) {
  result <- item$results[[1]]
  tibble(
    poll_id = item$poll_id,
    date = as.Date(item$publish_date),
    institute_id = item$institute_id,
    party_id = result$party_id,
    party = result$party_short_name,
    percentage = result$percentage
  )
})

# Export to CSV
write.csv(flat_data, "polling_data_2024.csv", row.names = FALSE)

# Export to RDS (R native format)
saveRDS(flat_data, "polling_data_2024.rds")

# Create summary statistics
summary_stats <- flat_data |>
  group_by(party) |>
  summarise(
    n_polls = n(),
    mean_support = mean(percentage),
    sd_support = sd(percentage),
    min_support = min(percentage),
    max_support = max(percentage),
    .groups = 'drop'
  ) |>
  arrange(desc(mean_support))

write.csv(summary_stats, "polling_summary_2024.csv", row.names = FALSE)
```

## Example 6: Method Comparison

Compare results by survey methodology:

```r
# Fetch polls with method data
response <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "federal",
    date_from = "2024-01-01",
    limit = 200
  ) |>
  req_perform()

polls <- resp_body_json(response)

# Extract method and results
data_by_method <- map_dfr(polls$items, function(poll) {
  if (!is.null(poll$results) && !is.null(poll$method_name)) {
    map_dfr(poll$results, function(result) {
      if (result$party_short_name %in% c("CDU/CSU", "SPD", "Grüne", "AfD")) {
        tibble(
          method = poll$method_name,
          party = result$party_short_name,
          percentage = result$percentage
        )
      }
    })
  }
})

# Calculate averages
method_comparison <- data_by_method |>
  filter(!is.na(method)) |>
  group_by(method, party) |>
  summarise(
    avg = mean(percentage),
    n = n(),
    se = sd(percentage) / sqrt(n()),
    .groups = 'drop'
  ) |>
  filter(n >= 10)

# Plot with error bars
ggplot(method_comparison, aes(x = method, y = avg, fill = party)) +
  geom_col(position = "dodge") +
  geom_errorbar(aes(ymin = avg - 1.96*se, ymax = avg + 1.96*se),
                position = position_dodge(width = 0.9),
                width = 0.2) +
  facet_wrap(~party) +
  labs(
    title = "Average Support by Polling Method",
    subtitle = "With 95% confidence intervals",
    x = "Method",
    y = "Average Support (%)"
  ) +
  theme_minimal() +
  theme(legend.position = "none", 
        axis.text.x = element_text(angle = 45, hjust = 1))
```

## Example 7: Election Proximity Analysis

Analyze how polls change as elections approach:

```r
# Get election information
elections_resp <- request("https://api.fasttrack29.com/v1/reference/elections") |>
  req_perform() |>
  resp_body_json()

elections <- bind_rows(elections_resp)

# Find next federal election
next_election <- elections |>
  filter(election_type == "Bundestagswahl", 
         as.Date(date) > Sys.Date()) |>
  arrange(date) |>
  slice(1)

if (nrow(next_election) > 0) {
  election_date <- as.Date(next_election$date)
  
  # Get polls for major parties
  polls_resp <- request("https://api.fasttrack29.com/v1/results") |>
    req_url_query(
      scope = "federal",
      date_from = as.character(election_date - 365),
      limit = 500
    ) |>
    req_perform() |>
    resp_body_json()
  
  # Process data
  proximity_data <- map_dfr(polls_resp$items, function(item) {
    result <- item$results[[1]]
    if (result$party_short_name %in% c("CDU/CSU", "SPD", "Grüne", "AfD")) {
      tibble(
        date = as.Date(item$publish_date),
        days_to_election = as.numeric(election_date - as.Date(item$publish_date)),
        party = result$party_short_name,
        percentage = result$percentage
      )
    }
  }) |>
    filter(days_to_election >= 0, days_to_election <= 365)
  
  # Plot
  ggplot(proximity_data, aes(x = days_to_election, y = percentage, color = party)) +
    geom_point(alpha = 0.3) +
    geom_smooth(method = "loess", se = TRUE) +
    scale_x_reverse() +
    facet_wrap(~party) +
    labs(
      title = "Polling Trends as Election Approaches",
      subtitle = paste("Election date:", format(election_date, "%d.%m.%Y")),
      x = "Days to Election",
      y = "Support (%)"
    ) +
    theme_minimal()
}
```

## Summary

These examples demonstrate:

1. **Basic data retrieval** — Fetching and converting API responses
2. **Time series analysis** — Tracking trends with rolling averages  
3. **Comparative analysis** — Comparing institutes and methods
4. **Coalition scenarios** — Calculating hypothetical coalition support
5. **Data export** — Saving data for external analysis
6. **Statistical analysis** — Confidence intervals and aggregation
7. **Temporal analysis** — Proximity to events

Each example is complete and can be run directly in R with the required packages installed.

## See Also

- [Working with R](index.md) — Progressive tutorial from basics to advanced
- [Use Cases](../use-cases/time-series.md) — Specialized analysis techniques
- [API Reference](../api-reference/overview.md) — Endpoint documentation
