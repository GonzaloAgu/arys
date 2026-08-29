# protected-source-layout Specification

## Purpose

Define the canonical repository layout that protects course source material: the lowercase `bibliografia/` directory for original PDFs, a sibling top-level directory for derived Markdown notes, and `.gitattributes` rules that make content bytes stable across machines and checkouts. This layout is the foundation on which `source-manifest` registration and `integrity-pre-commit-hook` enforcement operate.

The concrete name of the Markdown layer directory is finalized at design (candidate: `apuntes/`). This spec refers to it as "the Markdown layer".

## Requirements

### Requirement: Canonical protected source directory

All original course PDFs MUST live under the lowercase directory `bibliografia/`. This path is the canonical home of the single-source-of-truth layer; no alternative casing variant SHALL be introduced.

#### Scenario: Source PDF lives in the canonical directory

- GIVEN the bootstrap content of the repository
- WHEN tracked paths are inspected
- THEN the source PDF is exactly `bibliografia/unidad-01-conceptos-de-seguridad.pdf` (lowercase directory component)

#### Scenario: No casing variants are tracked

- GIVEN the repository history
- WHEN tracked paths are searched
- THEN no uppercase or mixed-case variant of the protected directory exists

### Requirement: Sibling Markdown layer

Derived Markdown notes MUST live in exactly one top-level directory that is a sibling of `bibliografia/` (never inside it). Every derived Markdown file corresponds to exactly one source PDF by the naming convention fixed in design.

#### Scenario: Derived note is placed in the sibling layer

- GIVEN a Markdown note derived from a PDF in `bibliografia/`
- WHEN it is created in the Markdown layer
- THEN its path is outside `bibliografia/` and it is eligible for manifest registration as that PDF's counterpart

#### Scenario: One-to-one pairing by name

- GIVEN a source PDF named `X.pdf`
- WHEN its derived Markdown exists
- THEN it is named `X.md`, lives in the Markdown layer, and corresponds to no other source PDF

### Requirement: Byte-stability attributes

A committed `.gitattributes` MUST exist before any protected file is committed and MUST pin `*.pdf binary` and `*.md text eol=lf`. These rules MUST neutralize local `core.autocrlf` settings so that every protected file's working-tree bytes equal its staged blob bytes on any machine.

#### Scenario: Fresh clone preserves hashes

- GIVEN a clone performed with `core.autocrlf=true`
- WHEN a protected Markdown file is hashed and compared to its manifest entry
- THEN the hash matches because the blob was stored with LF endings and checked out deterministically

#### Scenario: PDFs are never translated

- GIVEN any local git configuration
- WHEN a PDF under `bibliografia/` is staged and checked out
- THEN its bytes pass through git unchanged (binary), keeping its hash stable across machines
