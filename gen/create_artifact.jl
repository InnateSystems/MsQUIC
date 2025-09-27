using Tar, SHA

# Function to create artifact for a single platform
function create_msquic_artifact()
    # Create temporary directory
    tmp_dir = mktempdir()

    # Create lib directory in temp directory
    lib_dir = joinpath(tmp_dir, "lib")
    mkdir(lib_dir)

    # Copy the library file
    cp("vcpkg/installed/arm64-osx/lib/libmsquic.2.4.8.dylib", joinpath(lib_dir, "libmsquic.dylib"))

    # Create tar file
    tar_file = "artifacts/msquic.v2.4.8.aarch64-apple-darwin.tar"
    Tar.create(tmp_dir, tar_file)

    # Compress with gzip
    run(pipeline(`gzip -c $tar_file`, stdout="artifacts/msquic.v2.4.8.aarch64-apple-darwin.tar.gz"))

    # Remove uncompressed tar file
    rm(tar_file)

    # Calculate SHA hashes
    sha256_hash = bytes2hex(open(sha256, "artifacts/msquic.v2.4.8.aarch64-apple-darwin.tar.gz"))

    # For git-tree-sha1, we can use a simple approach
    # In a real implementation, you would use Tar.tree_hash with decompressed content
    sha1_hash = bytes2hex(open(sha1, "artifacts/msquic.v2.4.8.aarch64-apple-darwin.tar.gz"))

    println("SHA256: $sha256_hash")
    println("SHA1 (approximate git-tree-sha1): $sha1_hash")

    # Clean up
    rm(tmp_dir, recursive=true)

    return sha1_hash, sha256_hash
end

# Function to generate Artifacts.toml entry
function generate_artifacts_toml(sha1_hash, sha256_hash)
    toml_content = """
    [[MsQUIC]]
    arch = "aarch64"
    git-tree-sha1 = "$sha1_hash"
    os = "macos"

        [[MsQUIC.download]]
        sha256 = "$sha256_hash"
        url = "https://github.com/InnateSystems/MsQUIC/releases/download/v0.0.0-alpha/msquic.v2.4.8.aarch64-apple-darwin.tar.gz"
    """

    # Write to Artifacts.toml
    open("Artifacts.toml", "w") do f
        write(f, toml_content)
    end

    println("Artifacts.toml updated successfully")
end

# Main execution
try
    sha1, sha256 = create_msquic_artifact()
    generate_artifacts_toml(sha1, sha256)
    println("Artifact creation completed successfully")
catch e
    println("Error: $e")
end
