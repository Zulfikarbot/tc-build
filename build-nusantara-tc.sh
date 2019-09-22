#!/usr/bin/env bash
# Script to build a toolchain specialized for Chips Kernel development

# Exit on error
set -e

# Function to show an informational message
function msg() {
    echo -e "\e[1;32m$@\e[0m"
}

# Configure LLVM build based on environment or arguments
msg "Configuring reduced LLVM build for CI..."
llvm_args=(--targets "X86;ARM;AArch64")
binutils_args=(--targets arm aarch64 x86_64)

# Build LLVM
msg "Building LLVM..."
./build-llvm.py \
	--clang-vendor "NusantaraDevs" \
	--projects "clang;compiler-rt;lld;polly" \
	--pgo \
	--no-update \
	"${llvm_args[@]}"

# Build binutils
msg "Building binutils..."
./build-binutils.py \
	"${binutils_args[@]}"

# Remove unused products
msg "Removing unused products..."
rm -fr install/include
rm -f install/lib/*.a install/lib/*.la

# Strip remaining products
msg "Stripping remaining products..."
for f in $(find install -type f -exec file {} \; | grep 'not stripped' | awk '{print $1}'); do
	strip ${f: : -1}
done

# Set glob var git acc
git config --global user.email "najahiii@outlook.co.id"
git config --global user.name "Ahmad Thoriq Najahi"

# Grab some commits history by using some hack
git clone https://github.com/NusantaraDevs/clang.git -b dev/10.0 clang
cp -r clang/.git install/

# Push eeet
msg "Pushing compiled toolchains to Github..."
chmod -R 777 install
cd install
rm .gitignore
git add . -f
git commit -m "[$(date +'%d%m%Y')]: NusantaraDevs LLVM Clang 10.0.0" --signoff
git remote rm origin
git remote add origin https://najahiiii:$token@github.com/NusantaraDevs/clang.git
git push origin dev/10.0
