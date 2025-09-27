# MsQUIC.jl Examples

This directory contains examples demonstrating how to use the MsQUIC.jl package.

## Basic Connection Example

```julia
using MsQUIC

# Create API instance
api = MsQuicAPI()

# Create registration
registration = MsQuicRegistration(api)

# Create configuration with HTTP/3 ALPN
config = MsQuicConfiguration(registration, "h3")

# Create connection
connection = MsQuicConnection(registration)

# Connect to a QUIC server
if connect(connection, config, "quic.aiortc.org", UInt16(443))
    println("Connected successfully!")
    
    # Create a stream
    stream = MsQuicStream(connection)
    
    # Start the stream
    if start_stream(stream)
        println("Stream started!")
        
        # Send some data
        if send_data(stream, "Hello from MsQUIC.jl!")
            println("Data sent successfully!")
        end
        
        # Try to receive data
        data = receive_data(stream)
        println("Received: $data")
        
        # Clean up stream
        Base.close(stream)
    end
    
    # Clean up connection
    Base.close(connection)
else
    println("Failed to connect")
end

# Clean up
Base.close(config)
Base.close(registration)
Base.close(api)
```

## Connection with Retry Example

```julia
using MsQUIC

# Create API and configuration
api = MsQuicAPI()
registration = MsQuicRegistration(api)
config = MsQuicConfiguration(registration, "h3")

# Connect with retry logic (3 attempts, 1 second delay)
connection, new_registration, success = connect_with_retry(
    config, "quic.aiortc.org", UInt16(443), 3, 1.0
)

if success
    println("Connected successfully with retry!")
    
    # Use the connection...
    
    # Clean up
    Base.close(connection)
    Base.close(new_registration)
else
    println("Failed to connect after retries")
end

# Clean up
Base.close(config)
Base.close(registration)
Base.close(api)
```

## Stream Data Transfer Example

```julia
using MsQUIC

# Create API instance
api = MsQuicAPI()
registration = MsQuicRegistration(api)
config = MsQuicConfiguration(registration, "h3")
connection = MsQuicConnection(registration)

# Connect
if connect(connection, config, "quic.aiortc.org", UInt16(443))
    # Create and start stream
    stream = MsQuicStream(connection)
    
    if start_stream(stream)
        # Send multiple data packets
        messages = ["Hello", "World", "from", "MsQUIC"]
        for msg in messages
            if send_data(stream, msg)
                println("Sent: $msg")
            end
        end
        
        # Wait for data with timeout
        data = wait_for_data(stream, 5.0)
        println("Received: $data")
        
        # Enable receiving
        enable_receive(stream, true)
        
        # Shutdown stream gracefully
        shutdown_stream(stream)
        Base.close(stream)
    end
    
    Base.close(connection)
end

# Clean up
Base.close(config)
Base.close(registration)
Base.close(api)
```