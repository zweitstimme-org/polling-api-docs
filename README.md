# Zweitstimme Polling API Documentation

Comprehensive documentation for the Zweitstimme Polling API, designed for academic researchers and political scientists.

## About

This documentation provides a complete guide to using the [Zweitstimme Polling API](https://api.fasttrack29.com), which offers access to German election polling data.

### Target Audience

- Political science researchers
- Data journalists
- Statistics students
- Anyone interested in German polling data

**No advanced technical knowledge required** — we explain everything step by step.

## Features

- **Comprehensive API documentation** with examples
- **R vignette** with practical, copy-paste ready code
- **Use case guides** for common research scenarios
- **Plain-language explanations** of technical concepts
- **Visual guides** and diagrams

## Documentation Structure

```
├── Getting Started
│   ├── Introduction           # What is an API? Why use it?
│   ├── Your First Request    # Make your first API call
│   └── Understanding Data    # Data model explained
├── API Reference
│   ├── Overview              # Common patterns, pagination
│   ├── Polls                 # Cleaned polling data
│   ├── Raw Polls            # Original scraped data
│   ├── Results              # Flattened results
│   ├── Reference Tables     # Lookups and dictionaries
│   ├── Elections            # Election metadata
│   └── Downloads            # Bulk data exports
├── R Guide
│   ├── Working with R       # Complete R tutorial
│   └── Vignette            # Comprehensive examples
└── Use Cases
    ├── Time Series Analysis
    ├── Comparing Pollsters
    └── Party Trends
```

## Quick Links

- **[View Documentation](https://docs.zweitstimme.org)** (when deployed)
- **[API Base URL](https://api.fasttrack29.com)**
- **[OpenAPI Spec](https://api.fasttrack29.com/openapi.json)**

## Getting Started

### For R Users

```r
library(httr2)

# Get recent federal polls
polls <- request("https://api.fasttrack29.com/v1/polls") |>
  req_url_query(scope = "federal", limit = 10) |>
  req_perform() |>
  resp_body_json()
```

See the [R Guide](docs/r-guide/index.md) for complete examples.

### For Python Users

```python
import requests

response = requests.get(
    "https://api.fasttrack29.com/v1/polls",
    params={"scope": "federal", "limit": 10}
)
data = response.json()
```

### For Other Languages

Any programming language that can make HTTP requests and parse JSON will work. See the [API Reference](docs/api-reference/overview.md) for endpoint details.

## Building the Documentation

This documentation is built with [MkDocs](https://www.mkdocs.org/) using the Material theme.

### Prerequisites

```bash
pip install mkdocs mkdocs-material
```

### Local Development

```bash
# Clone the repository
git clone https://github.com/zweitstimme/polling-api-docs.git
cd polling-api-docs

# Start development server
mkdocs serve

# Build for production
mkdocs build
```

The documentation will be available at `http://127.0.0.1:8000`

### Deployment

Deploy to GitHub Pages:

```bash
mkdocs gh-deploy
```

Or use any static site hosting (Netlify, Vercel, etc.).

## Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

### Areas for Contribution

- Additional use cases
- More visualization examples
- Python tutorial
- Data export examples
- Translation to German

## API Key

No API key is required for academic use. The API is open and free for research purposes.

## Rate Limits

The API has generous rate limits. If you need higher limits for large-scale research, please contact us.

## Data Attribution

When using this data in publications, please cite:

> Zweitstimme Polling API. Retrieved from https://api.fasttrack29.com

## License

This documentation is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

The API data is available for academic and research use.

## Contact

- **Website**: https://zweitstimme.org
- **API**: https://api.fasttrack29.com
- **Issues**: [GitHub Issues](https://github.com/zweitstimme/polling-api-docs/issues)

## Acknowledgments

- Data sourced from major German polling institutes
- Built with [MkDocs](https://www.mkdocs.org/) and [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/)
- R examples use [httr2](https://httr2.r-lib.org/)

## Related Projects

- [zweitstimme.org](https://zweitstimme.org) — Main project website
- [Polling API](https://api.fasttrack29.com) — The API itself

---

**Ready to start?** Head to the [Getting Started Guide](docs/getting-started/introduction.md)!
