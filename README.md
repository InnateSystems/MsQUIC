# MsQUIC.jl

A Julia wrapper for Microsoft's MsQuic library, providing a high-performance, standards-compliant QUIC protocol implementation.

## Overview

MsQUIC.jl provides Julia bindings for Microsoft's MsQuic library, enabling Julia applications to use the QUIC protocol for secure, high-performance network communication. QUIC is a modern transport protocol that provides improved performance and security over traditional TCP-based protocols.

## Features

- **Full QUIC Protocol Support**: Implements the IETF QUIC standard
- **High Performance**: Leverages Microsoft's optimized MsQuic implementation
- **Security**: Built-in TLS 1.3 support
- **Cross-Platform**: Works on Windows, Linux, and macOS
- **Connection Management**: Complete connection lifecycle management
- **Stream Operations**: Full stream creation, data transfer, and management
- **Error Handling**: Comprehensive error code interpretation and handling
- **Connection Retry**: Automatic retry logic with configurable parameters

## Installation

The package uses Julia's artifact system to automatically download the MsQuic library binaries. Simply install the package:

```julia
using Pkg
Pkg.add("MsQUIC")
```

The required MsQuic library will be automatically downloaded and installed for your platform.

## Manual Installation (Alternative)

If you prefer to manually install the MsQuic library, you can use vcpkg:

```bash
# Install vcpkg if you haven't already
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
./bootstrap-vcpkg.sh  # On Linux/macOS
# ./bootstrap-vcpkg.bat  # On Windows

# Install MsQuic
./vcpkg install msquic
```

Then install the Julia package:

```julia
using Pkg
Pkg.add("MsQUIC")
```

## Usage

```julia
using MsQUIC

# Create API instance
api = MsQuicAPI()

# Create registration
registration = MsQuicRegistration(api)

# Create configuration
config = MsQuicConfiguration(registration, "h3")  # HTTP/3 ALPN

# Create connection
connection = MsQuicConnection(registration)

# Connect to server
connect(connection, config, "quic.aiortc.org", UInt16(443))

# Create stream
stream = MsQuicStream(connection)

# Start stream
start_stream(stream)

# Send data
send_data(stream, "Hello QUIC!")

# Clean up
Base.close(stream)
Base.close(connection)
Base.close(config)
Base.close(registration)
Base.close(api)
```

## API Reference

### Core Types

- `MsQuicAPI`: Main API interface
- `MsQuicRegistration`: Registration handle
- `MsQuicConfiguration`: Configuration settings
- `MsQuicConnection`: Connection handle
- `MsQuicStream`: Stream handle

### Connection Functions

- `connect(connection, config, server_name, port)`: Establish connection
- `connect_with_retry(config, server_name, port, max_retries, retry_delay)`: Connect with retry logic
- `shutdown(connection)`: Shutdown connection gracefully

### Stream Functions

- `start_stream(stream)`: Start stream
- `send_data(stream, data)`: Send data through stream
- `shutdown_stream(stream)`: Shutdown stream gracefully
- `receive_data(stream)`: Receive data from stream
- `wait_for_data(stream, timeout)`: Wait for data with timeout
- `enable_receive(stream, enabled)`: Enable/disable receiving

## Artifact Generation

To generate artifacts for new platforms:

1. Build MsQuic for the target platform using vcpkg
2. Run the artifact generation script:
   ```julia
   include("gen/create_artifact.jl")
   ```
3. Update the Artifacts.toml file with the generated hashes
4. Upload the tarball to the GitHub releases

## Testing

Run the test suite:

```julia
using Pkg
Pkg.test("MsQUIC")
```

## Requirements

- Julia 1.6+
- Supported platforms: Windows, Linux, macOS (with pre-built artifacts)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Microsoft for the MsQuic library
- The Julia community for the excellent language and ecosystem