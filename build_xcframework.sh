#!/bin/bash

# Script to build iOS and macOS frameworks and create an xcframework for mars.

# Define repeated path constants
IOS_DEVICE_DIR="cmake_build/iOS/iOS.out/mars.ios.framework"
IOS_SIMULATOR_DIR="cmake_build/iOS/iOS.out/mars.simulator.framework"
MACOS_FRAMEWORK_DIR="cmake_build/OSX/Darwin.out/mars.framework"
XCFRAMEWORK_OUTPUT="cmake_build/mars.xcframework"

# Change directory to the project folder
cd mars

# Build for iOS and macOS
python3 build_ios.py 2
python3 build_osx.py 3

# Define library binary paths (assuming static or dynamic libraries inside the framework)
IOS_DEVICE_LIB="$IOS_DEVICE_DIR/mars.a"
IOS_SIMULATOR_LIB="$IOS_SIMULATOR_DIR/mars.a"
MACOS_LIB="$MACOS_FRAMEWORK_DIR/mars.a"

# Define header path (assuming the headers are inside a "Headers" directory)
HEADERS_PATH="$IOS_DEVICE_DIR/Headers"

# Remove any previous xcframework
if [ -d "$XCFRAMEWORK_OUTPUT" ]; then
    echo "Removing existing xcframework..."
    rm -rf "$XCFRAMEWORK_OUTPUT"
fi

# Build xcframework
echo "Creating mars.xcframework..."

xcodebuild -create-xcframework \
    -library "$IOS_DEVICE_LIB" -headers "$HEADERS_PATH" \
    -library "$IOS_SIMULATOR_LIB" -headers "$HEADERS_PATH" \
    -library "$MACOS_LIB" -headers "$HEADERS_PATH" \
    -output "$XCFRAMEWORK_OUTPUT"

echo "mars.xcframework created successfully at $XCFRAMEWORK_OUTPUT"

# Removing the "mars/" prefix from all include statements in header files
echo "Updating include statements in header files..."

find "$XCFRAMEWORK_OUTPUT" -name "*.h" -type f | while read -r header_file; do
    sed -i '' 's/#include "mars\//#include "/g' "$header_file"
done

# Compress the xcframework for distribution
zip -r $XCFRAMEWORK_OUTPUT.zip $XCFRAMEWORK_OUTPUT
ZIP_NAME=$XCFRAMEWORK_OUTPUT.zip

# Compute checksum using swift package manager
CHECKSUM=$(swift package compute-checksum $ZIP_NAME)

echo "XCFramework: ${ZIP_NAME}"
echo "Checksum: ${CHECKSUM}"
