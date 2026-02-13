# R Guide Overview

Welcome to the R guide for the Zweitstimme Polling API. This section provides progressive documentation from simple requests to advanced analysis.

## What's in This Guide

### [Working with R](index.md) — Start Here
A progressive guide from basics to advanced:
- **Level 1**: Simple requests (fetch data, check status)
- **Level 2**: Working with data (transform, filter, analyze)
- **Level 3**: Visualization and advanced analysis
- **Helper Functions**: Reusable code snippets

### [Complete Workflow Examples](complete-examples.md)
End-to-end workflows for real research scenarios:
- Time series analysis with rolling averages
- Institute comparison and house effects
- Coalition scenario analysis
- Exporting data for external tools

## Quick Start

### Installation

```r
install.packages(c("httr2", "dplyr", "purrr", "ggplot2", "lubridate"))
```

### Level 1: Your First Request

```r
library(httr2)

# Simple request - just fetch and check
response <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(scope = "federal", limit = 5) |>
  req_perform()

resp_status(response)  # Should be 200
data <- resp_body_json(response)
```

### Level 2: Work with the Data

```r
library(dplyr)
library(purrr)

# Transform to data frame
df <- map_dfr(data$items, function(poll) {
  map_dfr(poll$results, function(result) {
    tibble(
      date = as.Date(poll$publish_date),
      party = result$party_short_name,
      percentage = result$percentage
    )
  })
})

# Simple analysis
df |>
  group_by(party) |>
  summarise(avg = mean(percentage))
```

### Level 3: Visualize

```r
library(ggplot2)

# Create a plot
ggplot(df, aes(x = date, y = percentage, color = party)) +
  geom_line() +
  theme_minimal()
```

## Recommended Learning Path

### Beginners
1. **[Working with R - Level 1](index.md)** — Master basic requests
2. **[Working with R - Level 2](index.md)** — Learn data transformation
3. **Practice** with your own queries

### Intermediate Users
1. **[Working with R - Level 3](index.md)** — Advanced visualization
2. **[Complete Workflow Examples](complete-examples.md)** — See full analyses
3. **[Use Cases](../use-cases/time-series.md)** — Specific scenarios

### Advanced Users
1. **[Complete Workflow Examples](complete-examples.md)** — Complex workflows
2. **[Use Cases](../use-cases/time-series.md)** — Specialized techniques
3. **[Data & Pipeline](../data-pipeline/index.md)** — Understanding data sources

## Code Philosophy

All code examples follow these principles:

- **Progressive complexity** — Start simple, add layers
- **Copy-paste ready** — Run immediately in R
- **Clean and modern** — Using current best practices
- **Well-commented** — Explains the "why" not just "what"
- **Practical** — Based on real research needs

## Getting Help

If you encounter issues:

1. Check the [API status](https://api.fasttrack29.com/health)
2. Review error messages carefully
3. Verify your query parameters
4. See the [troubleshooting section](../getting-started/first-request.md#troubleshooting)

## Best Practices Summary

1. **Start simple** — Get basic requests working first
2. **Filter early** — Use API parameters, not R filtering
3. **Check status** — Always verify response codes
4. **Transform systematically** — Use purrr for list-to-data-frame conversion
5. **Visualize incrementally** — Build plots step by step

## Additional Resources

- [httr2 documentation](https://httr2.r-lib.org/)
- [tidyverse documentation](https://www.tidyverse.org/)
- [ggplot2 documentation](https://ggplot2.tidyverse.org/)

## See Also

- [Getting Started Guide](../getting-started/introduction.md) — API basics
- [Data & Pipeline](../data-pipeline/index.md) — Understanding data
- [API Reference](../api-reference/overview.md) — Endpoint details
- [Use Cases](../use-cases/time-series.md) — Advanced scenarios
