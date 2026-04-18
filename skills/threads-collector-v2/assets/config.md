# Threads Collector — config

# Auto-written from the first-run interview. The skill re-reads this file every run.
# You can edit it directly if you want, but the skill has quick-confirm options that
# cover the common changes — no file-editing required.
# Lines starting with # are comments and ignored.

## Intent (from Q1)
# Options: content_ideas, competitor_watch, trend_spotting, hook_library, other
primary_intent: content_ideas

## Surface to scroll (from Q3)
# Options:
#   for_you          — your personalized feed
#   following        — only accounts you follow
#   search:<query>   — e.g. search:brand voice
#   profile:<handle> — e.g. profile:justinwelsh
#   trending         — auto-discovers Trending Now, drills into each topic (see Trending block below)
surface: for_you

## My handle (from Q5)
# Your own posts are always skipped. Include the @, or not — the skill handles both.
my_handle: @your_handle_here

## Engagement gate — scroll-time filter
# Posts below this likes count are skipped at scroll time, before any extraction.
# Set via Q4 strictness: Loose=50, Default=200, Strict=1000, or custom.
min_likes: 200

## Run sizing
# How many posts to collect before stopping. The session CSV will have exactly this many rows
# (assuming enough posts clear the likes gate before one of the other stop conditions fires).
target_collected: 100

# Scroll loop safety caps
max_scroll_cycles: 60
scroll_wait_seconds: 1.5

# Stop scrolling when posts get older than this (in hours). Prevents scrolling into stale feed.
stop_when_posts_older_than_hours: 48

## Trending settings (only used when surface: trending)

# Only drill into trending topics matching ANY of these substrings (case-insensitive).
# Leave [] to drill into all.
trending_topics_allowlist: []

# Always skip trending topics matching any of these.
trending_topics_blocklist: []

# How many trending topics to drill into per run (after allowlist/blocklist filtering).
trending_topics_per_run: 5

# Per-topic cap on posts collected from that topic's feed.
trending_posts_per_topic: 20

## Advanced

# Session folder naming — timestamped by default.
# session_filename_format: session-{timestamp}.csv
