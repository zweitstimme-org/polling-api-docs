# Party Trends Analysis

Analyze and visualize trends in party support over time.

## Introduction

Understanding how party support changes is fundamental to political analysis. This guide covers:

- Tracking party support trajectories
- Identifying turning points
- Comparing party performance
- Analyzing coalition potential

## Getting Started

### Fetch Party Data

```r
library(httr2)
library(dplyr)
library(purrr)
library(ggplot2)
library(lubridate)
library(tidyr)
library(zoo)

# Get all federal polls from 2024
polls <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "federal",
    date_from = "2024-01-01",
    limit = 500
  ) |>
  req_perform() |>
  resp_body_json()

# Convert to tidy format
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
```

## Individual Party Trends

### Single Party Trajectory

Track one party's support over time:

```r
# Focus on CDU/CSU
cdu_data <- tidy_polls |>
  filter(party == "CDU/CSU") |>
  arrange(date) |>
  mutate(
    # 7-poll moving average
    ma_7 = rollmean(percentage, k = 7, fill = NA, align = "right"),
    # Cumulative average
    cum_avg = cummean(percentage)
  )

# Create comprehensive plot
ggplot(cdu_data, aes(x = date)) +
  # Raw polls
  geom_point(aes(y = percentage), alpha = 0.3, color = "gray50") +
  # Moving average
  geom_line(aes(y = ma_7, color = "7-Poll MA"), size = 1) +
  # Cumulative average
  geom_line(aes(y = cum_avg, color = "Cumulative Avg"), 
            linetype = "dashed", size = 1) +
  scale_color_manual(values = c("7-Poll MA" = "blue", 
                                "Cumulative Avg" = "red")) +
  labs(
    title = "CDU/CSU Support Trajectory in 2024",
    x = "Date",
    y = "Support (%)",
    color = "Metric"
  ) +
  theme_minimal()
```

### Identifying Peaks and Troughs

Find the highest and lowest points:

```r
# Find peaks and troughs for each party
extremes <- tidy_polls |>
  group_by(party) |>
  summarise(
    peak_value = max(percentage),
    peak_date = date[which.max(percentage)],
    trough_value = min(percentage),
    trough_date = date[which.min(percentage)],
    current = percentage[which.max(date)],
    .groups = 'drop'
  )

print(extremes)
```

## Comparative Analysis

### Multi-Party Trends

Compare multiple parties on the same plot:

```r
# Major parties
major_parties <- c("CDU/CSU", "SPD", "Grüne", "AfD", "FDP", "Linke")

# Calculate moving averages for all
party_trends <- tidy_polls |>
  filter(party %in% major_parties) |>
  group_by(party) |>
  arrange(date) |>
  mutate(
    ma_7 = rollmean(percentage, k = 7, fill = NA, align = "right")
  ) |>
  ungroup()

# Get party colors
parties_ref <- request("https://api.fasttrack29.com/v1/reference/parties") |>
  req_perform() |>
  resp_body_json() |>
  bind_rows()

party_colors <- parties_ref |>
  select(short_name, color) |>
  filter(short_name %in% major_parties) |>
  deframe()

# Plot all parties
ggplot(party_trends, aes(x = date, y = ma_7, color = party)) +
  geom_line(size = 1) +
  scale_color_manual(values = party_colors) +
  labs(
    title = "Party Support Trends (7-Poll Moving Average)",
    x = "Date",
    y = "Support (%)",
    color = "Party"
  ) +
  theme_minimal()
```

### Relative Performance

Compare parties relative to each other:

```r
# Calculate relative rankings over time
rankings <- tidy_polls |>
  filter(party %in% major_parties) |>
  group_by(date) |>
  mutate(
    rank = rank(-percentage, ties.method = "min")
  ) |>
  ungroup()

# Plot rankings as lines
ggplot(rankings, aes(x = date, y = rank, color = party)) +
  geom_line(size = 1) +
  geom_point(size = 0.5) +
  scale_y_reverse(breaks = 1:6) +
  scale_color_manual(values = party_colors) +
  labs(
    title = "Party Rankings Over Time",
    x = "Date",
    y = "Rank (1 = Highest)",
    color = "Party"
  ) +
  theme_minimal()
```

## Coalition Analysis

### Coalition Potential

Analyze which coalitions would have majority:

```r
# Define possible coalitions
coalitions <- list(
  "CDU/CSU + SPD" = c("CDU/CSU", "SPD"),
  "CDU/CSU + Grüne" = c("CDU/CSU", "Grüne"),
  "CDU/CSU + Grüne + FDP" = c("CDU/CSU", "Grüne", "FDP"),
  "SPD + Grüne" = c("SPD", "Grüne"),
  "SPD + Grüne + FDP" = c("SPD", "Grüne", "FDP"),
  "CDU/CSU + SPD + FDP" = c("CDU/CSU", "SPD", "FDP")
)

# Calculate coalition support over time
coalition_data <- map_dfr(names(coalitions), function(name) {
  parties <- coalitions[[name]]
  
  tidy_polls |>
    filter(party %in% parties) |>
    group_by(date) |>
    summarise(
      coalition = name,
      total_support = sum(percentage),
      .groups = 'drop'
    )
}) |>
  arrange(date) |>
  group_by(coalition) |>
  mutate(
    ma_7 = rollmean(total_support, k = 7, fill = NA, align = "right")
  ) |>
  ungroup()

# Plot coalition trends
ggplot(coalition_data, aes(x = date, y = ma_7, color = coalition)) +
  geom_line(size = 1) +
  geom_hline(yintercept = 50, linetype = "dashed", 
             color = "red", alpha = 0.5) +
  annotate("text", x = min(coalition_data$date), y = 51, 
           label = "50% threshold", hjust = 0, color = "red") +
  labs(
    title = "Coalition Support Trends",
    subtitle = "7-poll moving average",
    x = "Date",
    y = "Combined Support (%)",
    color = "Coalition"
  ) +
  theme_minimal()
```

### Majority Probability

Estimate probability of achieving majority:

```r
# Calculate majority probability for each coalition
majority_prob <- coalition_data |>
  group_by(coalition) |>
  summarise(
    pct_above_50 = mean(total_support > 50, na.rm = TRUE) * 100,
    avg_support = mean(total_support, na.rm = TRUE),
    .groups = 'drop'
  ) |>
  arrange(desc(pct_above_50))

print(majority_prob)
```

## Trend Indicators

### Momentum Analysis

Calculate which parties are gaining or losing:

```r
# Calculate momentum (change over last 30 days)
momentum <- tidy_polls |>
  filter(party %in% major_parties) |>
  group_by(party) |>
  arrange(date) |>
  mutate(
    # Calculate rolling 30-day change
    lag_30 = lag(percentage, 30),
    momentum = percentage - lag_30
  ) |>
  filter(!is.na(momentum)) |>
  slice_tail(n = 1) |>  # Most recent
  ungroup() |>
  select(party, momentum) |>
  arrange(desc(momentum))

# Visualize momentum
ggplot(momentum, aes(x = reorder(party, momentum), y = momentum, 
                     fill = momentum > 0)) +
  geom_col() +
  geom_hline(yintercept = 0, linetype = "dashed") +
  coord_flip() +
  scale_fill_manual(values = c("red", "green"),
                    labels = c("Declining", "Rising")) +
  labs(
    title = "Party Momentum (30-Day Change)",
    x = "Party",
    y = "Change (% points)",
    fill = "Direction"
  ) +
  theme_minimal()
```

### Volatility by Party

Which parties are most volatile?

```r
volatility <- tidy_polls |>
  filter(party %in% major_parties) |>
  group_by(party) |>
  summarise(
    sd = sd(percentage),
    range = max(percentage) - min(percentage),
    coefficient_var = sd / mean(percentage),
    .groups = 'drop'
  ) |>
  arrange(desc(sd))

# Plot volatility
ggplot(volatility, aes(x = reorder(party, sd), y = sd, fill = party)) +
  geom_col() +
  coord_flip() +
  scale_fill_manual(values = party_colors) +
  labs(
    title = "Party Polling Volatility",
    subtitle = "Standard deviation of support",
    x = "Party",
    y = "Standard Deviation"
  ) +
  theme_minimal() +
  theme(legend.position = "none")
```

## Advanced Visualizations

### Area Chart

Show composition of support:

```r
# Create stacked area chart
party_trends |>
  filter(!is.na(ma_7)) |>
  ggplot(aes(x = date, y = ma_7, fill = party)) +
  geom_area(position = "stack", alpha = 0.8) +
  scale_fill_manual(values = party_colors) +
  labs(
    title = "Party Support Composition Over Time",
    x = "Date",
    y = "Support (%)",
    fill = "Party"
  ) +
  theme_minimal()
```

### Slope Graph

Compare start and end points:

```r
# Get first and last values
start_end <- tidy_polls |>
  filter(party %in% major_parties) |>
  group_by(party) |>
  summarise(
    start = first(percentage),
    start_date = first(date),
    end = last(percentage),
    end_date = last(date),
    change = end - start,
    .groups = 'drop'
  )

# Create slope data
slope_data <- start_end |>
  pivot_longer(cols = c(start, end), 
               names_to = "period",
               values_to = "support") |>
  mutate(
    x = ifelse(period == "start", 1, 2)
  )

# Plot slope graph
ggplot(slope_data, aes(x = x, y = support, group = party, color = party)) +
  geom_line(size = 1) +
  geom_point(size = 3) +
  geom_text(data = start_end, aes(x = 1, y = start, label = party),
            hjust = 1, nudge_x = -0.1) +
  geom_text(data = start_end, aes(x = 2, y = end, label = round(end, 1)),
            hjust = 0, nudge_x = 0.1) +
  scale_x_continuous(breaks = c(1, 2), labels = c("Start", "End")) +
  scale_color_manual(values = party_colors) +
  labs(
    title = "Party Support: Start vs End of Period",
    y = "Support (%)",
    x = NULL
  ) +
  theme_minimal() +
  theme(legend.position = "none")
```

## Predictive Analysis

### Trend Extrapolation

Simple linear extrapolation:

```r
# Fit linear trend for each party
predictions <- tidy_polls |>
  filter(party %in% major_parties) |>
  group_by(party) |>
  group_modify(~ {
    # Create time index
    .x <- .x |> mutate(t = row_number())
    
    # Fit linear model
    model <- lm(percentage ~ t, data = .x)
    
    # Predict next 30 days
    future_t <- max(.x$t) + 1:30
    pred <- predict(model, newdata = data.frame(t = future_t), 
                    interval = "prediction")
    
    # Create prediction data frame
    last_date <- max(.x$date)
    tibble(
      date = last_date + 1:30,
      predicted = pred[, "fit"],
      lower = pred[, "lwr"],
      upper = pred[, "upr"]
    )
  }) |>
  ungroup()

# Plot with predictions
full_data <- tidy_polls |>
  filter(party %in% major_parties) |>
  select(date, party, percentage) |>
  rename(value = percentage) |>
  mutate(type = "Actual") |>
  bind_rows(
    predictions |>
      select(date, party, predicted) |>
      rename(value = predicted) |>
      mutate(type = "Predicted")
  )

ggplot(full_data, aes(x = date, y = value, color = party, linetype = type)) +
  geom_line(size = 1) +
  scale_color_manual(values = party_colors) +
  labs(
    title = "Party Support with Linear Trend Projection",
    x = "Date",
    y = "Support (%)",
    color = "Party",
    linetype = "Type"
  ) +
  theme_minimal()
```

## Best Practices

### When Analyzing Trends

1. **Use appropriate time windows** - Too short = noise, too long = misses changes
2. **Consider multiple indicators** - Averages, rankings, coalitions
3. **Account for uncertainty** - Show confidence intervals when possible
4. **Look at context** - Events, campaigns, and scandals matter
5. **Compare to benchmarks** - Previous elections, other countries

### Common Pitfalls

- **Over-interpreting single polls**: Always look at trends
- **Ignoring house effects**: Different institutes show different levels
- **Cherry-picking time periods**: Be honest about the timeframe
- **Forgetting uncertainty**: Polling has error margins

## See Also

- [Time Series Analysis](time-series.md)
- [Comparing Pollsters](comparing-pollsters.md)
- [R Vignette](../r-guide/vignette.md)
