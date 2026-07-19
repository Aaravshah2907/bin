#!/bin/bash
# ============================================================
# cf-rating-monitor.sh
# Polls the Codeforces API and sends a WhatsApp/Ntfy alert
# whenever your rating changes after a contest.
# Run via cron: */15 * * * * ~/.local/bin/cf-rating-monitor.sh
# ============================================================

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
source "$HOME/.config/shell/functions.sh"

CF_HANDLE="Aarav_Shah"   # <-- Your Codeforces handle here
CACHE_FILE="/tmp/cf_rating_cache"

# Fetch current rating from Codeforces public API
RESPONSE=$(curl -s "https://codeforces.com/api/user.info?handles=$CF_HANDLE")
NEW_RATING=$(echo "$RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
if data.get('status') == 'OK':
    print(data['result'][0].get('rating', 0))
else:
    print('')
" 2>/dev/null)

# Bail if API failed or returned nothing
if [ -z "$NEW_RATING" ]; then
  exit 0
fi

# Read cached rating from last run
if [ -f "$CACHE_FILE" ]; then
  OLD_RATING=$(cat "$CACHE_FILE")
else
  # First run — just cache current and exit silently
  echo "$NEW_RATING" > "$CACHE_FILE"
  exit 0
fi

# Only alert if the rating actually changed
if [ "$NEW_RATING" != "$OLD_RATING" ]; then
  CHANGE=$((NEW_RATING - OLD_RATING))

  if [ "$CHANGE" -gt 0 ]; then
    SIGN="+"
    EMOJI="📈"
  else
    SIGN=""
    EMOJI="📉"
  fi

  # Determine rank
  RANK=$(python3 -c "
r = $NEW_RATING
if r < 1200: print('Newbie')
elif r < 1400: print('Pupil')
elif r < 1600: print('Specialist')
elif r < 1900: print('Expert')
elif r < 2100: print('Candidate Master')
elif r < 2300: print('Master')
else: print('Grandmaster')
")

  alert "${EMOJI} Codeforces Rating Updated! ${OLD_RATING} → ${NEW_RATING} (${SIGN}${CHANGE}) | Rank: ${RANK}"
  echo "$NEW_RATING" > "$CACHE_FILE"
fi
