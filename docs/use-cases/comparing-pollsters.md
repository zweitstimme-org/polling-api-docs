# Comparing Pollsters

Analyze systematic differences between polling institutes.

## Introduction

Different polling institutes may produce systematically different results due to:

- **Methodological differences** (phone vs online)
- **Sampling variations** (different populations)
- **Weighting procedures** (adjusting for demographics)
- **Timing** (fieldwork schedules)

This guide shows you how to identify and analyze these "house effects."

## Basic Comparison

### Fetching Data by Institute

```r
library(httr2)
library(dplyr)
library(purrr)
library(ggplot2)
library(lubridate)

# Get all federal polls from 2024
polls <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "federal",
    date_from = "2024-01-01",
    limit = 500
  ) |>
  req_perform() |>
  resp_body_json()

# Convert to tidy format with institute info
tidy_polls <- map_dfr(polls$items, function(poll) {
  map_dfr(poll$results, function(result) {
    tibble(
      date = as.Date(poll$publish_date),
      institute = poll$institute_name,
      method = poll$method_name,
      party = result$party_short_name,
      percentage = result$percentage
    )
  })
})
```

### Average Support by Institute

Calculate and compare averages:

```r
# Calculate averages
institute_avgs <- tidy_polls |>
  group_by(institute, party) |>
  summarise(
    avg_support = mean(percentage),
    n_polls = n(),
    sd_support = sd(percentage),
    .groups = 'drop'
  ) |>
  filter(n_polls >= 10)  # Only institutes with enough data

# Focus on major parties
major_parties <- c("CDU/CSU", "SPD", "Grüne", "AfD")

plot_data <- institute_avgs |>
  filter(party %in% major_parties)

# Plot
ggplot(plot_data, aes(x = reorder(institute, avg_support), 
                      y = avg_support, 
                      fill = party)) +
  geom_col(position = "dodge") +
  coord_flip() +
  facet_wrap(~party, scales = "free_x") +
  labs(
    title = "Average Party Support by Polling Institute",
    subtitle = "Institutes with 10+ polls in 2024",
    x = "Institute",
    y = "Average Support (%)",
    fill = "Party"
  ) +
  theme_minimal() +
  theme(legend.position = "none")
```

## House Effects Analysis

### Calculating House Effects

Compare each institute to the overall average:

```r
# Calculate overall averages
overall_avgs <- tidy_polls |>
  group_by(party) |>
  summarise(
    overall_avg = mean(percentage),
    .groups = 'drop'
  )

# Calculate house effects
house_effects <- institute_avgs |>
  left_join(overall_avgs, by = "party") |>
  mutate(
    house_effect = avg_support - overall_avg
  ) |>
  filter(party %in% major_parties)

# Visualize house effects
ggplot(house_effects, aes(x = reorder(institute, house_effect), 
                          y = house_effect, 
                          fill = house_effect > 0)) +
  geom_col() +
  geom_hline(yintercept = 0, linetype = "dashed") +
  coord_flip() +
  facet_wrap(~party, scales = "free_x") +
  scale_fill_manual(values = c("red", "green"), 
                    labels = c("Below Average", "Above Average")) +
  labs(
    title = "House Effects by Polling Institute",
    subtitle = "Difference from overall average",
    x = "Institute",
    y = "House Effect (% points)",
    fill = "Direction"
  ) +
  theme_minimal()
```

### Statistical Significance

Test if house effects are statistically significant:

```r
# Perform t-tests for each institute-party combination
house_effect_tests <- tidy_polls |>
  filter(party %in% major_parties) |>
  group_by(party) |>
  group_modify(~ {
    institutes <- unique(.x$institute)
    map_dfr(institutes, function(inst) {
      inst_data <- .x |> filter(institute == inst)
      other_data <- .x |> filter(institute != inst)
      
      if (nrow(inst_data) >= 10 && nrow(other_data) >= 10) {
        test <- t.test(inst_data$percentage, other_data$percentage)
        tibble(
          institute = inst,
          mean_diff = mean(inst_data$percentage) - mean(other_data$percentage),
          p_value = test$p.value,
          significant = test$p.value < 0.05
        )
      }
    })
  }) |>
  ungroup()

# Plot significant effects
sig_effects <- house_effect_tests |>
  filter(significant)

ggplot(sig_effects, aes(x = reorder(institute, mean_diff), 
                        y = mean_diff, 
                        fill = mean_diff > 0)) +
  geom_col() +
  coord_flip() +
  facet_wrap(~party, scales = "free_x") +
  labs(
    title = "Statistically Significant House Effects (p < 0.05)",
    x = "Institute",
    y = "Mean Difference from Others (% points)"
  ) +
  theme_minimal()
```

## Methodological Differences

### Comparing Methods

Do phone vs online polls produce different results?

```r
# Get polls with method information
method_comparison <- tidy_polls |>
  filter(!is.na(method), method != "Unknown") |>
  filter(party %in% major_parties) |>
  group_by(method, party) |>
  summarise(
    avg = mean(percentage),
    n = n(),
    se = sd(percentage) / sqrt(n()),
    .groups = 'drop'
  ) |>
  filter(n >= 20)  # Sufficient sample

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
  theme(legend.position = "none", axis.text.x = element_text(angle = 45, hjust = 1))
```

### Sample Size Effects

Do larger sample sizes produce more stable results?

```r
# Get polls with respondent information
sample_analysis <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(
    scope = "federal",
    date_from = "2024-01-01",
    limit = 500
  ) |>
  req_perform() |>
  resp_body_json()

sample_data <- map_dfr(sample_analysis$items, function(poll) {
  map_dfr(poll$results, function(result) {
    tibble(
      institute = poll$institute_name,
      respondents = as.integer(poll$respondents),
      party = result$party_short_name,
      percentage = result$percentage
    )
  })
}) |>
  filter(!is.na(respondents), party %in% major_parties)

# Analyze by sample size bins
sample_data <- sample_data |>
  mutate(
    sample_size_bin = case_when(
      respondents < 1000 ~ "< 1000",
      respondents < 2000 ~ "1000-1999",
      respondents < 3000 ~ "2000-2999",
      TRUE ~ "3000+"
    )
  )

# Calculate variance by sample size
variance_by_size <- sample_data |>
  group_by(sample_size_bin, party) |>
  summarise(
    variance = var(percentage),
    n = n(),
    .groups = 'drop'
  )

# Plot
ggplot(variance_by_size, aes(x = sample_size_bin, y = variance, fill = party)) +
  geom_col(position = "dodge") +
  facet_wrap(~party) +
  labs(
    title = "Polling Variance by Sample Size",
    x = "Sample Size",
    y = "Variance"
  ) +
  theme_minimal() +
  theme(legend.position = "none")
```

## Temporal Consistency

### Stability Over Time

Are house effects consistent or do they change?

```r
# Calculate rolling house effects
rolling_effects <- tidy_polls |>
  filter(party == "CDU/CSU") |>  # Focus on one party
  arrange(date) |>
  group_by(institute) |>
  mutate(
    rolling_avg = zoo::rollmean(percentage, k = 5, fill = NA, align = "right")
  ) |>
  ungroup()

# Get overall rolling average
overall_rolling <- tidy_polls |>
  filter(party == "CDU/CSU") |>
  arrange(date) |>
  mutate(
    overall_rolling = zoo::rollmean(percentage, k = 5, fill = NA, align = "right")
  ) |>
  select(date, overall_rolling) |>
  distinct()

# Merge and calculate difference
effect_over_time <- rolling_effects |>
  left_join(overall_rolling, by = "date") |>
  mutate(
    house_effect = rolling_avg - overall_rolling
  ) |>
  filter(!is.na(house_effect))

# Plot
ggplot(effect_over_time, aes(x = date, y = house_effect, color = institute)) +
  geom_line() +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(
    title = "CDU/CSU House Effects Over Time",
    subtitle = "5-poll rolling average difference from overall",
    x = "Date",
    y = "House Effect (% points)",
    color = "Institute"
  ) +
  theme_minimal()
```

## Advanced Analysis

### Multilevel Model

Account for multiple factors simultaneously:

```r
library(lme4)

# Prepare data
model_data <- tidy_polls |>
  filter(party == "CDU/CSU") |>
  mutate(
    month = month(date),
    year = year(date)
  )

# Fit mixed-effects model
model <- lmer(percentage ~ (1 | institute) + (1 | method) + month,
              data = model_data)

# Extract random effects
institute_effects <- ranef(model)$institute |>
  as.data.frame() |>
  rownames_to_column("institute") |>
  rename(effect = `(Intercept)`)

# Plot
ggplot(institute_effects, aes(x = reorder(institute, effect), y = effect)) +
  geom_col(aes(fill = effect > 0)) +
  coord_flip() +
  labs(
    title = "CDU/CSU: Institute Effects (Multilevel Model)",
    subtitle = "Controlling for method and month",
    x = "Institute",
    y = "Random Effect"
  ) +
  theme_minimal()
```

## Best Practices

### When Comparing Pollsters

1. **Check sample sizes** - Small samples = unreliable averages
2. **Consider time periods** - Compare same time frames
3. **Look at multiple parties** - Effects may vary by party
4. **Account for method** - Different methods explain some differences
5. **Consider uncertainty** - Use confidence intervals

### Interpreting House Effects

House effects don't necessarily mean bias:

- **Positive effect**: Institute tends to show higher support
- **Negative effect**: Institute tends to show lower support
- **Could indicate**: Methodological differences, timing, or real differences

Always consider:
- Sample size
- Time period
- Methodology
- Statistical significance

## See Also

- [Time Series Analysis](time-series.md)
- [Party Trends](party-trends.md)
- [API Reference: Polls](../api-reference/polls.md)
