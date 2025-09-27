# MsQUIC.jl Basic Example

This example demonstrates basic usage of the MsQUIC.jl package.

```julia
using MsQUIC

println("=== MsQUIC.jl Basic Example ===")

# Test that all core types and functions are available
println("Testing core functionality...")

# Test type availability
types_to_test = [
    :MsQuicAPI,
    :MsQuicConnection,
    :MsQuicStream,
    :MsQuicConfiguration,
    :MsQuicRegistration
]

for type in types_to_test
    if isdefined(MsQUIC, type)
        println("  ✓ $type available")
    else
        println("  ✗ $type missing")
    end
end

# Test function availability
functions_to_test = [
    :connect,
    :start_stream,
    :send_data,
    :shutdown,
    :shutdown_stream,
    :receive_data,
    :connect_with_retry,
    :wait_for_data,
    :enable_receive
]

println("\nTesting functions...")
for func in functions_to_test
    if isdefined(MsQUIC, func)
        println("  ✓ $func available")
    else
        println("  ✗ $func missing")
    end
end

println("\n=== Example completed successfully ===")
println("\nTo use MsQUIC.jl for actual QUIC connections:")
println("1. Ensure MsQuic library is installed via vcpkg")
println("2. Create API, Registration, Configuration, and Connection objects")
println("3. Use connect() to establish connections")
println("4. Create streams with MsQuicStream()")
println("5. Send data with send_data()")
println("6. Clean up with Base.close()")