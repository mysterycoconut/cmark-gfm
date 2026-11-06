# Upstream

Fork of [github/cmark-gfm](https://github.com/github/cmark-gfm) at `0.29.0.gfm.13`, the latest release as of 2026 (from Jul 21, 2023).

## Why this fork exists

Two reasons.

1. `Package.swift`, so the library can be consumed by Swift Package Manager. Upstream builds with CMake only.

2. Source-position fixes. `cmark-gfm` forked from [commonmark/cmark](https://github.com/commonmark/cmark) in 2019 and has not tracked it since; several sourcepos corrections upstream cmark has made were never merged back. Both `cmark-gfm` and the fork at [swiftlang/swift-cmark](https://github.com/swiftlang/swift-cmark) are largely dormant. The fixes below are backported from `cmark`, some cross-checked against the ones `swift-cmark` had already taken, and some our own.

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

- **Backslash hard break line tracking** (`src/inlines.c`, `handle_backslash`) — the linebreak branch calls `skip_line_end`, which only advances `subj->pos`. Unlike `handle_newline`, it never advances `subj->line` or resets `column_offset`, so everything after a backslash hard break keeps measuring from the line it was on before the break. *Example:* `foo\` followed by `bar` on the next line reported `bar` on line 1. *[bc6fdad044af324bb9caa3ca5737effeeaced41b]*

- **Raw HTML delimiter width** (`src/inlines.c`, `handle_pointy_brace`) — called `adjust_subj_node_newlines` with `extra=1`, the value `handle_backticks` uses to exclude a code span's closing backticks from its end position. Raw HTML's own position is delimiter-inclusive, so the same `extra` wrongly excluded its closing `>` too. *Example:* `<a href="foo\nbar">` reported its end one character short of the `>`. *[d13ae44c7a20fe33a6c17a3ad75052d48cfc9f48]*

- **Multi-line construct end column missing block_offset** (`src/inlines.c`, `adjust_subj_node_newlines`) — `end_column` was set to `since_newline` directly, skipping the `+ subj->block_offset` every other column assignment in this file includes. Invisible at the top level, where `block_offset` is 0; wrong by the container's prefix width for a code span or HTML tag nested inside a blockquote or list item. *Example:* `` `bl\nah` `` spanning two lines inside `> ` reported its closing backtick two columns short. *[668ac2b7a4bde51b7b5b7d0fe628b7ce93aabc95]*

- **Table header under a paragraph** (`extensions/table.c`, `try_opening_table_header`; `src/blocks.c`, `add_line`) — GFM lets a table's header row be the last line of a paragraph, which is only known once the delimiter row arrives. The extension turned the whole paragraph into the table and copied the lines above the header into a new paragraph made with `cmark_node_new_with_mem`. That copy had no position (`0:0-0:0`, its inlines numbered from line 0), and the table, its header row and header cells kept the paragraph's first line, with the cells measured along all of the paragraph's text. Now the header row is taken off the end of the paragraph and the table is opened after it with `cmark_parser_add_child`, as any block that interrupts a paragraph is: the paragraph stays the parser's own node, with its real start, and the table starts on the header's line. `finalize` ends a block on the line before the one that closed it, which here is the header's, so the paragraph's end is set to the line before that. Both numbers this needs are from lines the parser has already finished with, so `add_line` records them: where the added line's text starts (`last_added_line_offset`) and the length of the line before it (`line_length_before_last_added`). *Example:* `adasda` above `| a | b |` reported the paragraph at `0:0-0:0` and the first header cell at `1:9-1:11`; now `1:1-1:6` and `2:2-2:4`. *[8a566397be755d9086446fcfae2fd62c43bc0091]*

### Fixes that change output

- **Link reference definitions above a table header** (same change as above) — the paragraph copy never went through `finalize`, so link reference definitions at its start were never taken off: they rendered as text, and links using them didn't resolve. It also unescaped `\|` in the copy's text, which only cells need, so every column after one was a byte short (output unaffected, since `\|` in a paragraph is an escape either way). Both went with the copy. *Example:* `[ref]: /url` and `foo` above `| a |` rendered `<p>[ref]: /url\nfoo</p>`, and `[x][ref]` later in the document stayed text. *[SHA]*

## Not taken from swift-cmark

`swift-cmark` carries feature work for `swift-markdown` that this fork deliberately omits: the `^[...]` attribute syntax and `CMARK_NODE_ATTRIBUTE`, `CMARK_OPT_PRESERVE_WHITESPACE`, per-parser character tables, `bracket_type` replacing `bool image`, and `node->backtick_count`. These change parsing behaviour or the public node structure.

## Known divergences from the GFM spec

Not yet fixed. Listed so they aren't rediscovered.

- Email autolinks are matched after inline parsing, over text where escapes and character references have already been resolved, so `<foo\+@bar.example.com>` produces a link the spec says should not exist (spec example 614). `www.` and `http://` are matched during inline parsing and are unaffected. Fixing it means moving email matching to parse time, which changes output rather than positions.
