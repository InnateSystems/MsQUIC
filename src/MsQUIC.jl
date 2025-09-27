module MsQUIC

using Libdl
using Artifacts

export MsQuicAPI, MsQuicConnection, MsQuicStream, MsQuicConfiguration, MsQuicRegistration, MsQuicListener
export connect, listen, send_data, receive_data, close, open_stream, close_stream, start_stream
export QUIC_STATUS_SUCCESS, QUIC_STATUS_PENDING, QUIC_STATUS_CONTINUE

# Global variable to store the library handle
const libmsquic_handle = Ref{Ptr{Cvoid}}(C_NULL)

"""
    __init__()

Initialize the MsQuic library when the module is loaded.
"""
function __init__()
    # Try to load the MsQuic library from artifacts first
    lib_names = String[]
    
    # Try to load the library from the artifact
    try
        # Use the artifact string macro to get the path
        lib_path = joinpath(artifact"MsQUIC", "lib", "libmsquic.dylib")
        if isfile(lib_path)
            push!(lib_names, lib_path)
            println("Found MsQuic library in artifact: $lib_path")
        end
    catch e
        # If there's an error with the artifact system, continue with the regular approach
        @debug "Failed to load from artifact: $e"
    end
    
    # Platform-specific library names
    if Sys.isapple()
        push!(lib_names, "libmsquic.dylib")
        push!(lib_names, "/usr/local/lib/libmsquic.dylib")
        push!(lib_names, "/opt/homebrew/lib/libmsquic.dylib")
    elseif Sys.islinux()
        push!(lib_names, "libmsquic.so")
        push!(lib_names, "/usr/lib/libmsquic.so")
        push!(lib_names, "/usr/local/lib/libmsquic.so")
    elseif Sys.iswindows()
        push!(lib_names, "msquic.dll")
        push!(lib_names, "libmsquic.dll")
    end
    
    # Try to load the library
    loaded = false
    for lib_name in lib_names
        try
            libmsquic_handle[] = Libdl.dlopen(lib_name)
            loaded = true
            println("Successfully loaded MsQuic library: $lib_name")
            break
        catch e
            # Continue trying other library names
        end
    end
    
    if !loaded
        @warn "Could not load MsQuic library. Please ensure MsQuic is installed on your system."
        @warn "Supported library names: $(join(lib_names, ", "))"
    end
end

# Load the MsQuic library function
function get_libmsquic()
    if libmsquic_handle[] == C_NULL
        error("MsQuic library not loaded. Please ensure MsQuic is installed.")
    end
    return libmsquic_handle[]
end

# MsQuic API version
const MSQUIC_API_VERSION = 2

# MsQuic function types
const QUIC_HANDLE = Ptr{Cvoid}
const HQUIC = QUIC_HANDLE

# Status codes
const QUIC_STATUS_SUCCESS = 0
const QUIC_STATUS_PENDING = -2
const QUIC_STATUS_CONTINUE = 2

# Error codes
const QUIC_ERROR_NO_ERROR = 0x00000000
const QUIC_ERROR_INTERNAL_ERROR = 0x00000001
const QUIC_ERROR_CONNECTION_REFUSED = 0x00000002
const QUIC_ERROR_FLOW_CONTROL_ERROR = 0x00000003
const QUIC_ERROR_STREAM_LIMIT_ERROR = 0x00000004
const QUIC_ERROR_STREAM_STATE_ERROR = 0x00000005
const QUIC_ERROR_FINAL_SIZE_ERROR = 0x00000006
const QUIC_ERROR_FRAME_ENCODING_ERROR = 0x00000007
const QUIC_ERROR_TRANSPORT_PARAMETER_ERROR = 0x00000008
const QUIC_ERROR_CONNECTION_ID_LIMIT_ERROR = 0x00000009
const QUIC_ERROR_PROTOCOL_VIOLATION = 0x0000000A
const QUIC_ERROR_INVALID_TOKEN = 0x0000000B
const QUIC_ERROR_APPLICATION_ERROR = 0x0000000C
const QUIC_ERROR_CRYPTO_BUFFER_EXCEEDED = 0x0000000D
const QUIC_ERROR_KEY_UPDATE_ERROR = 0x0000000E
const QUIC_ERROR_AEAD_LIMIT_REACHED = 0x0000000F
const QUIC_ERROR_NO_VIABLE_PATH = 0x00000010

# Credential types
const QUIC_CREDENTIAL_TYPE_NONE = 0
const QUIC_CREDENTIAL_TYPE_CERTIFICATE_HASH = 1
const QUIC_CREDENTIAL_TYPE_CERTIFICATE_HASH_STORE = 2
const QUIC_CREDENTIAL_TYPE_CERTIFICATE_CONTEXT = 3
const QUIC_CREDENTIAL_TYPE_CERTIFICATE_FILE = 4
const QUIC_CREDENTIAL_TYPE_CERTIFICATE_FILE_PROTECTED = 5
const QUIC_CREDENTIAL_TYPE_CERTIFICATE_PKCS12 = 6

# Credential flags
const QUIC_CREDENTIAL_FLAG_NONE = 0x00000000
const QUIC_CREDENTIAL_FLAG_CLIENT = 0x00000001
const QUIC_CREDENTIAL_FLAG_LOAD_ASYNCHRONOUS = 0x00000002
const QUIC_CREDENTIAL_FLAG_NO_CERTIFICATE_VALIDATION = 0x00000004

# CREDENTIAL_CONFIG structure
struct QUIC_CREDENTIAL_CONFIG
    Type::UInt32
    Flags::UInt32
    CertificateHash::Ptr{Cvoid}  # Union field, we'll just use a pointer
    CertificateHashStore::Ptr{Cvoid}
    CertificateContext::Ptr{Cvoid}
    CertificateFile::Ptr{Cvoid}
    CertificateFileProtected::Ptr{Cvoid}
    CertificatePkcs12::Ptr{Cvoid}
    Principal::Cstring
    Reserved::Ptr{Cvoid}
    AsyncHandler::Ptr{Cvoid}
    AllowedCipherSuites::UInt32
    CaCertificateFile::Cstring
end

# Connection event types
const QUIC_CONNECTION_EVENT_TYPE_CONNECTED = 0
const QUIC_CONNECTION_EVENT_TYPE_SHUTDOWN_INITIATED_BY_TRANSPORT = 1
const QUIC_CONNECTION_EVENT_TYPE_SHUTDOWN_INITIATED_BY_PEER = 2
const QUIC_CONNECTION_EVENT_TYPE_SHUTDOWN_COMPLETE = 3
const QUIC_CONNECTION_EVENT_TYPE_LOCAL_ADDRESS_CHANGED = 4
const QUIC_CONNECTION_EVENT_TYPE_PEER_ADDRESS_CHANGED = 5
const QUIC_CONNECTION_EVENT_TYPE_PEER_STREAM_STARTED = 6
const QUIC_CONNECTION_EVENT_TYPE_STREAMS_AVAILABLE = 7
const QUIC_CONNECTION_EVENT_TYPE_PEER_NEEDS_STREAMS = 8
const QUIC_CONNECTION_EVENT_TYPE_IDEAL_PROCESSOR_CHANGED = 9
const QUIC_CONNECTION_EVENT_TYPE_DATAGRAM_STATE_CHANGED = 10
const QUIC_CONNECTION_EVENT_TYPE_DATAGRAM_RECEIVED = 11
const QUIC_CONNECTION_EVENT_TYPE_DATAGRAM_SEND_STATE_CHANGED = 12
const QUIC_CONNECTION_EVENT_TYPE_RESUMED = 13
const QUIC_CONNECTION_EVENT_TYPE_RESUMPTION_TICKET_RECEIVED = 14
const QUIC_CONNECTION_EVENT_TYPE_PEER_CERTIFICATE_RECEIVED = 15

# Stream event types
const QUIC_STREAM_EVENT_TYPE_START_COMPLETE = 0
const QUIC_STREAM_EVENT_TYPE_RECEIVE = 1
const QUIC_STREAM_EVENT_TYPE_SEND_COMPLETE = 2
const QUIC_STREAM_EVENT_TYPE_PEER_SEND_SHUTDOWN = 3
const QUIC_STREAM_EVENT_TYPE_PEER_SEND_ABORTED = 4
const QUIC_STREAM_EVENT_TYPE_PEER_RECEIVE_ABORTED = 5
const QUIC_STREAM_EVENT_TYPE_SEND_SHUTDOWN_COMPLETE = 6
const QUIC_STREAM_EVENT_TYPE_SHUTDOWN_COMPLETE = 7
const QUIC_STREAM_EVENT_TYPE_IDEAL_SEND_BUFFER_SIZE = 8
const QUIC_STREAM_EVENT_TYPE_PEER_ACCEPTED = 9
const QUIC_STREAM_EVENT_TYPE_CANCEL_ON_LOSS = 10

# QUIC_SETTINGS structure (simplified version matching Zig approach)
struct QUIC_SETTINGS
    IsSetFlags::UInt64
    MaxBytesPerKey::UInt64
    HandshakeIdleTimeoutMs::UInt64
    IdleTimeoutMs::UInt64
    MtuDiscoverySearchCompleteTimeoutUs::UInt64
    TlsClientMaxSendBuffer::UInt32
    TlsServerMaxSendBuffer::UInt32
    StreamRecvWindowDefault::UInt32
    StreamRecvBufferDefault::UInt32
    ConnFlowControlWindow::UInt32
    MaxWorkerQueueDelayUs::UInt32
    MaxStatelessOperations::UInt32
    InitialWindowPackets::UInt32
    SendIdleTimeoutMs::UInt32
    InitialRttMs::UInt32
    MaxAckDelayMs::UInt32
    DisconnectTimeoutMs::UInt32
    KeepAliveIntervalMs::UInt32
    CongestionControlAlgorithm::UInt16
    PeerBidiStreamCount::UInt16
    PeerUnidiStreamCount::UInt16
    MaxBindingStatelessOperations::UInt16
    StatelessOperationExpirationMs::UInt16
    MinimumMtu::UInt16
    MaximumMtu::UInt16
    SendBufferingEnabled::UInt8
    PacingEnabled::UInt8
    MigrationEnabled::UInt8
    DatagramReceiveEnabled::UInt8
    ServerResumptionLevel::UInt8
    MaxOperationsPerDrain::UInt8
    MtuDiscoveryMissingProbeCount::UInt8
    DestCidUpdateIdleTimeoutMs::UInt32
    Flags::UInt64
    StreamRecvWindowBidiLocalDefault::UInt32
    StreamRecvWindowBidiRemoteDefault::UInt32
    StreamRecvWindowUnidiDefault::UInt32
end

# Address family
const QUIC_ADDRESS_FAMILY_UNSPEC = 0
const QUIC_ADDRESS_FAMILY_INET = 2
const QUIC_ADDRESS_FAMILY_INET6 = 30

# Stream flags
const QUIC_STREAM_OPEN_FLAG_NONE = 0x0000
const QUIC_STREAM_OPEN_FLAG_UNIDIRECTIONAL = 0x0001

const QUIC_STREAM_START_FLAG_NONE = 0x0000
const QUIC_STREAM_START_FLAG_IMMEDIATE = 0x0001

const QUIC_STREAM_SHUTDOWN_FLAG_NONE = 0x0000
const QUIC_STREAM_SHUTDOWN_FLAG_GRACEFUL = 0x0001
const QUIC_STREAM_SHUTDOWN_FLAG_ABORT_SEND = 0x0002
const QUIC_STREAM_SHUTDOWN_FLAG_ABORT_RECEIVE = 0x0004

const QUIC_SEND_FLAG_NONE = 0x0000
const QUIC_SEND_FLAG_ALLOW_0_RTT = 0x0001
const QUIC_SEND_FLAG_START = 0x0002
const QUIC_SEND_FLAG_FIN = 0x0004

# Connection shutdown flags
const QUIC_CONNECTION_SHUTDOWN_FLAG_NONE = 0x0000
const QUIC_CONNECTION_SHUTDOWN_FLAG_SILENT = 0x0001

# Function pointer types
const QUIC_SET_CONTEXT_FN = Ptr{Cvoid}
const QUIC_GET_CONTEXT_FN = Ptr{Cvoid}
const QUIC_SET_CALLBACK_HANDLER_FN = Ptr{Cvoid}
const QUIC_SET_PARAM_FN = Ptr{Cvoid}
const QUIC_GET_PARAM_FN = Ptr{Cvoid}
const QUIC_REGISTRATION_OPEN_FN = Ptr{Cvoid}
const QUIC_REGISTRATION_CLOSE_FN = Ptr{Cvoid}
const QUIC_REGISTRATION_SHUTDOWN_FN = Ptr{Cvoid}
const QUIC_CONFIGURATION_OPEN_FN = Ptr{Cvoid}
const QUIC_CONFIGURATION_CLOSE_FN = Ptr{Cvoid}
const QUIC_CONFIGURATION_LOAD_CREDENTIAL_FN = Ptr{Cvoid}
const QUIC_LISTENER_OPEN_FN = Ptr{Cvoid}
const QUIC_LISTENER_CLOSE_FN = Ptr{Cvoid}
const QUIC_LISTENER_START_FN = Ptr{Cvoid}
const QUIC_LISTENER_STOP_FN = Ptr{Cvoid}
const QUIC_CONNECTION_OPEN_FN = Ptr{Cvoid}
const QUIC_CONNECTION_CLOSE_FN = Ptr{Cvoid}
const QUIC_CONNECTION_SHUTDOWN_FN = Ptr{Cvoid}
const QUIC_CONNECTION_START_FN = Ptr{Cvoid}
const QUIC_CONNECTION_SET_CONFIGURATION_FN = Ptr{Cvoid}
const QUIC_CONNECTION_SEND_RESUMPTION_FN = Ptr{Cvoid}
const QUIC_STREAM_OPEN_FN = Ptr{Cvoid}
const QUIC_STREAM_CLOSE_FN = Ptr{Cvoid}
const QUIC_STREAM_START_FN = Ptr{Cvoid}
const QUIC_STREAM_SHUTDOWN_FN = Ptr{Cvoid}
const QUIC_STREAM_SEND_FN = Ptr{Cvoid}
const QUIC_STREAM_RECEIVE_COMPLETE_FN = Ptr{Cvoid}
const QUIC_STREAM_RECEIVE_SET_ENABLED_FN = Ptr{Cvoid}
const QUIC_DATAGRAM_SEND_FN = Ptr{Cvoid}

# QUIC API Table structure
struct QUIC_API_TABLE
    SetContext::QUIC_SET_CONTEXT_FN
    GetContext::QUIC_GET_CONTEXT_FN
    SetCallbackHandler::QUIC_SET_CALLBACK_HANDLER_FN
    SetParam::QUIC_SET_PARAM_FN
    GetParam::QUIC_GET_PARAM_FN
    RegistrationOpen::QUIC_REGISTRATION_OPEN_FN
    RegistrationClose::QUIC_REGISTRATION_CLOSE_FN
    RegistrationShutdown::QUIC_REGISTRATION_SHUTDOWN_FN
    ConfigurationOpen::QUIC_CONFIGURATION_OPEN_FN
    ConfigurationClose::QUIC_CONFIGURATION_CLOSE_FN
    ConfigurationLoadCredential::QUIC_CONFIGURATION_LOAD_CREDENTIAL_FN
    ListenerOpen::QUIC_LISTENER_OPEN_FN
    ListenerClose::QUIC_LISTENER_CLOSE_FN
    ListenerStart::QUIC_LISTENER_START_FN
    ListenerStop::QUIC_LISTENER_STOP_FN
    ConnectionOpen::QUIC_CONNECTION_OPEN_FN
    ConnectionClose::QUIC_CONNECTION_CLOSE_FN
    ConnectionShutdown::QUIC_CONNECTION_SHUTDOWN_FN
    ConnectionStart::QUIC_CONNECTION_START_FN
    ConnectionSetConfiguration::QUIC_CONNECTION_SET_CONFIGURATION_FN
    ConnectionSendResumptionTicket::QUIC_CONNECTION_SEND_RESUMPTION_FN
    StreamOpen::QUIC_STREAM_OPEN_FN
    StreamClose::QUIC_STREAM_CLOSE_FN
    StreamStart::QUIC_STREAM_START_FN
    StreamShutdown::QUIC_STREAM_SHUTDOWN_FN
    StreamSend::QUIC_STREAM_SEND_FN
    StreamReceiveComplete::QUIC_STREAM_RECEIVE_COMPLETE_FN
    StreamReceiveSetEnabled::QUIC_STREAM_RECEIVE_SET_ENABLED_FN
    DatagramSend::QUIC_DATAGRAM_SEND_FN
    ConnectionResumptionTicketValidationComplete::Ptr{Cvoid}
    ConnectionCertificateValidationComplete::Ptr{Cvoid}
end

# QUIC structures
struct QUIC_BUFFER
    Length::UInt32
    Buffer::Ptr{UInt8}
end

struct QUIC_REGISTRATION_CONFIG
    AppName::Cstring
    ExecutionProfile::UInt32
end

# Callback function types
const QUIC_CONNECTION_CALLBACK = Ptr{Cvoid}
const QUIC_STREAM_CALLBACK = Ptr{Cvoid}
const QUIC_LISTENER_CALLBACK = Ptr{Cvoid}

# Connection parameters
const QUIC_PARAM_CONN_SETTINGS = 0x05000004

# MsQuic API functions
function msquic_open()
    api = Ref{Ptr{QUIC_API_TABLE}}(C_NULL)
    status = ccall((:MsQuicOpenVersion, get_libmsquic()), Cint, (UInt32, Ptr{Ptr{QUIC_API_TABLE}}), MSQUIC_API_VERSION, api)
    return status, api[]
end

# Set parameter function
function set_param(api_table_ptr::Ptr{QUIC_API_TABLE}, handle::Ptr{Cvoid}, param::UInt32, buffer_length::UInt32, buffer::Ptr{Cvoid})
    # Get the API table
    api_table = unsafe_load(api_table_ptr)
    return ccall(api_table.SetParam, Cint, (Ptr{Cvoid}, UInt32, UInt32, Ptr{Cvoid}), 
                 handle, param, buffer_length, buffer)
end

# Global storage for received data
const received_data = Dict{HQUIC, String}()

# C function for StreamReceiveComplete
function stream_receive_complete(api_table::Ptr{QUIC_API_TABLE}, stream::HQUIC, buffer_length::UInt64)
    # Get the API table
    api = unsafe_load(api_table)
    # Call the StreamReceiveComplete function from the API table
    return ccall(unsafe_load(api.StreamReceiveComplete), Cint, (HQUIC, UInt64), stream, buffer_length)
end

# C function for StreamReceiveSetEnabled
function stream_receive_set_enabled(api_table::Ptr{QUIC_API_TABLE}, stream::HQUIC, enabled::Bool)
    # Get the API table
    api = unsafe_load(api_table)
    # Call the StreamReceiveSetEnabled function from the API table
    flags = enabled ? 1 : 0  # QUIC_RECEIVE_FLAG_NONE or appropriate flag
    return ccall(unsafe_load(api.StreamReceiveSetEnabled), Cint, (HQUIC, UInt32), stream, flags)
end

function msquic_close(api_table)
    ccall((:MsQuicClose, get_libmsquic()), Cvoid, (Ptr{QUIC_API_TABLE},), api_table)
end

# MsQuic API wrapper
mutable struct MsQuicAPI
    api_table::Ptr{QUIC_API_TABLE}
    function MsQuicAPI()
        status, api = msquic_open()
        if status != QUIC_STATUS_SUCCESS
            error("Failed to open MsQuic: $status")
        end
        new(api)
    end
end

function Base.close(api::MsQuicAPI)
    if api.api_table != C_NULL
        msquic_close(api.api_table)
        api.api_table = C_NULL
    end
end

# MsQuic registration
mutable struct MsQuicRegistration
    handle::HQUIC
    api::MsQuicAPI
    function MsQuicRegistration(api::MsQuicAPI)
        handle = Ref{HQUIC}(C_NULL)
        # Get the API table
        api_table = unsafe_load(api.api_table)
        # Create registration config
        app_name = "BareLibP2P"
        config = QUIC_REGISTRATION_CONFIG(Base.unsafe_convert(Cstring, app_name), 0)  # QUIC_EXECUTION_PROFILE_LOW_LATENCY
        # Call the RegistrationOpen function from the API table
        status = ccall(api_table.RegistrationOpen, Cint, (Ref{QUIC_REGISTRATION_CONFIG}, Ptr{HQUIC}), 
                       Ref(config), handle)
        if status != QUIC_STATUS_SUCCESS
            error("Failed to create MsQuic registration: $status")
        end
        new(handle[], api)
    end
end

function Base.close(reg::MsQuicRegistration)
    if reg.handle != C_NULL
        # Get the API table
        api_table = unsafe_load(reg.api.api_table)
        # Call the RegistrationClose function
        ccall(api_table.RegistrationClose, Cvoid, (HQUIC,), reg.handle)
        reg.handle = C_NULL
    end
end

# Global storage for connection states and shutdown completion
const connection_states = Dict{Ptr{Cvoid}, Symbol}()
const connection_shutdown_complete = Dict{Ptr{Cvoid}, Bool}()

# C function for connection callback
function connection_callback(connection::Ptr{Cvoid}, context::Ptr{Cvoid}, event::Ptr{Cvoid})::Cint
    # Get the event type
    event_type = unsafe_load(reinterpret(Ptr{Cint}, event))
    
    #println("DEBUG: Connection callback called with connection: $connection, event type: $event_type")
    
    # Print debug information
    println("DEBUG: Connection callback called with connection: $connection, event type: $event_type")
    
    # Check if the connection is already closed
    # This is a simple check to prevent processing events after the connection is closed
    local conn_closed = (connection == C_NULL)
    
    # Print debug information
    if haskey(connection_states, connection)
        local current_state = connection_states[connection]
        println("DEBUG: Connection state in callback: $current_state")
    else
        println("DEBUG: Connection state in callback: not in global state")
    end
    
    if event_type == QUIC_CONNECTION_EVENT_TYPE_CONNECTED
        # Connection established
        if !conn_closed
            connection_states[connection] = :connected
        end
        println("DEBUG: Connection established")
    elseif event_type == QUIC_CONNECTION_EVENT_TYPE_SHUTDOWN_INITIATED_BY_TRANSPORT
        # Transport initiated shutdown
        if !conn_closed
            connection_states[connection] = :shutdown_transport
        end
        println("DEBUG: Connection shutdown initiated by transport")
        # Print the error code
        error_code = unsafe_load(reinterpret(Ptr{UInt64}, event + 8))  # Offset to get error code
        # Convert error code to hex
        error_hex = string(error_code, base=16)
        println("DEBUG: Transport shutdown error code: $error_code (0x$error_hex)")
        # Check if it's a known error
        if error_code == 0x00000000
            println("DEBUG: Error: NO_ERROR")
        elseif error_code == 0x00000001
            println("DEBUG: Error: INTERNAL_ERROR")
        elseif error_code == 0x00000002
            println("DEBUG: Error: CONNECTION_REFUSED")
        elseif error_code == 0x00000003
            println("DEBUG: Error: FLOW_CONTROL_ERROR")
        elseif error_code == 0x00000004
            println("DEBUG: Error: STREAM_LIMIT_ERROR")
        elseif error_code == 0x00000005
            println("DEBUG: Error: STREAM_STATE_ERROR")
        elseif error_code == 0x00000006
            println("DEBUG: Error: FINAL_SIZE_ERROR")
        elseif error_code == 0x00000007
            println("DEBUG: Error: FRAME_ENCODING_ERROR")
        elseif error_code == 0x00000008
            println("DEBUG: Error: TRANSPORT_PARAMETER_ERROR")
        elseif error_code == 0x00000009
            println("DEBUG: Error: CONNECTION_ID_LIMIT_ERROR")
        elseif error_code == 0x0000000A
            println("DEBUG: Error: PROTOCOL_VIOLATION")
        elseif error_code == 0x0000000B
            println("DEBUG: Error: INVALID_TOKEN")
        elseif error_code == 0x0000000C
            println("DEBUG: Error: APPLICATION_ERROR")
        elseif error_code == 0x0000000D
            println("DEBUG: Error: CRYPTO_BUFFER_EXCEEDED")
        elseif error_code == 0x0000000E
            println("DEBUG: Error: KEY_UPDATE_ERROR")
        elseif error_code == 0x0000000F
            println("DEBUG: Error: AEAD_LIMIT_REACHED")
        elseif error_code == 0x00000010
            println("DEBUG: Error: NO_VIABLE_PATH")
        else
            # Check if it's a TLS error
            if (error_code & 0xFFFFFF0000000000) == 0x600000000000
                tls_error = error_code & 0xFF
                println("DEBUG: Error: TLS error $tls_error")
            else
                println("DEBUG: Error: Unknown error code")
            end
        end
    elseif event_type == QUIC_CONNECTION_EVENT_TYPE_SHUTDOWN_INITIATED_BY_PEER
        # Peer initiated shutdown
        if !conn_closed
            connection_states[connection] = :shutdown_peer
        end
        println("DEBUG: Connection shutdown initiated by peer")
        # Print the error code
        error_code = unsafe_load(reinterpret(Ptr{UInt64}, event + 8))  # Offset to get error code
        # Convert error code to hex
        error_hex = string(error_code, base=16)
        println("DEBUG: Peer shutdown error code: $error_code (0x$error_hex)")
        # Check if it's a known error
        if error_code == 0x00000000
            println("DEBUG: Error: NO_ERROR")
        elseif error_code == 0x00000001
            println("DEBUG: Error: INTERNAL_ERROR")
        elseif error_code == 0x00000002
            println("DEBUG: Error: CONNECTION_REFUSED")
        elseif error_code == 0x00000003
            println("DEBUG: Error: FLOW_CONTROL_ERROR")
        elseif error_code == 0x00000004
            println("DEBUG: Error: STREAM_LIMIT_ERROR")
        elseif error_code == 0x00000005
            println("DEBUG: Error: STREAM_STATE_ERROR")
        elseif error_code == 0x00000006
            println("DEBUG: Error: FINAL_SIZE_ERROR")
        elseif error_code == 0x00000007
            println("DEBUG: Error: FRAME_ENCODING_ERROR")
        elseif error_code == 0x00000008
            println("DEBUG: Error: TRANSPORT_PARAMETER_ERROR")
        elseif error_code == 0x00000009
            println("DEBUG: Error: CONNECTION_ID_LIMIT_ERROR")
        elseif error_code == 0x0000000A
            println("DEBUG: Error: PROTOCOL_VIOLATION")
        elseif error_code == 0x0000000B
            println("DEBUG: Error: INVALID_TOKEN")
        elseif error_code == 0x0000000C
            println("DEBUG: Error: APPLICATION_ERROR")
        elseif error_code == 0x0000000D
            println("DEBUG: Error: CRYPTO_BUFFER_EXCEEDED")
        elseif error_code == 0x0000000E
            println("DEBUG: Error: KEY_UPDATE_ERROR")
        elseif error_code == 0x0000000F
            println("DEBUG: Error: AEAD_LIMIT_REACHED")
        elseif error_code == 0x00000010
            println("DEBUG: Error: NO_VIABLE_PATH")
        else
            # Check if it's a TLS error
            if (error_code & 0xFFFFFF0000000000) == 0x600000000000
                tls_error = error_code & 0xFF
                println("DEBUG: Error: TLS error $tls_error")
            else
                println("DEBUG: Error: Unknown error code")
            end
        end
    elseif event_type == QUIC_CONNECTION_EVENT_TYPE_SHUTDOWN_COMPLETE
        # Shutdown complete
        if !conn_closed
            connection_states[connection] = :shutdown_complete
            connection_shutdown_complete[connection] = true
        end
        println("DEBUG: Connection shutdown complete")
        # Remove from states when fully closed
        # Only remove if the connection is not already closed
        if !conn_closed && haskey(connection_states, connection)
            delete!(connection_states, connection)
        end
        if !conn_closed && haskey(connection_shutdown_complete, connection)
            delete!(connection_shutdown_complete, connection)
        end
    elseif event_type == QUIC_CONNECTION_EVENT_TYPE_PEER_STREAM_STARTED
        # New stream started by peer
        println("DEBUG: Peer stream started")
    elseif event_type == QUIC_CONNECTION_EVENT_TYPE_PEER_CERTIFICATE_RECEIVED
        # Certificate received
        println("DEBUG: Peer certificate received")
        # Accept the certificate
        # This is where we would normally validate the certificate
        # But since we're using NO_CERTIFICATE_VALIDATION, we should accept it
        # The certificate validation is handled by the MsQuic library
        # when we set the QUIC_CREDENTIAL_FLAG_NO_CERTIFICATE_VALIDATION flag
        # So we don't need to do anything here
    end
    
    # Return success
    return QUIC_STATUS_SUCCESS
end

# Global storage for stream states and received data
const stream_states = Dict{Ptr{Cvoid}, Symbol}()
const stream_received_data = Dict{Ptr{Cvoid}, Vector{UInt8}}()

# C function for stream callback
function stream_callback(stream::Ptr{Cvoid}, context::Ptr{Cvoid}, event::Ptr{Cvoid})::Cint
    # Get the event type
    event_type = unsafe_load(reinterpret(Ptr{Cint}, event))
    
    #println("DEBUG: Stream callback called with stream: $stream, event type: $event_type")
    
    if event_type == QUIC_STREAM_EVENT_TYPE_START_COMPLETE
        # Stream start complete
        stream_states[stream] = :started
        println("DEBUG: Stream start complete")
    elseif event_type == QUIC_STREAM_EVENT_TYPE_RECEIVE
        # Data received
        stream_states[stream] = :receiving
        println("DEBUG: Data received")
        # Extract the data from the event
        # The event structure for RECEIVE has the buffer information
        # For now, we'll just acknowledge the data
        # In a full implementation, we would extract the data and store it
        # The RECEIVE event structure:
        # - Offset 0: EventType (4 bytes)
        # - Offset 4: Reserved (4 bytes)
        # - Offset 8: BufferCount (4 bytes)
        # - Offset 12: Flags (1 byte)
        # - Offset 16: Buffer pointer
        # For now, we'll just acknowledge all received data
        # Try to extract the actual data
        try
            # Extract the buffer from the event
            buffer = unsafe_load(reinterpret(Ptr{QUIC_BUFFER}, event + 16))
            if buffer.Length > 0
                # Read the data
                data_bytes = unsafe_wrap(Vector{UInt8}, buffer.Buffer, buffer.Length)
                # Store the data in the global storage
                if haskey(stream_received_data, stream)
                    # Append to existing data
                    stream_received_data[stream] = vcat(stream_received_data[stream], data_bytes)
                else
                    # Create new data
                    stream_received_data[stream] = data_bytes
                end
                # Print the received data
                data_string = String(data_bytes)
                println("Received data: $data_string")
            end
        catch e
            # Handle the error in the receive
        end
    elseif event_type == QUIC_STREAM_EVENT_TYPE_SEND_COMPLETE
        # Send complete
        stream_states[stream] = :send_complete
        println("DEBUG: Send complete")
    elseif event_type == QUIC_STREAM_EVENT_TYPE_SHUTDOWN_COMPLETE
        # Stream shutdown complete
        stream_states[stream] = :shutdown_complete
        println("DEBUG: Stream shutdown complete")
        # Clean up
        if haskey(stream_states, stream)
            delete!(stream_states, stream)
        end
        if haskey(stream_received_data, stream)
            delete!(stream_received_data, stream)
        end
    end
    
    # Return success
    return QUIC_STATUS_SUCCESS
end

# MsQuic connection
mutable struct MsQuicConnection
    handle::Ptr{Cvoid}
    api::MsQuicAPI
    registration::MsQuicRegistration
    state::Symbol  # :new, :connecting, :connected, :shutdown_transport, :shutdown_peer, :shutdown_complete
    function MsQuicConnection(registration::MsQuicRegistration)
        handle = Ref{Ptr{Cvoid}}(C_NULL)
        # Get the API table
        api_table = unsafe_load(registration.api.api_table)
        # Create a callback handler
        callback_handler = @cfunction(connection_callback, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}))
        # Call the ConnectionOpen function from the API table
        status = ccall(api_table.ConnectionOpen, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Ptr{Cvoid}}), 
                       registration.handle, callback_handler, C_NULL, handle)
        if status != QUIC_STATUS_SUCCESS
            error("Failed to create MsQuic connection: $status")
        end
        # Initialize the connection state in the global dictionary
        connection_states[handle[]] = :new
        new(handle[], registration.api, registration, :new)
    end
end

function Base.close(conn::MsQuicConnection)
    if conn.handle != C_NULL
        # Get the API table
        api_table = unsafe_load(conn.api.api_table)
        
        # Check if connection is already in shutdown state
        if haskey(connection_states, conn.handle)
            current_state = connection_states[conn.handle]
            println("DEBUG: Connection current state: $current_state")
        end
        
        # Mark that we're initiating shutdown
        connection_shutdown_complete[conn.handle] = false
        
        # Instead of directly calling ConnectionClose, we'll use ConnectionShutdown first
        # This is a more proper way to close connections in MsQuic
        println("DEBUG: Calling ConnectionShutdown...")
        shutdown_flags = QUIC_CONNECTION_SHUTDOWN_FLAG_NONE
        error_code = UInt64(0)  # Normal shutdown
        ccall(api_table.ConnectionShutdown, Cvoid, (Ptr{Cvoid}, UInt32, UInt64), 
              conn.handle, shutdown_flags, error_code)
        println("DEBUG: ConnectionShutdown returned")
        
        # Check if the connection is already in shutdown state
        if haskey(connection_states, conn.handle)
            current_state = connection_states[conn.handle]
            if current_state == :shutdown_complete
                println("DEBUG: Connection is already in shutdown complete state, skipping wait")
                # Set the connection handle to NULL to prevent further operations
                conn.handle = C_NULL
                conn.state = :shutdown_complete
                return
            end
        end
        
        # Wait for the connection to be fully closed with a timeout
        timeout = 5.0  # 5 seconds timeout
        start_time = time()
        while !get(connection_shutdown_complete, conn.handle, false) && (time() - start_time) < timeout
            # Check if we've reached shutdown complete state
            if get(connection_shutdown_complete, conn.handle, false)
                break
            end
            # Small sleep to avoid busy waiting
            sleep(0.01)
        end
        
        # Check if we timed out
        if !get(connection_shutdown_complete, conn.handle, false)
            println("DEBUG: Connection shutdown timed out, forcing close...")
            # Force the connection to shutdown complete state
            connection_states[conn.handle] = :shutdown_complete
            connection_shutdown_complete[conn.handle] = true
        else
            println("DEBUG: Connection shutdown completed normally")
        end
        
        # Remove from global state if it exists
        if haskey(connection_states, conn.handle)
            println("DEBUG: Removing connection from global state")
            delete!(connection_states, conn.handle)
        end
        if haskey(connection_shutdown_complete, conn.handle)
            delete!(connection_shutdown_complete, conn.handle)
        end
        
        # Set the connection handle to NULL before calling ConnectionClose
        # This prevents the callback from being processed after the connection is closed
        handle = conn.handle
        conn.handle = C_NULL
        conn.state = :shutdown_complete
        
        # Now call ConnectionClose to clean up resources
        # But only if the handle was valid
        if handle != C_NULL
            println("DEBUG: Calling ConnectionClose...")
            ccall(api_table.ConnectionClose, Cvoid, (Ptr{Cvoid},), handle)
            println("DEBUG: ConnectionClose returned")
        end
        
        # Note: We don't close the registration here as it might be used by other connections
        println("DEBUG: Connection close completed")
    end
end

# MsQuic configuration
mutable struct MsQuicConfiguration
    handle::HQUIC
    api::MsQuicAPI
    function MsQuicConfiguration(registration::MsQuicRegistration, alpn::String)
        handle = Ref{HQUIC}(C_NULL)
        # Get the API table
        api_table = unsafe_load(registration.api.api_table)
        # Create ALPN buffer
        alpn_bytes = Vector{UInt8}(alpn)
        alpn_length = UInt32(length(alpn_bytes))
        alpn_buffer = QUIC_BUFFER(alpn_length, pointer(alpn_bytes))
        # Create QUIC settings (matching Zig approach)
        settings = QUIC_SETTINGS(
            0x00000000000C0004,  # IsSetFlags (IdleTimeoutMs + ConnFlowControlWindow + PeerBidiStreamCount)
            0,  # MaxBytesPerKey
            0,  # HandshakeIdleTimeoutMs
            5000,  # IdleTimeoutMs (5 seconds like Zig)
            0,  # MtuDiscoverySearchCompleteTimeoutUs
            0,  # TlsClientMaxSendBuffer
            0,  # TlsServerMaxSendBuffer
            0,  # StreamRecvWindowDefault
            0,  # StreamRecvBufferDefault
            0x8000000,  # ConnFlowControlWindow (128MB like Zig)
            0,  # MaxWorkerQueueDelayUs
            0,  # MaxStatelessOperations
            0,  # InitialWindowPackets
            0,  # SendIdleTimeoutMs
            0,  # InitialRttMs
            0,  # MaxAckDelayMs
            0,  # DisconnectTimeoutMs
            0,  # KeepAliveIntervalMs
            1,  # CongestionControlAlgorithm (CUBIC like Zig)
            1024,  # PeerBidiStreamCount (1024 like Zig)
            0,  # PeerUnidiStreamCount
            0,  # MaxBindingStatelessOperations
            0,  # StatelessOperationExpirationMs
            0,  # MinimumMtu
            0,  # MaximumMtu
            0,  # SendBufferingEnabled
            0,  # PacingEnabled
            0,  # MigrationEnabled
            0,  # DatagramReceiveEnabled
            3,  # ServerResumptionLevel (QUIC_SERVER_RESUME_AND_ZERORTT)
            0,  # MaxOperationsPerDrain
            0,  # MtuDiscoveryMissingProbeCount
            0,  # DestCidUpdateIdleTimeoutMs
            0,  # Flags
            0,  # StreamRecvWindowBidiLocalDefault
            0,  # StreamRecvWindowBidiRemoteDefault
            0   # StreamRecvWindowUnidiDefault
        )
        settings_size = UInt32(sizeof(QUIC_SETTINGS))
        context = C_NULL
        # Call the ConfigurationOpen function from the API table
        status = ccall(api_table.ConfigurationOpen, Cint, (HQUIC, Ptr{QUIC_BUFFER}, UInt32, Ptr{QUIC_SETTINGS}, UInt32, Ptr{Cvoid}, Ptr{HQUIC}), 
                       registration.handle, Ref(alpn_buffer), 1, Ref(settings), settings_size, context, handle)
        if status != QUIC_STATUS_SUCCESS
            error("Failed to create MsQuic configuration: $status")
        end
        # Load credentials
        # Create a zero-initialized credential configuration
        # This is similar to what CxPlatZeroMemory does in the C code
        # We explicitly set all fields to ensure proper initialization
        cred_config = QUIC_CREDENTIAL_CONFIG(
            QUIC_CREDENTIAL_TYPE_NONE,  # Type
            QUIC_CREDENTIAL_FLAG_CLIENT | QUIC_CREDENTIAL_FLAG_NO_CERTIFICATE_VALIDATION,  # Flags
            C_NULL,  # CertificateHash
            C_NULL,  # CertificateHashStore
            C_NULL,  # CertificateContext
            C_NULL,  # CertificateFile
            C_NULL,  # CertificateFileProtected
            C_NULL,  # CertificatePkcs12
            C_NULL,  # Principal
            C_NULL,  # Reserved
            C_NULL,  # AsyncHandler
            0,       # AllowedCipherSuites
            C_NULL   # CaCertificateFile
        )
        # Note: In the C code, CxPlatZeroMemory is used to zero-initialize
        # the entire structure. In Julia, we're explicitly setting
        # all fields to zero/null to achieve the same effect
        # Call the ConfigurationLoadCredential function from the API table
        status = ccall(api_table.ConfigurationLoadCredential, Cint, (HQUIC, Ref{QUIC_CREDENTIAL_CONFIG}), 
                       handle[], Ref(cred_config))
        if status != QUIC_STATUS_SUCCESS
            error("Failed to load credentials for MsQuic configuration: $status")
        end
        new(handle[], registration.api)
    end
end

function Base.close(config::MsQuicConfiguration)
    if config.handle != C_NULL
        # Get the API table
        api_table = unsafe_load(config.api.api_table)
        # Call the ConfigurationClose function
        ccall(api_table.ConfigurationClose, Cvoid, (HQUIC,), config.handle)
        config.handle = C_NULL
    end
end

function connect(conn::MsQuicConnection, config::MsQuicConfiguration, server_name::String, server_port::UInt16)
    # Update state
    conn.state = :connecting
    # Get the API table
    api_table = unsafe_load(conn.api.api_table)
    
    # Set connection parameters like the Zig code does
    # Disable send buffering if needed (this is what the Zig code does)
    # For now, let's just try to set some basic parameters
    
    # Call the ConnectionStart function from the API table
    # Convert server name to C string
    c_server_name = Base.unsafe_convert(Cstring, server_name)
    # Set address family (unspecified to let MsQuic choose)
    family = QUIC_ADDRESS_FAMILY_UNSPEC
    status = ccall(api_table.ConnectionStart, Cint, (HQUIC, HQUIC, UInt32, Cstring, UInt16), 
                   conn.handle, config.handle, family, c_server_name, server_port)
    # QUIC_STATUS_PENDING is normal for async operations, not an error
    # We should return true when the connection is initiated, even if it's pending
    if status == QUIC_STATUS_SUCCESS || status == QUIC_STATUS_PENDING
        println("Connection started to $server_name:$server_port using MsQuic (status: $status)")
        # Note: The connection state will be updated by the callback
        return true
    else
        println("Failed to start connection to $server_name:$server_port using MsQuic: $status")
        conn.state = :shutdown_transport
        return false
    end
end

function connect_with_retry(config::MsQuicConfiguration, server_name::String, server_port::UInt16, max_retries::Int = 3, retry_delay::Float64 = 1.0)
    # Create a new registration and connection for each attempt
    # This ensures we have a clean connection state for each retry
    for attempt in 1:max_retries
        println("Connection attempt $attempt/$max_retries to $server_name:$server_port")
        
        # Create new registration and connection for this attempt
        try
            registration = MsQuicRegistration(config.api)
            connection = MsQuicConnection(registration)
            
            # Try to connect
            result = connect(connection, config, server_name, server_port)
            if result
                # Wait for connection to establish or fail
                timeout = 5.0  # 5 seconds timeout
                start_time = time()
                while connection.state == :connecting && (time() - start_time) < timeout
                    if haskey(connection_states, connection.handle)
                        current_state = connection_states[connection.handle]
                        if current_state == :connected
                            println("✓ Connection established successfully on attempt $attempt")
                            return (connection, registration, true)  # Success
                        elseif current_state == :shutdown_transport || current_state == :shutdown_peer
                            break
                        end
                    end
                    sleep(0.1)
                end
                
                # Check if connection was successful
                if haskey(connection_states, connection.handle)
                    current_state = connection_states[connection.handle]
                    if current_state == :connected
                        println("✓ Connection established successfully on attempt $attempt")
                        return (connection, registration, true)  # Success
                    end
                end
            end
            
            # If we get here, the connection failed
            println("Connection attempt $attempt failed")
            
            # Clean up resources
            if connection.handle != C_NULL
                Base.close(connection)
            end
            Base.close(registration)
            
            # Wait before retrying (except on the last attempt)
            if attempt < max_retries
                println("Waiting $retry_delay seconds before retry...")
                sleep(retry_delay)
            end
        catch e
            println("Error during connection attempt $attempt: $e")
            # Wait before retrying (except on the last attempt)
            if attempt < max_retries
                println("Waiting $retry_delay seconds before retry...")
                sleep(retry_delay)
            end
        end
    end
    
    println("All $max_retries connection attempts failed")
    return (nothing, nothing, false)  # Failure
end

function shutdown(conn::MsQuicConnection)
    if conn.handle != C_NULL
        # Get the API table
        api_table = unsafe_load(conn.api.api_table)
        # Call the ConnectionShutdown function
        shutdown_flags = QUIC_CONNECTION_SHUTDOWN_FLAG_NONE
        error_code = UInt64(0)  # Normal shutdown
        ccall(api_table.ConnectionShutdown, Cvoid, (Ptr{Cvoid}, UInt32, UInt64), 
              conn.handle, shutdown_flags, error_code)
        conn.state = :shutdown_initiated
    end
end

# MsQuic stream
mutable struct MsQuicStream
    handle::HQUIC
    connection::MsQuicConnection
    state::Symbol  # :new, :started, :receiving, :send_complete, :shutdown_complete
    function MsQuicStream(connection::MsQuicConnection)
        handle = Ref{HQUIC}(C_NULL)
        # Get the API table
        api_table = unsafe_load(connection.api.api_table)
        # Create a callback handler
        callback_handler = @cfunction(stream_callback, Cint, (HQUIC, Ptr{Cvoid}, Ptr{Cvoid}))
        # Call the StreamOpen function from the API table
        flags = QUIC_STREAM_OPEN_FLAG_NONE
        status = ccall(api_table.StreamOpen, Cint, (HQUIC, UInt32, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{HQUIC}), 
                       connection.handle, flags, callback_handler, C_NULL, handle)
        if status != QUIC_STATUS_SUCCESS
            error("Failed to create MsQuic stream: $status")
        end
        # Initialize the stream state in the global dictionary
        stream_states[handle[]] = :new
        new(handle[], connection, :new)
    end
end

function Base.close(stream::MsQuicStream)
    if stream.handle != C_NULL
        # Get the API table
        api_table = unsafe_load(stream.connection.api.api_table)
        # Call the StreamClose function from the API table
        ccall(api_table.StreamClose, Cvoid, (HQUIC,), stream.handle)
        stream.handle = C_NULL
        stream.state = :shutdown_complete
        # Also update the global state
        if haskey(stream_states, stream.handle)
            delete!(stream_states, stream.handle)
        end
        if haskey(stream_received_data, stream.handle)
            delete!(stream_received_data, stream.handle)
        end
    end
end

function start_stream(stream::MsQuicStream)
    # Get the API table
    api_table = unsafe_load(stream.connection.api.api_table)
    # Call the StreamStart function from the API table
    flags = QUIC_STREAM_START_FLAG_NONE
    status = ccall(api_table.StreamStart, Cint, (HQUIC, UInt32), stream.handle, flags)
    # QUIC_STATUS_PENDING is normal for async operations, not an error
    # We should return true when the stream start is initiated, even if it's pending
    if status == QUIC_STATUS_SUCCESS || status == QUIC_STATUS_PENDING
        println("Stream started using MsQuic (status: $status)")
        # Note: The stream state will be updated by the callback
        return true
    else
        println("Failed to start stream using MsQuic: $status")
        return false
    end
end

function enable_receive(stream::MsQuicStream, enabled::Bool = true)
    # Enable or disable receiving data on the stream
    # Get the API table
    api_table = unsafe_load(stream.connection.api.api_table)
    # Call the StreamReceiveSetEnabled function
    try
        return stream_receive_set_enabled(api_table, stream.handle, enabled)
    catch e
        println("Warning: Failed to enable receive: $e")
        return false
    end
end

function shutdown_stream(stream::MsQuicStream)
    if stream.handle != C_NULL
        # Get the API table
        api_table = unsafe_load(stream.connection.api.api_table)
        # Call the StreamShutdown function
        shutdown_flags = QUIC_STREAM_SHUTDOWN_FLAG_GRACEFUL
        error_code = UInt64(0)  # Normal shutdown
        status = ccall(api_table.StreamShutdown, Cint, (Ptr{Cvoid}, UInt32, UInt64), 
                       stream.handle, shutdown_flags, error_code)
        if status == QUIC_STATUS_SUCCESS || status == QUIC_STATUS_PENDING
            stream.state = :shutdown_initiated
            return true
        else
            println("Failed to shutdown stream: $status")
            return false
        end
    end
end

function send_data(stream::MsQuicStream, data::String)
    # Get the API table
    api_table = unsafe_load(stream.connection.api.api_table)
    # Convert data to C format
    data_bytes = Vector{UInt8}(data)
    data_length = UInt32(length(data_bytes))
    # Create QUIC_BUFFER
    buffer = QUIC_BUFFER(data_length, pointer(data_bytes))
    # Call the StreamSend function from the API table
    flags = QUIC_SEND_FLAG_NONE
    status = ccall(api_table.StreamSend, Cint, (HQUIC, Ptr{QUIC_BUFFER}, UInt32, UInt32, Ptr{Cvoid}), 
                   stream.handle, Ref(buffer), 1, flags, C_NULL)
    # QUIC_STATUS_PENDING is normal for async operations, not an error
    # We should return true when the send is initiated, even if it's pending
    if status == QUIC_STATUS_SUCCESS || status == QUIC_STATUS_PENDING
        println("Data sent using MsQuic (status: $status): $data")
        # Note: The stream state will be updated by the callback
        return true
    else
        println("Failed to send data using MsQuic: $status")
        return false
    end
end

function receive_data(stream::MsQuicStream)
    # Check if we have received data for this stream
    if haskey(stream_received_data, stream.handle)
        data_bytes = stream_received_data[stream.handle]
        # Convert to string
        data_string = String(data_bytes)
        # Clear the data
        delete!(stream_received_data, stream.handle)
        return data_string
    end
    # Check the current stream state
    if haskey(stream_states, stream.handle)
        current_state = stream_states[stream.handle]
        if current_state == :receiving
            return "Data is being received..."
        elseif current_state == :send_complete
            return "Data was sent successfully"
        elseif current_state == :started
            return "Stream is started, waiting for data..."
        elseif current_state == :shutdown_complete
            return "Stream closed"
        end
    end
    # If no data and stream is not active, return appropriate message
    if stream.handle == C_NULL
        return "Stream closed"
    else
        return "No data available"
    end
end

function wait_for_data(stream::MsQuicStream, timeout::Float64 = 5.0)
    # Wait for data to be received
    start_time = time()
    while (time() - start_time) < timeout
        if haskey(stream_received_data, stream.handle)
            return receive_data(stream)
        end
        # Check if the stream is in a receiving state
        if haskey(stream_states, stream.handle)
            current_state = stream_states[stream.handle]
            if current_state == :shutdown_complete
                return "Stream closed"
            end
        end
        sleep(0.1)
    end
    return "Timeout waiting for data"
end

# MsQuic listener
mutable struct MsQuicListener
    handle::HQUIC
    api::MsQuicAPI
    registration::MsQuicRegistration
    function MsQuicListener(api::MsQuicAPI)
        handle = Ref{HQUIC}(C_NULL)
        # Create a listener using the API
        status = listener_open(api.api_table, api.api_table, handle)
        if status != QUIC_STATUS_SUCCESS
            error("Failed to create MsQuic listener: $status")
        end
        new(handle[], api, MsQuicRegistration(api))
    end
end

function Base.close(listener::MsQuicListener)
    if listener.handle != C_NULL
        # Get the API table
        api = unsafe_load(listener.api.api_table)
        # Call the ListenerClose function
        ccall(unsafe_load(api.ListenerClose), Cvoid, (HQUIC,), listener.handle)
        listener.handle = C_NULL
        close(listener.registration)
    end
end

function listen(listener::MsQuicListener, config::MsQuicConfiguration, port::UInt16)
    if listener.handle == C_NULL
        error("Listener is closed")
    end
    
    # Start the listener
    status = listener_start(listener.api.api_table, listener.handle, config.handle, port)
    if status != QUIC_STATUS_SUCCESS
        println("Failed to start listener on port $port using MsQuic: $status")
        return false
    end
    println("Listening on port $port using MsQuic")
    return true
end

function stop(listener::MsQuicListener)
    if listener.handle != C_NULL
        # Get the API table
        api_table = unsafe_load(listener.api.api_table)
        # Call the ListenerStop function
        ccall(unsafe_load(api_table.ListenerStop), Cvoid, (HQUIC,), listener.handle)
    end
end

end # module MsQUIC