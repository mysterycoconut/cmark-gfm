#ifndef CMARK_INLINES_H
#define CMARK_INLINES_H

#ifdef __cplusplus
extern "C" {
#endif

#include "references.h"

cmark_chunk cmark_clean_url(cmark_mem *mem, cmark_chunk *url);
cmark_chunk cmark_clean_title(cmark_mem *mem, cmark_chunk *title);

CMARK_GFM_EXPORT
void cmark_parse_inlines(cmark_parser *parser,
                         cmark_node *parent,
                         cmark_map *refmap,
                         int options);

// Where the parts of a link reference definition are in the text it was read
// from, as offsets, each end just past the part. A title's start and end are
// equal when there is none.
typedef struct {
  bufsize_t label_start, label_end;
  bufsize_t destination_start, destination_end;
  bufsize_t title_start, title_end;
} cmark_reference_offsets;

// Reads a link reference definition at the start of 'input' into 'refmap', and
// returns how much of 'input' it takes, or 0 when there is none. Where its
// parts are goes in 'offsets', unless it's NULL.
bufsize_t cmark_parse_reference_inline(cmark_mem *mem, cmark_chunk *input,
                                       cmark_map *refmap,
                                       cmark_reference_offsets *offsets);

void cmark_inlines_add_special_character(cmark_parser *parser, unsigned char c,
                                         bool emphasis);
void cmark_inlines_remove_special_character(cmark_parser *parser,
                                            unsigned char c, bool emphasis);

#ifdef __cplusplus
}
#endif

#endif
