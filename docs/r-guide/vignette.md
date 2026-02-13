# R Guide Overview

Welcome to the R guide for the Zweitstimme Polling API. This section provides comprehensive documentation for using the API with R.

## What's in This Guide

### [Working with R](index.md)
Complete guide to using the API with R and httr2, including:
- Setting up your environment
- Making API requests
- Data transformation techniques
- Visualization examples
- Advanced techniques

### [Vignette - Practical Examples](vignette.md)
Comprehensive R vignette with:
- Complete workflow examples
- Statistical analysis techniques
- Ready-to-use code
- Reproducible examples

## Quick Start

### Installation

```r
install.packages(c("httr2", "dplyr", "purrr", "ggplot2", "lubridate"))
```

### Your First Request

```r
library(httr2)

polls <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(scope = "federal", limit = 10) |>
  req_perform() |>
  resp_body_json()
```

### Convert to Data Frame

```r
library(dplyr)
library(purrr)

df <- map_dfr(polls$items, function(poll) {
  map_dfr(poll$results, function(result) {
    tibble(
      date = as.Date(poll$publish_date),
      party = result$party_short_name,
      percentage = result$percentage
    )
  })
})
```

## Recommended Learning Path

1. **Start with [Working with R](index.md)** — Learn the basics
2. **Read the [Vignette](vignette.md)** — See complete examples
3. **Explore [Use Cases](../use-cases/time-series.md)** — Advanced techniques
4. **Check [API Reference](../api-reference/overview.md)** — Endpoint details

## Code Examples

All code examples in this guide are:
- **Copy-paste ready** — Run them directly in R
- **Fully documented** — Comments explain each step
- **Progressive** — Start simple, build complexity
- **Practical** — Based on real research scenarios

## Getting Help

If you encounter issues:

1. Check the [API status](https://api.fasttrack29.com/health)
2. Review error messages carefully
3. Verify your query parameters
4. See the [troubleshooting section](../getting-started/first-request.md#troubleshooting)

## Best Practices

1. **Always filter your queries** — Don't fetch everything
2. **Use pagination** — For large datasets
3. **Cache reference data** — It rarely changes
4. **Handle missing values** — Some fields can be NULL
5. **Respect rate limits** — Add delays between requests

## Additional Resources

- [httr2 documentation](https://httr2.r-lib.org/)
- [tidyverse documentation](https://www.tidyverse.org/)
- [ggplot2 documentation](https://ggplot2.tidyverse.org/)

## R Markdown Reports

Want to create reports? See the vignette for R Markdown examples.

```markdown
---
title: "My Polling Analysis"
output: html_document
---

```{r}
library(httr2)
# Your analysis code here
```
```

## See Also

- [Getting Started Guide](../getting-started/introduction.md)
- [API Reference](../api-reference/overview.md)
- [Use Cases](../use-cases/time-series.md)
