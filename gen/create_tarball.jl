using Tar, SHA

# Create artifact for MsQUIC
function create_msquic_artifact()
    # Create temporary directory with the correct structure
    tmp_dir = mktempdir()
    lib_dir = joinpath(tmp_dir, "lib")
    mkdir(lib_dir)

    # Copy the actual library file (not the symlink)
    cp("$(homedir())/.julia/dev/MsQUIC/vcpkg/installed/arm64-osx/lib/libmsquic.2.4.8.dylib",
       joinpath(lib_dir, "libmsquic.dylib"))

    # Create tarball
    tar_file = "$(homedir())/.julia/dev/MsQUIC/artifacts/msquic.v2.4.8.aarch64-apple-darwin.tar.gz"
    Tar.create(tmp_dir, tar_file)

    # Calculate SHA hashes
    sha256_hash = bytes2hex(open(sha256, tar_file))
    # For git-tree-sha1, we need to decompress and calculate tree hash
    sha1_hash = Tar.tree_hash(open(tar_file, "r"))

    println("SHA256: $sha256_hash")
    println("git-tree-sha1: $sha1_hash")

    # Clean up
    rm(tmp_dir, recursive=true)

    return sha1_hash, sha256_hash
end

# Run the function
sha1, sha256 = create_msquic_artifact()
println("Artifact creation completed")
