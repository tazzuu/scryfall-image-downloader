#!/bin/bash
set -euo pipefail
JSON="${1:-unique-artwork-20251119100609.json}"
IMAGE_DIR="${PWD}/images"
mkdir -p "$IMAGE_DIR"

SAVED_FILENAMES="saved_filenames.txt"
touch "${SAVED_FILENAMES}"

# Extract PNG URLs into urls.txt (one per line)
jq -r '.[].image_uris.png' "${JSON}" | grep -v null > urls.txt


get_filename_from_url () {
    local url="$1"
    # Determine the final URL after redirects
    final_url=$(curl -sS -L -o /dev/null -w '%{url_effective}' "$url")

    # Fetch headers (follow redirects). Some servers don't support HEAD well,
    # so using -I with -L and allowing failure.
    headers=$(curl -sS -L -I "$url" || true)
    headers=$(echo "$headers" | tr -d '\r')

    # Try to parse filename from Content-Disposition header
    filename=""
    cd_header=$(echo "$headers" | grep -i '^Content-Disposition:' || true)
    if [[ -n "$cd_header" ]]; then
        # Try filename*= (encoded), then filename="...", then filename=bare
        filename=$(echo "$cd_header" | sed -n "s/.*filename\*=[^']*'[^']*'\([^;]*\).*/\1/p")
        if [[ -z "$filename" ]]; then
            filename=$(echo "$cd_header" | sed -n 's/.*filename=\"\([^\"]*\)\".*/\1/p')
        fi
        if [[ -z "$filename" ]]; then
            filename=$(echo "$cd_header" | sed -n 's/.*filename=\([^; ]*\).*/\1/p')
        fi
    fi

    # Fallback: derive filename from final URL path (strip query string)
    if [[ -z "$filename" ]]; then
        path="${final_url%%\?*}"
        filename=$(basename "$path")
    fi

    # If still empty, create a deterministic name using a hash and content-type
    if [[ -z "$filename" || "$filename" == "/" ]]; then
        ct=$(echo "$headers" | grep -i '^Content-Type:' | awk '{print $2}' | cut -d';' -f1 || true)
        case "$ct" in
            image/png) ext="png" ;;
            image/jpeg) ext="jpg" ;;
            image/gif) ext="gif" ;;
            image/webp) ext="webp" ;;
            *) ext="bin" ;;
        esac
        hash=$(printf '%s' "$url" | shasum -a 1 | awk '{print $1}')
        filename="${hash}.${ext}"
    fi

    # Strip any surrounding quotes
    filename="${filename%\"}"
    filename="${filename#\"}"

    printf "$filename"
}

download_if_not_exists () {
    local url="$1"
    local dest="$2"
    if [[ -f "$dest" ]]; then
        echo "Exists: $dest — skipping"
        # continue
    else
        echo "Downloading to: $dest"
        curl -L -o "$dest" --fail --retry 5 --continue-at - --compressed "$url"
    fi
}

# For each URL: resolve filename from headers or final URL, skip if file exists,
# and otherwise download (resuming partial downloads when possible).
while read -r url; do
    # check if the URL has a saved filename
    if grep -q "$url" "$SAVED_FILENAMES" ; then
        # skip
        echo "Skipping: Found previously saved filename for $url"
    else
        # dont skip
        echo "Filename not previously saved for $url"
        echo "Processing: $url"
        filename="$(get_filename_from_url "$url")"
        dest="$IMAGE_DIR/$filename"
        download_if_not_exists "$url" "$dest"

        # save the final file name
        printf '%s\t%s\n' "$url" "$filename" >> "$SAVED_FILENAMES"
    fi

done < urls.txt