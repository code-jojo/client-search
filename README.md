# Client Search CLI

A command-line interface for searching client data.

## Overview

This CLI tool provides a simple, efficient way to search for client information using the API or custom JSON files.

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

3. Set up Git hooks (optional but recommended for development):
   ```
   bin/setup_git_hooks
   ```
   This installs hooks that run Rubocop and tests before each commit to ensure code quality and functionality.

4. Build and install the gem:
   ```   gem build client-search-cli.gemspec
   gem install client-search-cli-[VERSION].gem
   ```

4. Environment configuration:
   Create a `.env` file in the root directory with your API credentials:
   ```
   SHIFTCARE_API_URL=https://api.example.com
   ```

## Usage

### Search by Any Field
Search for clients by any field available in the data:
```
client_search search "John Doe" --field=full_name
client_search search "example@email.com" --field=email
client_search search "1234" --field=id
```

### Using Custom JSON Files
You can use any JSON file as a data source:
```
client_search search "John" --file=path/to/clients.json
```

### Duplicate Email Detection
Identify and list duplicate email records:
```
client_search duplicates
```

You can also find duplicates in a custom JSON file:
```
client_search duplicates --file=path/to/clients.json
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

### Version Information
Display the current version:
```
client_search version
```

## Assumptions and Decisions Made

1. **Search Logic**: 
   - For multi-word searches, all terms must appear in the client's full name
   - For single-word searches, the term must match a complete word in the name or be contained in the email
   - When searching by other fields, both exact matches and partial matches are supported

2. **API Communication**:
   - Uses HTTParty to handle API requests
   - Fetches all clients and performs filtering locally (assuming moderate dataset size)
   - Supports custom JSON files as data sources

3. **Error Handling**:
   - Provides descriptive error messages for common HTTP errors
   - Gracefully handles missing fields in client data
   - Validates custom JSON files before processing

4. **Output Formats**:
   - Default tabular output for terminal readability
   - JSON format for integration with other tools
   - Dynamic field display adapts to the structure of your data

## Known Limitations and Areas for Future Improvement

1. **Performance**:
   - Currently fetches all clients before filtering, which may be inefficient for large datasets
   - Could be improved by implementing server-side filtering if API supports it

2. **Search Capabilities**:
   - Search capabilities now extended to any field in the data
   - Future improvements could include more complex search conditions and sorting options

3. **Authentication**:
   - Basic API URL configuration
   - Could be enhanced with proper authentication methods

4. **Data Display**:
   - Currently displays up to 5 important fields from the data
   - Could be expanded to allow customizing which fields to display
