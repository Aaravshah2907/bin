#!/usr/bin/env bash
# googlebooks.sh - provider for books using Google Books API

set -euo pipefail

googlebooks_add() {
    local query="$1"

    # Fetch search results
    json=$(curl -s "https://www.googleapis.com/books/v1/volumes?q=$(echo "$query" | jq -sRr @uri)&maxResults=40")

    if ! echo "$json" | jq . >/dev/null 2>&1; then
        echo '{"error":"invalid JSON"}'
        return 1
    fi

    # Prepare fzf selection
    tmpfile=$(mktemp)
    echo "$json" | jq -c '.items[] | {
        id,
        title: .volumeInfo.title,
        author: (.volumeInfo.authors[0] // "Unknown"),
        year: (.volumeInfo.publishedDate | split("-")[0] // null)
    }' > "$tmpfile"

    if [ ! -s "$tmpfile" ]; then
        rm -f "$tmpfile"
        echo '{}'
        return 1
    fi

    selection=$(cat "$tmpfile" | fzf --reverse --prompt="Select Book: ")
    rm -f "$tmpfile"

    if [ -z "$selection" ]; then
        echo '{}'
        return 1
    fi

    # Parse selection
    id=$(echo "$selection" | jq -r '.id')
    
    # Get full details
    doc=$(curl -s "https://www.googleapis.com/books/v1/volumes/${id}")
    info=$(echo "$doc" | jq -c '.volumeInfo')
    
    title=$(echo "$info" | jq -r '.title')
    author=$(echo "$info" | jq -r '.authors[0] // "Unknown"')
    year=$(echo "$info" | jq -r '.publishedDate | split("-")[0] // null')
    pages=$(echo "$info" | jq -r '.pageCount // null')
    desc=$(echo "$info" | jq -r '.description // ""')
    poster=$(echo "$info" | jq -r '.imageLinks.thumbnail // empty')
    rating=$(echo "$info" | jq -r '.averageRating // null')
    isbn=$(echo "$info" | jq -c '(.industryIdentifiers[] | select(.type == "ISBN_13") | .identifier) // []')

    # Output uniform JSON
    echo "$info" | jq --arg id "gb:$id" --arg now "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" '
        {
            id: $id,
            title: .title,
            type: "book",
            brand: (.publisher // "Unknown"),
            subtype: null,
            status: "planned",
            progress: { current: 0, total: (.pageCount // 0), unit: "page" },
            seasons: null,
            metadata: {
                year: (.publishedDate[0:4] // null),
                release_date: (.publishedDate // null),
                genres: (.categories // []),
                author: (.authors // ["Unknown"]),
                isbn: (.industryIdentifiers // []),
                series: ""
            },
            source: { provider: "googlebooks", id: $id },
            local: { path: "", available: false },
            details: {
                authors: (.authors // []),
                publisher: .publisher,
                published_date: .publishedDate,
                page_count: .pageCount,
                isbn: (.industryIdentifiers // []),
                series: ""
            },
            streaming: (if .previewLink then [{name: "Google Books Preview", url: .previewLink}] else [] end),
            timestamps: { added: $now, updated: $now },
            poster_path: (.imageLinks?.thumbnail // ""),
            rating: ((.averageRating // 0) * 2),
            overview: (.description // "")
        }
    '
}
