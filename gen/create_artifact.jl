using Tar, SHA, Inflate

# Function to create artifact for a single platform
function create_msquic_artifact()
    # Copy the library file
    libpath = "deps/vcpkg/installed/arm64-osx/debug/lib/"

    # Create tar file
    tar_file = "msquic.v2.4.8.aarch64-apple-darwin.tar.gz"
    run(`tar -C $libpath -czvf $tar_file .`)

    # Calculate SHA hashes
    sha256_hash = bytes2hex(open(sha256, tar_file))
    sha1_hash = Tar.tree_hash(IOBuffer(inflate_gzip(tar_file)))

    println("SHA256: $sha256_hash")
    println("SHA1 (approximate git-tree-sha1): $sha1_hash")

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
