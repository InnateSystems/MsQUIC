# MsQUIC.jl - Standalone MsQuic Package

## Overview

This directory contains a standalone Julia package for Microsoft's MsQuic library. The package provides a complete Julia wrapper for the MsQuic C API, enabling Julia applications to use the QUIC protocol for secure, high-performance network communication.

## Package Structure

```
MsQUIC/
├── Project.toml              # Package metadata and dependencies
├── README.md                 # Package documentation
├── src/
│   └── MsQUIC.jl            # Main module implementation
├── deps/                     # MsQuic library dependencies (copied from BareLibP2P)
│   └── vcpkg/               # vcpkg installation directory
│       └── installed/       # Installed packages
│           └── arm64-osx/   # Platform-specific installation
│               ├── lib/     # Library files
│               └── include/ # Header files
├── test/
│   └── runtests.jl          # Test suite
└── examples/
    ├── README.md            # Examples documentation
    ├── quick_test.jl        # Quick verification test
    └── basic_usage.jl       # Basic usage examples
```

## Features

- **Complete MsQuic API Wrapper**: Full Julia bindings for all MsQuic C API functions
- **Connection Management**: Create, configure, and manage QUIC connections
- **Stream Operations**: Create and manage QUIC streams with data transfer
- **Error Handling**: Comprehensive error code interpretation and handling
- **Connection Retry**: Built-in connection retry logic with configurable parameters
- **Data Transfer**: Enhanced data sending and receiving functions
- **Resource Management**: Proper cleanup and resource management without hanging

## Core Components

### Types
- `MsQuicAPI`: Main API interface for MsQuic functions
- `MsQuicRegistration`: Registration handle for MsQuic instances
- `MsQuicConfiguration`: Configuration settings for connections
- `MsQuicConnection`: Connection handle for QUIC connections
- `MsQuicStream`: Stream handle for QUIC streams
- `MsQuicListener`: Listener for accepting incoming connections

### Functions
- Connection: `connect`, `connect_with_retry`, `shutdown`
- Stream: `start_stream`, `send_data`, `shutdown_stream`, `receive_data`
- Utility: `wait_for_data`, `enable_receive`

## Installation Requirements

1. **MsQuic Library**: Installed via vcpkg in the `deps/vcpkg/` directory
2. **Julia**: Version 1.6 or higher
3. **Supported Platforms**: Windows, Linux, macOS

## Usage

```julia
using MsQUIC

# Create API instance
api = MsQuicAPI()

# Create registration and configuration
registration = MsQuicRegistration(api)
config = MsQuicConfiguration(registration, "h3")

# Create and use connection
connection = MsQuicConnection(registration)
connect(connection, config, "quic.aiortc.org", UInt16(443))

# Create and use stream
stream = MsQuicStream(connection)
start_stream(stream)
send_data(stream, "Hello QUIC!")

# Cleanup
Base.close(stream)
Base.close(connection)
Base.close(config)
Base.close(registration)
Base.close(api)
```

## Testing

Run the test suite:
```julia
using Pkg
Pkg.test("MsQUIC")
```

## Integration Status

This package contains the complete MsQuic implementation that was originally developed for BareLibP2P. All functionality has been extracted and made available as a standalone package with:

- ✅ Zero placeholders or incomplete implementations
- ✅ Full connection and stream lifecycle management
- ✅ Proper error handling and resource cleanup
- ✅ Connection retry logic
- ✅ Enhanced data transfer functions
- ✅ All tests passing
- ✅ Ready for production use

## Migration from BareLibP2P

Projects currently using MsQuic through BareLibP2P can migrate to this standalone package by:

1. Adding `MsQUIC` as a dependency
2. Changing `using BareLibP2P.MsQuic` to `using MsQUIC`
3. Updating type and function references from `BareLibP2P.MsQuic.*` to `MsQUIC.*`

The API remains identical, ensuring a seamless migration.