#!/bin/bash

# Directory to process (default: current directory)
DIR=${1:-.}

# Check if pandoc is installed
if ! command -v pandoc &> /dev/null; then
    echo "Pandoc is not installed. Install it with: brew install pandoc"
    exit 1
fi

# Convert all .docx files in the directory to .md
for file in "$DIR"/*.docx; do
    if [[ -f "$file" ]]; then
        filename=$(basename -- "$file")
        name="${filename%.*}"
        echo "Converting $file to ${name}.md..."
        pandoc "$file" -o "${DIR}/${name}.md"
    fi
done

echo "Conversion complete!"

