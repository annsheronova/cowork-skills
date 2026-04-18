# Threads Collector — My Catch Config

# This file defines what makes a Threads post worth catching.
# Edit freely. The skill re-reads this file on every run, so changes take effect immediately.
# Lines starting with # are comments and ignored by the skill.

## Surface to scroll
# Options:
#   for_you          — your personalized feed (default)
#   following        — only posts from accounts you follow
#   search:<query>   — e.g. search:brand voice    (searches threads.com for that query)
#   profile:<handle> — e.g. profile:justinwelsh (scrolls that person's posts)
#   trending         — auto-discovers what's in Trending Now, drills into each topic.
#                      Use together with the "Trending settings" block below.
surface: for_you

## Trending settings (only used when surface: trending)

# Only drill into trending topics matching ANY of these substrings (case-insensitive).
# This is how you watch only trending *relevant to your niche*. Leave [] to drill into all.
# Example: ["AI", "marketing", "agent", "brand", "creator"]
trending_topics_allowlist:
  - AI
  - agent
  - brand
  - marketing
  - content
  - creator

# Always skip trending topics matching any of these (e.g. politics, sports, celebrities).
trending_topics_blocklist:
  - election
  - NFL
  - MLB
  - NBA
  - Grammy
  - Met Gala
  - Kardashian

# How many trending topics to drill into per run (after allowlist/blocklist filtering).
trending_topics_per_run: 5

# Per-topic scroll and capture caps (separate from the main run limits).
trending_posts_per_topic: 20
trending_scroll_cycles_per_topic: 8

## My handle
# Posts you authored will always be skipped (never catch yourself).
my_handle: @your_handle_here

## Run limits
# How much to scroll per run. Increase if you're getting too few catches.
max_scroll_cycles: 30
max_posts_to_collect: 50

# Stop scrolling when posts start being older than this (in hours).
# Prevents scrolling too far back into old feed content.
stop_when_posts_older_than_hours: 48

## Engagement — what makes a post "catch-worthy"

# Absolute thresholds (a post must clear at least one of these to pass)
min_likes: 200
min_replies: 0
min_reposts: 0

# Reply-to-like ratio — high ratio = real conversation (not just applause)
# 0.15 means replies are at least 15% of likes, which is strong conversation signal
min_reply_like_ratio: 0.15

# The rule that decides "catch or drop"
# Default: catch if EITHER a high-like post OR a high-conversation post
# You can rewrite this expression however you want using: likes, replies, reposts, reply_like_ratio
# Examples:
#   Stricter (AND):     "likes >= min_likes AND reply_like_ratio >= min_reply_like_ratio"
#   Only breakouts:     "likes >= 1000"
#   Conversation focus: "reply_like_ratio >= 0.25"
#   Multi-signal:       "likes >= min_likes OR (replies >= 50 AND reposts >= 20)"
catch_rule: "likes >= min_likes OR reply_like_ratio >= min_reply_like_ratio"

## Content keyword filters (optional)

# required_keywords_any: post must contain AT LEAST ONE of these phrases (case-insensitive)
# Leave empty [] to skip this filter.
required_keywords_any: []

# required_keywords_all: post must contain ALL of these phrases
required_keywords_all: []

# excluded_keywords: drop the post if it contains ANY of these phrases
excluded_keywords:
  - "OnlyFans"
  - "promo code"
  - "sponsored by"
  - "sp0nsored"
  - "DM for code"

## Author filters (optional)

# If set, catch ONLY from these authors. Everyone else dropped.
# Use for "follow a specific small list of mentors" mode.
# Leave [] for no allowlist.
author_allowlist: []

# Always drop posts from these authors (spam, irrelevant-to-you, etc.)
author_blocklist: []

## Format filters

# What kind of posts to catch
# Options: single, thread, either
post_format: either

# How much of a multi-post thread to capture when post_format allows threads.
# Options:
#   hook_only       — just the first (hook) post. Fastest, lightweight library.
#   inline_only     — first post + parts visible inline in the feed. Default balance.
#   full_expansion  — click into every caught thread, capture every part. Slowest, complete.
capture_thread_body: inline_only

# Media requirement
# Options: any, text_only, must_have_media
media_requirement: any

## My topics
# Used for automatic category classification. Add the ones that match your content focus.
# The skill tries to match each caught post to ONE of these as category_primary.
# If no topic fits, the post gets flagged category_needs_review=true for later manual sorting.
my_topics:
  - brand voice
  - AI in marketing
  - Claude / Cowork / AI agents
  - content strategy
  - remote team rituals
  - product marketing

## Hard excludes (always drop)
drop_ads: true
drop_reposts: true
drop_own_posts: true
drop_replies: true          # reply-type posts are skipped entirely

## Advanced (optional) — adjust only if you understand the tradeoff

# How long to wait between scroll cycles (seconds). Lower = faster but may miss late-rendering content.
scroll_wait_seconds: 1.5

# If three consecutive scrolls find no new posts, stop even if under max_scroll_cycles.
stop_on_empty_scrolls: true
