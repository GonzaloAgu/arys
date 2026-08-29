# source-manifest Specification

## Purpose

Define the append-only SHA-256 registry that makes source immutability provable: one canonical manifest listing every protected file with the hash of its committed content, plus an additions-only register helper. Content registered here is NEVER modified — no re-baseline flow exists anywhere in this system. Deleting a registered source is the single legitimate exception and must stay fully traceable through git history.

The exact manifest path is finalized at design (candidate: `integrity/manifest.sha256`).

## Requirements

### Requirement: Manifest format and encoding

The system MUST maintain exactly one manifest file, one line per protected file, in standard `sha256sum -c` format (`<lowercase-sha256>␣␣<repo-relative/path>`), forward slashes, deterministically sorted. The manifest MUST be UTF-8 without BOM with LF line endings so external tools consume it directly.

#### Scenario: External verification succeeds on a clean tree

- GIVEN a checkout whose protected files match their manifest entries
- WHEN `sha256sum -c <manifest>` runs outside git
- THEN every entry reports OK and the exit code is zero

#### Scenario: Manifest is BOM-free

- GIVEN the manifest bytes on disk
- WHEN the first byte is inspected
- THEN it is a hexadecimal character, not a byte-order mark

### Requirement: Entry identity

Each entry MUST record the SHA-256 of the file's committed blob content as git stores it — never incidental working-tree bytes. Entries cover exactly the two protected layers defined by `protected-source-layout`.

#### Scenario: Entries match committed blobs

- GIVEN a registered PDF–Markdown pair
- WHEN each manifest line is compared against the SHA-256 of its file's committed blob
- THEN every pair matches

### Requirement: Append-only registration

A register helper MUST be provided that adds manifest lines only. It MUST refuse to alter or remove any existing line and MUST refuse to register a PDF unless its converted Markdown counterpart exists and is registered in the same operation. No update, refresh, or re-baseline command exists.

#### Scenario: Registering a new pair appends two lines

- GIVEN a new PDF and its existing Markdown counterpart, neither registered
- WHEN the helper registers them
- THEN exactly one line per file is appended and all pre-existing lines are byte-identical afterwards

#### Scenario: Helper refuses unpaired PDF

- GIVEN a new PDF whose Markdown counterpart does not exist
- WHEN the helper runs
- THEN nothing is appended and it exits non-zero

#### Scenario: Helper refuses entry mutation

- GIVEN an already-registered path
- WHEN any operation attempts to change or delete its manifest line outside the deletion exception
- THEN the helper fails and the manifest is unchanged

### Requirement: Deletion is the sole exception

Removing registered material MUST be permitted only as one atomic event: deleting a source requires deleting its derived Markdown counterpart and removing ALL their manifest lines within a single commit, preserving full traceability through git history. Partial removal (file without entry, entry without file, PDF without its Markdown, or vice versa) is invalid.

#### Scenario: Atomic pair deletion leaves together

- GIVEN a registered PDF–Markdown pair
- WHEN one commit deletes both files and removes both manifest lines
- THEN the deletion is legitimate and history shows files and entries departing together in that commit

#### Scenario: Partial removal is invalid

- GIVEN a commit that deletes a registered file but omits its counterpart or the corresponding manifest-line removals
- WHEN the commit is evaluated
- THEN it violates this requirement and is rejected by `integrity-pre-commit-hook`

### Requirement: Strict bootstrap without grandfathering

The FIRST commit MUST already satisfy full strictness: the initial source enters together with its converted Markdown and both manifest lines. No grandfather clause, baseline exception, or deferred registration exists anywhere in this system; this supersedes any earlier baseline assumption.

#### Scenario: Bootstrap carries the initial pair fully registered

- GIVEN a repository with zero commits
- WHEN the first commit includes `bibliografia/unidad-01-conceptos-de-seguridad.pdf`, its converted Markdown in the Markdown layer, and manifest lines for both
- THEN the tree satisfies every invariant above immediately after bootstrap

#### Scenario: Unpaired bootstrap source is non-conformant

- GIVEN a proposed first commit registering the initial PDF without its Markdown counterpart
- WHEN it is evaluated against these requirements
- THEN it fails — no baseline exception allows it
