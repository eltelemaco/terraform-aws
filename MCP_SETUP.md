# MCP Server Configuration for Context7

This document provides guidance on setting up the Context7 MCP server in VS Code.

## Installation Options

### Option 1: npm/npx Installation
```bash
# If context7 is available via npm
npm install -g context7

# Or run via npx
npx context7
```

### Option 2: Binary Installation
```bash
# Download and install context7 binary
# Follow the official context7 installation guide
```

### Option 3: Local Development
```bash
# If you have the context7 source code
git clone https://github.com/context7/context7.git
cd context7
npm install
npm run build
```

## VS Code Configuration

The MCP server configuration has been added to `.vscode/settings.json`:

```json
{
  "mcp.servers": {
    "context7": {
      "command": "context7",
      "args": [],
      "env": {},
      "description": "Context7 MCP Server for enhanced code context"
    }
  }
}
```

## Alternative Configuration Options

If context7 requires specific arguments or environment variables:

```json
{
  "mcp.servers": {
    "context7": {
      "command": "npx",
      "args": ["context7", "--config", "context7.config.json"],
      "env": {
        "CONTEXT7_API_KEY": "your-api-key",
        "CONTEXT7_MODE": "development"
      },
      "description": "Context7 MCP Server"
    }
  }
}
```

## Troubleshooting

1. **Command not found**: Ensure context7 is installed and in your PATH
2. **Permission issues**: Run VS Code as administrator if needed
3. **Config issues**: Check the MCP server logs in VS Code developer tools

## Usage

Once configured, context7 should provide enhanced context awareness for:
- Code understanding
- Project structure analysis
- Intelligent suggestions
- Context-aware completions

## Next Steps

1. Install context7 using your preferred method
2. Update the command path in `.vscode/settings.json` if needed
3. Restart VS Code to apply the configuration
4. Check the MCP server status in VS Code
