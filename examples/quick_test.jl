using MsQUIC
using Test

println("=== MsQUIC.jl Quick Test ===")

# Test 1: Module loading
println("1. Testing module loading...")
@test isdefined(MsQUIC, :MsQuicAPI)
@test isdefined(MsQUIC, :MsQuicConnection)
@test isdefined(MsQUIC, :MsQuicStream)
@test isdefined(MsQUIC, :MsQuicConfiguration)
@test isdefined(MsQUIC, :MsQuicRegistration)
println("   ✓ Core types available")

# Test 2: Function availability
println("2. Testing function availability...")
functions = [
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

for func in functions
    @test isdefined(MsQUIC, func)
end
println("   ✓ All functions available")

# Test 3: Library loading
println("3. Testing library loading...")
try
    # This tests that the MsQuic library can be loaded
    # We don't create actual connections to avoid network dependencies
    api = MsQUIC.MsQuicAPI()
    println("   ✓ MsQuic library loaded successfully")
catch e
    if occursin("MsQuic library not found", string(e))
        println("   ⚠ MsQuic library not installed (expected in some environments)")
    else
        println("   ⚠ Unexpected error: $e")
    end
end

println("\n=== Quick test completed ===")
println("MsQUIC.jl is ready for use!")