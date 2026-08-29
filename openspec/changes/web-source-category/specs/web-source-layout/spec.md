# web-source-layout Specification

## Purpose

Define a second protected source category parallel to `protected-source-layout`'s PDF category: a plain-text link file in `bibliografia/` naming the original web URL, paired with a verbatim Markdown mirror in the sibling `apuntes/` layer, pinned byte-stable, all under the same append-only immutability model. The link file is the sole provenance carrier; the mirror carries the content snapshot textually unaltered.

## Requirements

### Requirement: Link-file content contract

A web source MUST live at `bibliografia/{stem}.txt` and MUST contain exactly one line holding a single absolute `http://` or `https://` URL (the original web source). No other content, header, or commentary SHALL appear in the file.

#### Scenario: Link file carries one absolute URL

- GIVEN a web source registered as `bibliografia/unidad-01-teoria-web.txt`
- WHEN the staged blob content is inspected
- THEN it is exactly one line with a single absolute `https://` URL and nothing else

### Requirement: Verbatim Markdown mirror

The derived mirror of a web link MUST exist at `apuntes/{stem}.md` and MUST contain the sourced web content verbatim — byte-for-byte identical to the fetched source material. No added provenance header or editorial modification SHALL be introduced; the link file is the sole provenance carrier.

#### Scenario: Mirror is verbatim

- GIVEN the fetched web material for `unidad-01-teoria-web`
- WHEN its mirror `apuntes/unidad-01-teoria-web.md` is committed
- THEN it is byte-identical to the fetched source (Appendix A of the proposal), with no inserted provenance lines

### Requirement: Stem rules and collision avoidance

A web stem MUST match `[a-z0-9-]+` and MUST NOT collide with any existing stem in `bibliografia/` (PDFs included). The stem is the single key that maps link and mirror to `apuntes/{stem}.md`.

#### Scenario: Duplicate stem is rejected

- GIVEN a web link whose stem equals an existing source's stem (PDF or web)
- WHEN registration or verification runs
- THEN it is refused as a collision, preventing two sources from mapping to the same `apuntes/{stem}.md`

### Requirement: Cross-kind single source per stem

A stem MUST have at most one source file in `bibliografia/` regardless of kind (PDF or web link), because both kinds mirror to the same `apuntes/{stem}.md`. This invariant SHALL be enforced at both registration and verification.

#### Scenario: No two sources share a stem

- GIVEN the repository's protected sources
- WHEN the source set is inspected
- THEN each distinct stem in `bibliografia/` maps to exactly one source file

### Requirement: Byte-stability attributes

`.gitattributes` MUST pin `*.txt text eol=lf` so that link-file working-tree bytes equal their staged blob bytes on any machine, neutralizing local `core.autocrlf` settings under the existing byte-stability model.

#### Scenario: EOL is stable across machines

- GIVEN any local git configuration
- WHEN a link `.txt` under `bibliografia/` is staged and checked out
- THEN its bytes are LF-stable and its hash matches its manifest entry
