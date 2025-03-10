#!/bin/bash

OUTPUT_DIR="site"
INDEX_FILE="$OUTPUT_DIR/index.html"
CSS_FILE="$OUTPUT_DIR/style.css"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Create a simple CSS file for better readability
cat > "$CSS_FILE" << 'EOL'
body {
    font-family: Arial, sans-serif;
    line-height: 1.6;
    margin: 0;
    padding: 20px;
    color: #333;
    max-width: 1000px;
    margin: 0 auto;
}
a {
    color: #0066cc;
    text-decoration: none;
}
a:hover {
    text-decoration: underline;
}
h1, h2, h3 {
    color: #444;
}
.navigation {
    background-color: #f5f5f5;
    padding: 10px;
    border-radius: 5px;
    margin-bottom: 20px;
}
.folder {
    margin-left: 20px;
}
.back-link {
    margin-bottom: 10px;
    display: block;
}
EOL

# Generate index.html
cat > "$INDEX_FILE" << 'EOL'
<!DOCTYPE html>
<html>
<head>
    <title>Markdown Documentation</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <h1>Game Documentation</h1>
    <div class="navigation">
        <p>This is a generated site of markdown documentation for the Tribal Drum Game project.</p>
    </div>
    <h2>Contents</h2>
    <ul>
EOL

# Function to process markdown files in a directory
process_directory() {
    local dir="$1"
    local rel_path="$2"
    local output_dir="$OUTPUT_DIR/$rel_path"
    
    # Create output directory if it doesn't exist
    mkdir -p "$output_dir"
    
    # Process each markdown file in the directory
    for file in "$dir"/*.md; do
        if [ -f "$file" ]; then
            filename=$(basename -- "$file")
            name="${filename%.*}"
            
            # Create output HTML file
            if [ -z "$rel_path" ]; then
                html_path="$name.html"
                # Create a temporary header file with navigation
                temp_header=$(mktemp)
                echo '<div class="back-link"><a href="index.html">Back to Index</a></div>' > "$temp_header"
                
                pandoc "$file" -o "$OUTPUT_DIR/$html_path" --standalone --css="style.css" --include-before-body="$temp_header"
                rm "$temp_header"
                echo "    <li><a href=\"$html_path\">$name</a></li>" >> "$INDEX_FILE"
            else
                html_path="$rel_path/$name.html"
                # Create a temporary header file with navigation
                temp_header=$(mktemp)
                echo "<div class=\"back-link\"><a href=\"../index.html\">Back to Index</a></div>" > "$temp_header"
                
                pandoc "$file" -o "$OUTPUT_DIR/$html_path" --standalone --css="../style.css" --include-before-body="$temp_header"
                rm "$temp_header"
                echo "    <li><a href=\"$html_path\">$rel_path/$name</a></li>" >> "$INDEX_FILE"
            fi
        fi
    done
    
    # Process subdirectories
    for subdir in "$dir"/*/; do
        if [ -d "$subdir" ] && [[ "$subdir" != *"$OUTPUT_DIR"* ]]; then
            sub_name=$(basename -- "$subdir")
            
            if [ -z "$rel_path" ]; then
                process_directory "$subdir" "$sub_name"
            else
                process_directory "$subdir" "$rel_path/$sub_name"
            fi
        fi
    done
}

# Process current directory
process_directory "." ""

# Finish the index file
cat >> "$INDEX_FILE" << 'EOL'
    </ul>
    <hr>
    <p><small>Generated documentation site for the Tribal Drum Game project.</small></p>
</body>
</html>
EOL

echo "HTML pages generated in the '$OUTPUT_DIR' folder. Open $OUTPUT_DIR/index.html in your browser."