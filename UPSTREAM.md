# Upstream

Fork of [github/cmark-gfm](https://github.com/github/cmark-gfm) at `0.29.0.gfm.13`, the latest release as of 2026 (from Jul 21, 2023).

## Why this fork exists

Two reasons.

1. `Package.swift`, so the library can be consumed by Swift Package Manager. Upstream builds with CMake only.

2. Source-position fixes. `cmark-gfm` forked from [commonmark/cmark](https://github.com/commonmark/cmark) in 2019 and has not tracked it since; several sourcepos corrections upstream cmark has made were never merged back. Both `cmark-gfm` and the fork at [swiftlang/swift-cmark](https://github.com/swiftlang/swift-cmark) are largely dormant. The fixes below are backported from cmark`, some cross-checked against the ones `swift-cmark` had already taken.

## Changes from 0.29.0.gfm.13

### Packaging

- `Package.swift` and the layout changes SPM requires. *[1ff0c09088d40cd983419bda52284cf91c27fef5]*

### Backported source-position fixes

In order of commit (with *[SHA]* signatures).

- **Unmatched backtick runs** (`src/inlines.c`, `handle_backticks`) — reported `(pos, pos)` after rewinding, placing a run of *n* backticks as a single  column just past itself. Now reports the run's real span. *Example:* ` ```foo`` ` reported `(1,2)-(1,4)` for an eight-character literal. *[a88352ddca4f4b3c74b71291e568df1ce653c7b3]*

- **Autolink columns** (`src/inlines.c`, `make_autolink`) — omitted `subj->column_offset` and `subj->block_offset`, so `<https://example.com>` reported columns in the block's frame rather than the line's. Wrong by the width of every stripped prefix inside a blockquote, list item, or indented block. *Example:* `- <https://example.com>`. *[0f00e56e33be0edf634f3827c5161b937a3541a8]*

- **Link start line** (`src/inlines.c`, `handle_close_bracket`) — set `start_line` to the line holding `]` while taking `start_column` from the opening bracket, so a link spanning lines reported a start whose line and column came from different places. Now takes both from the opener.\
  *Example:* `[a \n  link](https://example.com)`. *[0d63fea4d3976411488678e57c9e82ce4f812563]*

- **Block end lines** (`src/blocks.c`, `finalize` and `add_line`) — `finalize` assumed blocks are closed from a later line and set `end_line` to `parser->line_number - 1`. HTML blocks of types 1–5 end on a condition inside a line and are finalized while still on it, so they reported `(0, 0)`. `swift-cmark`'s guard on that branch is taken here, but it relies on `end_line` holding the last line the block consumed, and upstream only ever sets it in `add_child`. Setting it in `add_line` as well completes the fix. *Example:* `<style>\np{color:red;}\n</style>` reported `(1,1)-(2,13)` for a three-line block; `<!DOCTYPE html>` reported `(1,1)-(0,0)`. *[66c52a391df961e3a7cdb10e7dd7d355ebcffb20]*

## Not taken from swift-cmark

`swift-cmark` carries feature work for `swift-markdown` that this fork deliberately omits: the `^[...]` attribute syntax and `CMARK_NODE_ATTRIBUTE`, `CMARK_OPT_PRESERVE_WHITESPACE`, per-parser character tables, `bracket_type` replacing `bool image`, and `node->backtick_count`. These change parsing behaviour or the public node structure.

## Known divergences from the GFM spec

Not yet fixed. Listed so they aren't rediscovered.

- Email autolinks are matched after inline parsing, over text where escapes and character references have already been resolved, so `<foo\+@bar.example.com>` produces a link the spec says should not exist (spec example 614). `www.` and `http://` are matched during inline parsing and are unaffected. Fixing it means moving email matching to parse time, which changes output rather than positions.
