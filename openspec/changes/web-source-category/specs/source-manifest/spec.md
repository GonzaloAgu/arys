# Delta for source-manifest

## MODIFIED Requirements

### Requirement: Append-only registration

A register helper MUST be provided that adds manifest lines only. It MUST refuse to alter or remove any existing line and MUST refuse to register a PDF **or web link** in `bibliografia/` unless its converted Markdown counterpart is registered in the same operation. When the source is a web link, the helper MUST validate that the link file contains a single absolute `http(s)://` URL. No update, refresh, or re-baseline command exists.
(Previously: the helper refused to register a PDF unless its converted Markdown counterpart existed and was registered in the same operation; web links were unsupported.)

#### Scenario: Registering a new pair appends two lines

- GIVEN a new source (PDF with its `.md`, or web link with its `.md`), neither registered
- WHEN the helper registers them
- THEN exactly one line per file is appended and all pre-existing lines are byte-identical afterwards

#### Scenario: Registering a web pair appends exactly two lines

- GIVEN a staged `bibliografia/unidad-01-teoria-web.txt` containing a single absolute URL and its staged mirror `apuntes/unidad-01-teoria-web.md`
- WHEN the helper registers the pair
- THEN exactly a `.txt` line and an `.md` line are appended and every pre-existing manifest line stays byte-identical

#### Scenario: Helper refuses unpaired source

- GIVEN a new source (PDF or web link) whose Markdown counterpart does not exist
- WHEN the helper runs
- THEN nothing is appended and it exits non-zero

#### Scenario: Helper refuses a link without a URL

- GIVEN a staged web link file whose content is not exactly one absolute `http(s)://` URL (empty, multi-line, or a relative/invalid URL)
- WHEN the helper runs
- THEN nothing is appended and it exits non-zero

#### Scenario: Helper refuses a duplicate stem

- GIVEN a web link whose stem already has a source (PDF or web) registered
- WHEN the helper runs
- THEN nothing is appended and it exits non-zero

#### Scenario: Helper refuses entry mutation

- GIVEN an already-registered path (PDF or web)
- WHEN any operation attempts to change or delete its manifest line outside the deletion exception
- THEN the helper fails and the manifest is unchanged

### Requirement: Deletion is the sole exception

Removing registered material MUST be permitted only as one atomic event: deleting a source requires deleting its derived Markdown counterpart and removing ALL their manifest lines within a single commit, preserving full traceability through git history. Partial removal (file without entry, entry without file, source without its Markdown, or vice versa) is invalid.
(Previously: this requirement referenced only PDF sources; it now applies identically to web-link sources.)

#### Scenario: Atomic pair deletion leaves together

- GIVEN a registered pair (a PDF and its `.md`, or a web link and its `.md`)
- WHEN one commit deletes both files and removes both manifest lines
- THEN the deletion is legitimate and history shows files and entries departing together in that commit

#### Scenario: Partial removal is invalid

- GIVEN a commit that deletes a registered source (PDF or web) but omits its counterpart or the corresponding manifest-line removals
- WHEN the commit is evaluated
- THEN it violates this requirement and is rejected by `integrity-pre-commit-hook`
