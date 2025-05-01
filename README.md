# Client Search

A command-line interface and REST API for searching client data.

## Table of Contents
- [Client Search](#client-search)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Installation](#installation)
    - [Prerequisites](#prerequisites)
    - [Setup Steps](#setup-steps)
    - [Environment Configuration](#environment-configuration)
  - [CLI Usage](#cli-usage)
    - [Search by Field](#search-by-field)
    - [Using Custom JSON Files](#using-custom-json-files)
    - [Duplicate Email Detection](#duplicate-email-detection)
    - [Output Formats](#output-formats)
    - [Version Information](#version-information)
  - [REST API](#rest-api)
    - [Starting the Server](#starting-the-server)
    - [API Endpoints](#api-endpoints)
      - [Search for Clients](#search-for-clients)
      - [Find Duplicate Emails](#find-duplicate-emails)
      - [Health Check](#health-check)
  - [Implementation Details](#implementation-details)
    - [Design Decisions](#design-decisions)
    - [Limitations and Future Work](#limitations-and-future-work)

## Overview

This tool provides both a command-line interface (CLI) and a REST API for searching client information. The CLI allows searching client data from either a remote API or local JSON files, while the REST API exposes HTTP endpoints for programmatic access to the same search functionality.

## Installation

### Prerequisites
- Ruby 2.7.0 or higher
- Bundler gem

### Setup Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/code-jojo/client-search.git
   cd client-search
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Set up Git hooks (optional but recommended for development):
   ```bash
   bin/setup_git_hooks
   ```
   This installs hooks that run Rubocop and tests before each commit to ensure code quality and functionality.

4. Build and install the gem:
   ```bash
   gem build client-search.gemspec
   gem install client-search-[VERSION].gem
   ```

### Environment Configuration

Create a `.env` file in the root directory with your API credentials:
```
SHIFTCARE_API_URL=https://api.example.com
```

## CLI Usage

### Search by Field

Search for clients by any field available in the data:

```bash
# Search by full name
client_search search "John Doe" --field=full_name

# Search by email
client_search search "example@email.com" --field=email

# Search by ID
client_search search "1234" --field=id
```

### Using Custom JSON Files

You can use any JSON file as a data source:

```bash
client_search search "John" --file=path/to/clients.json
```

### Duplicate Email Detection

Identify and list duplicate email records:

```bash
# Check default data source
client_search duplicates

# Check custom JSON file
client_search duplicates --file=path/to/clients.json
```

### Output Formats

Specify different output formats for your results:

```bash
# Table format (default)
client_search search "John Doe"

# JSON format
client_search search "John Doe" --format=json
```

### Version Information

Display the current version:

```bash
client_search version
```

## REST API

The tool also provides a REST API server for accessing the client search functionality through HTTP requests.

### Starting the Server

```bash
# Start with default port (3000)
client_search_api

# Start with custom port
PORT=8080 client_search_api
```

### API Endpoints

#### Search for Clients
```
GET http://localhost:3000/query?q=John%20Doe&field=full_name
```

**Parameters:**
- `q`: (Required) The search term
- `field`: (Optional) The field to search in (default: `full_name`)

**Example response:**
```json
{
  "results": [
    {
      "id": "123",
      "full_name": "John Doe",
      "email": "john@example.com"
    }
  ]
}
```

#### Find Duplicate Emails
```
GET http://localhost:3000/duplicates
```

**Parameters:**
- `file`: (Optional) Path to a custom JSON file

**Example response:**
```json
{
  "results": {
    "duplicate@example.com": [
      {
        "id": "123",
        "full_name": "John Doe",
        "email": "duplicate@example.com"
      },
      {
        "id": "456",
        "full_name": "Jane Smith",
        "email": "duplicate@example.com"
      }
    ]
  }
}
```

#### Health Check
```
GET http://localhost:3000/health
```

**Example response:**
```json
{
  "status": "ok", 
  "version": "0.1.0"
}
```

## Implementation Details

### Design Decisions

1. **Search Logic**: 
   - Multi-word searches require all terms to appear in the client's full name
   - Single-word searches match complete words in names or are contained in emails
   - Both exact and partial matches are supported when searching by specific fields

2. **API Communication**:
   - Uses HTTParty for API requests
   - Fetches all clients and filters locally (assumes moderate dataset size)
   - Supports custom JSON files as alternative data sources

3. **Error Handling**:
   - Provides descriptive error messages for common HTTP errors
   - Gracefully handles missing fields in client data
   - Validates custom JSON files before processing

4. **Output Formats**:
   - Default tabular output optimized for terminal readability
   - JSON format available for integration with other tools
   - Dynamic field display adapts to the structure of your data

### Limitations and Future Work

1. **Performance**:
   - Currently fetches all clients before filtering, which may be inefficient for large datasets
   - Could be improved by implementing server-side filtering if API supports it

2. **Search Capabilities**:
   - Search capabilities now extended to any field in the data
   - Future improvements could include more complex search conditions and sorting options

3. **Authentication**:
   - Basic API URL configuration
   - Could be enhanced with proper authentication methods
   - REST API server currently has no authentication

4. **Data Display**:
   - Currently displays up to 5 important fields from the data
   - Could be expanded to allow customizing which fields to display
