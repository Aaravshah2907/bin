#!/usr/bin/env bash
# jikan.sh - MyAnimeList provider via Jikan API

jikan_add() {
    local query="$1"
    local type="${2:-anime}"

    # Search for the anime with safe encoding
    local escaped_query
    escaped_query=$(jq -rn --arg q "$query" '$q|@uri')
    
    echo "Searching MyAnimeList for: $query" >&2
    local final_url="https://api.jikan.moe/v4/anime?q=${escaped_query}&limit=5"
    echo "DEBUG: API URL is [$final_url]" >&2
    
    search_json=$(curl -s -L --connect-timeout 10 \
        -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
        "$final_url")
    
    if [ -z "$search_json" ]; then
        echo "Error: MyAnimeList API (Jikan) unreachable or returned empty response." >&2
        return 1
    fi

    # Save debug log
    echo "$search_json" > "/tmp/jikan_last_search.json"

    # Check for Rate Limits or Errors
    local status
    status=$(echo "$search_json" | jq -r '.status // empty')
    if [ -n "$status" ] && [ "$status" != "null" ] && [ "$status" -ge 400 ]; then
        local msg
        msg=$(echo "$search_json" | jq -r '.message // "API Error"')
        echo "MAL API error ($status): $msg" >&2
        return 1
    fi

    # Check for valid JSON and data
    local data_len
    data_len=$(echo "$search_json" | jq -r '.data | length // 0' 2>/dev/null || echo "0")
    
    if [ "$data_len" -eq 0 ]; then
        echo "DEBUG: No results in first attempt. Result was: $(echo "$search_json" | cut -c 1-100)..." >&2
        # Last resort: Try one more time without limit
        local fallback_url="https://api.jikan.moe/v4/anime?q=${escaped_query}"
        echo "DEBUG: Falling back to [$fallback_url]" >&2
        search_json=$(curl -s -L -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
            "$fallback_url")
        data_len=$(echo "$search_json" | jq -r '.data | length // 0' 2>/dev/null || echo "0")
    fi

    if [ "$data_len" -eq 0 ]; then
        echo "No results found on MyAnimeList for '$query'." >&2
        return 1
    fi

    # Let user pick using fzf
    selection=$(echo "$search_json" | jq -r '.data[] | "\(.title) (\(.aired.prop.from.year // "N/A")) | ID:\(.mal_id)"' | fzf --reverse --prompt="Select MAL entry: ")
    
    if [ -z "$selection" ]; then
        echo "No selection made." >&2
        return 0
    fi

    mal_id=$(echo "$selection" | sed -E 's/.*ID:([0-9]+)/\1/')
    
    # Fetch full data for the selected ID with safe headers
    full_json=$(curl -s -L -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
        "https://api.jikan.moe/v4/anime/${mal_id}/full")
    
    # Check if full_json is valid
    if ! echo "$full_json" | jq -e '.data' > /dev/null 2>&1; then
        echo "Failed to fetch full metadata from Jikan." >&2
        return 1
    fi

    # Map to library schema in one robust jq step
    echo "$full_json" | jq -c --arg now "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" --arg mal_id "$mal_id" '
    .data | {
        id: "mal:\($mal_id)",
        title: (.title_english // .title),
        type: "anime",
        brand: (.studios[0]?.name // .producers[0]?.name // "Unknown"),
        subtype: .type,
        status: "planned",
        progress: { current: 0, total: (.episodes // 0), unit: "episode" },
        seasons: { current: 0, total: 1 },
        metadata: {
            year: .aired.prop.from.year,
            release_date: (.aired.from[0:10] // null),
            genres: [.genres[].name],
            score: .score,
            idMal: ($mal_id | tonumber)
        },
        source: {
            provider: "mal",
            id: ($mal_id | tonumber)
        },
        local: { path: "", available: false },
        details: {
            studios: [.studios[].name],
            source: .source,
            status: .status,
            serialization: (.serialization // "")
        },
        timestamps: { added: $now, updated: $now },
        overview: (.synopsis | gsub("<[^>]*>"; "") // "No description provided."),
        poster_path: (.images.jpg.large_image_url // .images.jpg.image_url // ""),
        rating: (.score // 0)
    }
    '
}
