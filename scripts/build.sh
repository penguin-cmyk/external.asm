#!/bin/bash
set -e

FORMAT="win64"
SRC_DIR="../src"
INTERMEDIATE_DIR="../build/intermediate"
BUILD_DIR="../build"
OUTPUT_FILE="output.exe"

mkdir -p "$INTERMEDIATE_DIR"
mkdir -p "$BUILD_DIR"

echo "Assembling all .asm in $SRC_DIR..."

asm_files_found=false
while IFS= read -r -d '' asmfile; do
    asm_files_found=true
    rel_path="${asmfile#$SRC_DIR/}"
    obj_dir="$INTERMEDIATE_DIR/$(dirname "$rel_path")"
    mkdir -p "$obj_dir"
    objfile="$obj_dir/$(basename "${rel_path%.asm}.obj")"
    
    echo "nasm -f $FORMAT \"$asmfile\" -o \"$objfile\""
    nasm -f "$FORMAT" "$asmfile" -o "$objfile"
done < <(find "$SRC_DIR" -name "*.asm" -type f -print0)

if [ "$asm_files_found" = false ]; then
    echo "No asm files found in $SRC_DIR (including subfolders)"
    exit 1
fi

echo "Linking all .obj files in $INTERMEDIATE_DIR into $OUTPUT_FILE..."
gcc $(find "$INTERMEDIATE_DIR" -name "*.obj" -type f) -o "$BUILD_DIR/$OUTPUT_FILE" -mconsole

echo "Build succeeded! Output: $BUILD_DIR/$OUTPUT_FILE"
echo
"$BUILD_DIR/$OUTPUT_FILE"