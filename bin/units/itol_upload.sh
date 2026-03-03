#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <treefile> <project> <tree_id_outfile> [annotation_files...]"
    exit 1
fi

TREE=$1
PROJECT=$2
TREE_ID_OUTFILE=$3
shift 3

ANNOTATIONS=("$@")

echo "=============================================="
echo "🌳 Uploading tree to iTOL (Batch mode)"
echo "Tree: $TREE"
echo "Project: $PROJECT"
echo "Annotations: ${#ANNOTATIONS[@]}"
echo "=============================================="

if [ -z "${ITOL_API_KEY:-}" ]; then
    echo "❌ ITOL_API_KEY environment variable not set."
    exit 1
fi

TMPDIR=$(mktemp -d)
BASENAME=$(basename "$TREE" .treefile)
TREE_RENAMED="${TMPDIR}/${BASENAME}.tree"
ZIPFILE="${TMPDIR}/${BASENAME}.zip"

# Copy and rename tree
cp "$TREE" "$TREE_RENAMED"

# Copy annotation files (if any)
for file in "${ANNOTATIONS[@]}"; do
    if [ -f "$file" ]; then
        cp "$file" "$TMPDIR/"
    else
        echo "⚠ Warning: Annotation file not found: $file"
    fi
done

# Create zip archive
cd "$TMPDIR"
zip -q "$ZIPFILE" *
cd - > /dev/null

# Upload
RESPONSE=$(curl -s \
    -F "zipFile=@${ZIPFILE}" \
    -F "projectName=${PROJECT}" \
    -F "APIkey=${ITOL_API_KEY}" \
    https://itol.embl.de/batch_uploader.cgi)

echo "----------------------------------------------"
echo "iTOL Response:"
echo "$RESPONSE"
echo "----------------------------------------------"


# Check result
if [[ "$RESPONSE" == SUCCESS* ]]; then
    TREE_ID=$(echo "$RESPONSE" | awk '{print $2}')

    echo "✅ Upload successful."
    echo "Tree ID: $TREE_ID"
    echo "Access URL: https://itol.embl.de/tree/${TREE_ID}" 

    # Overwrite file with clean tree ID only
    TREE_URL="https://itol.embl.de/tree/${TREE_ID}"
    echo "$TREE_URL" > "$TREE_ID_OUTFILE"

else
    echo "❌ Upload failed."
    rm -rf "$TMPDIR"
    exit 1
fi

# Cleanup
rm -rf "$TMPDIR"