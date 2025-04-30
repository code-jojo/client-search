# Client Search CLI

A command-line interface for searching client data.

## Overview

This CLI tool provides a simple, efficient way to search for client information using the API. It's designed for users who prefer command-line workflows and need to quickly find client details without accessing the web interface.

## Setup and Installation

### Prerequisites
- Ruby 2.7.0 or higher
- Bundler gem

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/code-jojo/client-search-cli.git
   cd client-search-cli
   ```

2. Install dependencies:
   ```
   bundle install
   ```

3. Build and install the gem:
   ```
   gem build client-search-cli.gemspec
   gem install client-search-cli-[VERSION].gem
   ```

4. Environment configuration:
   Create a `.env` file in the root directory with your API credentials:
   ```
   SHIFTCARE_API_URL=https://api.example.com
   ```

## Usage

### Basic Search
Search for clients by name:
```
client_search search "John Doe"
```

### Output Formats
You can specify different output formats:

- Table format (default):
  ```
  client_search search "John Doe"
  ```

- JSON format:
  ```
  client_search search "John Doe" --format=json
  ```

- CSV format:
  ```
  client_search search "John Doe" --format=csv
  ```

### Duplicate Email Detection
Identify and list duplicate email records:
```
client_search duplicates
```

This command finds duplicate emails in the dataset.

### Version Information
Display the current version:
```
client_search version
```

## Assumptions and Decisions Made

1. **Search Logic**: 
   - For multi-word searches, all terms must appear in the client's full name
   - For single-word searches, the term must match a complete word in the name or be contained in the email

2. **API Communication**:
   - Uses HTTParty to handle API requests
   - Fetches all clients and performs filtering locally (assuming moderate dataset size)

3. **Error Handling**:
   - Provides descriptive error messages for common HTTP errors
   - Gracefully handles missing fields in client data

4. **Output Formats**:
   - Default tabular output for terminal readability
   - JSON format for integration with other tools
   - CSV format for export to spreadsheet applications

## Known Limitations and Areas for Future Improvement

1. **Performance**:
   - Currently fetches all clients before filtering, which may be inefficient for large datasets
   - Could be improved by implementing server-side filtering if API supports it

2. **Search Capabilities**:
   - Limited to name-based searches
   - Future improvements could include searching by other attributes like phone, email, or ID

3. **Authentication**:
   - Basic API URL configuration
   - Could be enhanced with proper authentication methods

4. **Data Display**:
   - Limited information displayed in the results
   - Could be expanded to show more client details or allow fetching specific client information