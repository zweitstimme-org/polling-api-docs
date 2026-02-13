# Time Series Analysis

Learn how to analyze polling trends over time using the API.

## Introduction

Time series analysis is one of the most common uses of polling data. This guide shows you how to:

- Fetch historical data
- Calculate moving averages
- Identify trends and patterns
- Visualize changes over time

## Basic Time Series

### Fetching Historical Data

Let's get all federal polls from the past year:

```r
library(httr2)
library(dplyr)
library(purrr)
library(ggplot2)
library(lubridate)

# Calculate date one year ago
start_date <- Sys.Date() - 365

# Fetch polls
polls <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "federal",
    date_from = as.character(start_date),
    limit = 500
  ) |>
  req_perform() |>
  resp_body_json()

# Convert to tidy format
tidy_polls <- map_dfr(polls$items, function(poll) {
  map_dfr(poll$results, function(result) {
    tibble(
      date = as.Date(poll$publish_date),
      party = result$party_short_name,
      percentage = result$percentage
    )
  })
})
```

### Simple Line Plot

Plot raw polling data over time:

```r
# Filter major parties
major_parties <- c("CDU/CSU", "SPD", "Grüne", "AfD", "FDP", "Linke")

plot_data <- tidy_polls |>
  filter(party %in% major_parties)

ggplot(plot_data, aes(x = date, y = percentage, color = party)) +
  geom_point(alpha = 0.3, size = 1) +
  geom_smooth(method = "loess", se = FALSE) +
  labs(
    title = "German Party Support Over Time",
    x = "Date",
    y = "Support (%)",
    color = "Party"
  ) +
  theme_minimal()
```

## Moving Averages

### Simple Moving Average

Polls are noisy. Let's calculate a 7-poll moving average:

```r
library(zoo)

# Calculate rolling averages by party
rolling_data <- tidy_polls |>
  filter(party %in% major_parties) |>
  group_by(party) |>
  arrange(date) |>
  mutate(
    # 7-poll moving average
    ma_7 = rollmean(percentage, k = 7, fill = NA, align = "right"),
    # 14-poll moving average
    ma_14 = rollmean(percentage, k = 14, fill = NA, align = "right")
  ) |>
  ungroup()

# Plot with moving averages
ggplot(rolling_data, aes(x = date, color = party)) +
  geom_point(aes(y = percentage), alpha = 0.2, size = 0.8) +
  geom_line(aes(y = ma_7), size = 1, alpha = 0.8) +
  labs(
    title = "Party Support with 7-Poll Moving Average",
    x = "Date",
    y = "Support (%)",
    color = "Party"
  ) +
  theme_minimal()
```

### Weighted Moving Average

Weight more recent polls more heavily:

```r
# Calculate exponentially weighted moving average
ewma_data <- tidy_polls |>
  filter(party %in% major_parties) |>
  group_by(party) |>
  arrange(date) |>
  mutate(
    ewma = EWMA(percentage, lambda = 0.3)
  ) |>
  ungroup()

# Compare different smoothing methods
comparison <- rolling_data |>
  filter(party == "CDU/CSU") |>
  select(date, percentage, ma_7, ma_14) |>
  pivot_longer(cols = c(percentage, ma_7, ma_14),
               names_to = "method",
               values_to = "value")

ggplot(comparison, aes(x = date, y = value, color = method)) +
  geom_line() +
  labs(
    title = "CDU/CSU Support: Raw vs Moving Averages",
    x = "Date",
    y = "Support (%)",
    color = "Method"
  ) +
  theme_minimal()
```

## Trend Analysis

### Linear Trends

Fit linear trends to identify long-term direction:

```r
# Add time index for regression
analysis_data <- tidy_polls |>
  filter(party %in% major_parties) |>
  group_by(party) |>
  mutate(
    time_index = row_number()
  ) |>
  ungroup()

# Fit linear model for each party
trends <- analysis_data |>
  group_by(party) |>
  summarise(
    model = list(lm(percentage ~ time_index)),
    .groups = 'drop'
  ) |>
  mutate(
    slope = map_dbl(model, ~ coef(.)[2]),
    r_squared = map_dbl(model, ~ summary(.)$r.squared)
  )

print(trends |> select(party, slope, r_squared))
```

### Change Point Detection

Identify when significant changes occurred:

```r
library(changepoint)

# Focus on one party
cdu_data <- tidy_polls |>
  filter(party == "CDU/CSU") |>
  arrange(date)

# Detect change points
cp_model <- cpt.mean(cdu_data$percentage, method = "PELT")

# Plot with change points
ggplot(cdu_data, aes(x = date, y = percentage)) +
  geom_point(alpha = 0.3) +
  geom_vline(xintercept = cdu_data$date[cpts(cp_model)], 
             linetype = "dashed", color = "red") +
  labs(
    title = "CDU/CSU: Detected Change Points",
    x = "Date",
    y = "Support (%)"
  ) +
  theme_minimal()
```

## Seasonal Patterns

### Monthly Averages

Are there seasonal patterns in polling?

```r
monthly_data <- tidy_polls |>
  filter(party %in% major_parties) |>
  mutate(
    month = month(date),
    month_name = month(date, label = TRUE),
    year = year(date)
  ) |>
  group_by(party, month_name) |>
  summarise(
    avg_support = mean(percentage),
    .groups = 'drop'
  )

# Plot seasonal pattern
ggplot(monthly_data, aes(x = month_name, y = avg_support, group = party, color = party)) +
  geom_line(size = 1) +
  geom_point() +
  facet_wrap(~party) +
  labs(
    title = "Average Party Support by Month",
    x = "Month",
    y = "Average Support (%)"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
```

## Comparing Time Periods

### Pre- vs Post-Event

Compare polling before and after a significant event:

```r
# Define event date (example: election date)
event_date <- as.Date("2024-06-09")  # EU election

period_comparison <- tidy_polls |>
  filter(party %in% major_parties) |>
  mutate(
    period = ifelse(date < event_date, "Before", "After"),
    days_from_event = as.numeric(date - event_date)
  ) |>
  filter(abs(days_from_event) <= 90)  # 90 days before/after

# Plot
ggplot(period_comparison, aes(x = days_from_event, y = percentage, color = party)) +
  geom_point(alpha = 0.3) +
  geom_smooth(method = "loess") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "black") +
  facet_wrap(~party) +
  labs(
    title = "Polling Before and After EU Election",
    subtitle = "90 days before/after June 9, 2024",
    x = "Days from Event",
    y = "Support (%)"
  ) +
  theme_minimal()
```

## Advanced Visualization

### Ridgeline Plot

Show distribution changes over time:

```r
library(ggridges)

# Create time periods
tidy_polls <- tidy_polls |>
  mutate(
    period = case_when(
      date < as.Date("2024-04-01") ~ "Q1 2024",
      date < as.Date("2024-07-01") ~ "Q2 2024",
      date < as.Date("2024-10-01") ~ "Q3 2024",
      TRUE ~ "Q4 2024"
    )
  )

# Ridgeline plot
ggplot(tidy_polls |> filter(party == "CDU/CSU"), 
       aes(x = percentage, y = period, fill = period)) +
  geom_density_ridges(alpha = 0.7) +
  labs(
    title = "CDU/CSU Support Distribution by Quarter",
    x = "Support (%)",
    y = "Quarter"
  ) +
  theme_minimal() +
  theme(legend.position = "none")
```

### Calendar Heatmap

Show polling intensity over time:

```r
# Create calendar data
calendar_data <- tidy_polls |>
  group_by(date) |>
  summarise(
    n_polls = n(),
    .groups = 'drop'
  ) |>
  mutate(
    year = year(date),
    month = month(date),
    week = week(date)
  )

# Calendar heatmap
ggplot(calendar_data, aes(x = week, y = month, fill = n_polls)) +
  geom_tile() +
  facet_wrap(~year) +
  scale_fill_gradient(low = "white", high = "steelblue") +
  labs(
    title = "Number of Polls by Week",
    x = "Week of Year",
    y = "Month",
    fill = "Polls"
  ) +
  theme_minimal()
```

## Forecasting

### Simple Forecast

Use time series models to project future support:

```r
library(forecast)

# Create time series for one party
cdu_ts <- tidy_polls |>
  filter(party == "CDU/CSU") |>
  arrange(date) |>
  pull(percentage) |>
  ts(frequency = 52)  # Weekly data

# Fit ARIMA model
model <- auto.arima(cdu_ts)

# Forecast 4 weeks ahead
forecast_data <- forecast(model, h = 4)

# Plot forecast
autoplot(forecast_data) +
  labs(
    title = "CDU/CSU Support Forecast",
    subtitle = "4-week ahead projection",
    y = "Support (%)",
    x = "Time"
  )
```

## Best Practices

1. **Always use moving averages** when showing trends - raw polls are too noisy
2. **Consider polling volume** - more polls = more reliable averages
3. **Account for house effects** - different institutes may have biases
4. **Note uncertainty** - show confidence intervals when possible
5. **Consider event impacts** - major events can cause sudden changes

## Further Reading

- [Forecasting: Principles and Practice](https://otexts.com/fpp3/)
- [Comparing Pollsters](comparing-pollsters.md)
- [Party Trends](party-trends.md)
