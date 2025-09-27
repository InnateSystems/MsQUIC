#!/bin/bash

# Build script for MsQuic
set -e

# Check if we're in the right directory
if [ ! -d "msquic" ]; then
    echo "Error: msquic directory not found"
    exit 1
fi

cd msquic

# Create build directory
mkdir -p build
cd build

# Configure with CMake
echo "Configuring MsQuic with CMake..."
cmake .. -DCMAKE_BUILD_TYPE=Release -DQUIC_BUILD_SHARED=ON

# Build MsQuic
echo "Building MsQuic..."
make -j$(nproc)

echo "MsQuic build completed successfully!"
echo "Libraries are in: $(pwd)/lib"