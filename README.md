# Go Toolchain Setup for WSL Ubuntu 22.04

An idempotent bash script that sets up a complete Go development environment on Ubuntu 22.04 WSL with version management via asdf.

## Features

- ✅ **Idempotent**: Safe to run multiple times without side effects
- 🔄 **Version Management**: Install and manage multiple Go versions using asdf
- 🛠️ **Complete Toolchain**: Installs essential Go development tools
- 🐳 **Docker Ready**: Includes Docker installation
- ⚡ **WSL Optimized**: Configures systemd for WSL environment
- 📦 **Essential Tools**: Pre-installs gopls, delve, golangci-lint, and more

## Quick Start

```bash
# Install latest Go version
bash install-go-wsl.sh

# Install specific Go versions
bash install-go-wsl.sh -v "1.23.3 1.24.5"

# Install only specified versions (removes others)
bash install-go-wsl.sh -v "1.23.3" --only
```

## Prerequisites

- Ubuntu 22.04 WSL environment
- Internet connection for downloading packages

## What Gets Installed

### System Packages
- Build tools: `build-essential`, `git`, `curl`, `wget`
- Development utilities: `tar`, `unzip`, `ca-certificates`
- Networking tools: `iproute2`, `net-tools`, `htop`
- Containerization: `docker.io`

### Go Version Manager
- **asdf** v0.13.1 with Go plugin for version management

### Go Development Tools
- `gopls` - Go Language Server
- `dlv` - Delve debugger
- `golangci-lint` - Linter aggregator
- `staticcheck` - Static analysis tool
- `mockgen` - Mock generation
- `stringer` - String method generator
- `govulncheck` - Vulnerability scanner

## Usage Options

### Basic Installation
```bash
bash install-go-wsl.sh
```
Installs the latest available Go version if no Go is currently installed.

### Specific Versions
```bash
bash install-go-wsl.sh -v "1.23.3 1.24.5 1.25.0"
```
Ensures the specified Go versions are installed. Existing versions remain untouched.

### Exclusive Installation
```bash
bash install-go-wsl.sh -v "1.23.3" --only
```
Installs Go 1.23.3 and removes any other installed Go versions.

### Help
```bash
bash install-go-wsl.sh --help
```

## Environment Configuration

The script automatically configures your shell environment:

```bash
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export PATH="$GOBIN:$PATH"
```

These settings are added to both `~/.profile` and `~/.bashrc`.

## WSL Integration

- Enables systemd in WSL for better service management
- After first run, restart WSL with `wsl --shutdown` from Windows to apply systemd changes

## Post-Installation

After successful installation:

1. **Restart your WSL session** to ensure all environment variables are loaded
2. **Verify installation**:
   ```bash
   go version
   asdf list go
   gopls version
   ```

## Version Management

Switch between installed Go versions:
```bash
# Set global Go version
asdf global go 1.23.3

# Set local Go version for current project
asdf local go 1.24.5

# List installed versions
asdf list go

# List all available versions
asdf list-all go
```

## Troubleshooting

### Script Fails on OS Check
Ensure you're running Ubuntu 22.04:
```bash
lsb_release -dr
```

### Environment Variables Not Set
Reload your shell configuration:
```bash
source ~/.bashrc
```

### Go Tools Not Found
Reshim asdf after installing new tools:
```bash
asdf reshim go
```

## Contributing

Feel free to submit issues and enhancement requests!

## License

This script is provided as-is for educational and development purposes.