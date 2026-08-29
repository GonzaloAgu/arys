# Delta for integrity-pre-commit-hook

## MODIFIED Requirements

### Requirement: Blocking conditions

While active, the hook MUST reject any commit whose staged changes include:

1. A registered file whose blob hash differs from its manifest line.
2. A new protected-layer file without a manifest line added in the same commit.
3. A new source under `bibliografia/` (PDF **or web link**) without its Markdown counterpart staged and both registered in that same commit.
4. A registered file deleted while its manifest line remains.
5. One member of a registered pair deleted without the other member.
6. An existing manifest line modified or removed except alongside its file's deletion.
7. A web link file whose staged content is not a single absolute `http(s)://` URL.
8. A source whose stem collides with another source's stem in `bibliografia/` (a stem with both a PDF and a web link mapped to the same Markdown).
(Previously: condition 3 applied only to PDF sources; conditions 7 and 8 did not exist.)

#### Scenario: Modified registered source is blocked

- GIVEN a registered source (PDF or web link) with altered content staged
- WHEN committing without a manifest change
- THEN it is rejected, naming the offending file

#### Scenario: Unpaired new source is blocked

- GIVEN a new source staged under `bibliografia/` (a PDF or a web link)
- WHEN its Markdown counterpart is absent from the same commit
- THEN it is rejected until both files exist and both entries are added

#### Scenario: Modified registered web link is blocked

- GIVEN a registered web link whose staged `.txt` content no longer matches its manifest line
- WHEN committing without a manifest change
- THEN it is rejected, naming the link file

#### Scenario: Half-pair web deletion is blocked

- GIVEN a commit deleting one member of a registered web pair (link or its Markdown) but not the other
- WHEN committing
- THEN it is rejected as a half-pair deletion

#### Scenario: Duplicate-stem source is blocked

- GIVEN a staged web link whose stem already has a source (PDF or web) in `bibliografia/`
- WHEN committing
- THEN it is rejected as a duplicate-stem collision

#### Scenario: Deletion without entry removal is blocked

- GIVEN a commit deleting a registered file but keeping its manifest line
- WHEN committing
- THEN it is rejected; only the atomic deletion exception passes

#### Scenario: Manifest tampering is blocked

- GIVEN an existing manifest line edited to match altered content
- WHEN committing
- THEN it is rejected as registry tampering

### Requirement: Verification over staged index blobs

The verifier MUST compute hashes from staged blob content in the git index — never from working-tree bytes. For web links this stays pure-hash: the verifier SHALL NOT evaluate URL freshness or fetch the link; it only recomputes SHA-256 over staged blobs and compares against manifest lines, keeping immutability checks byte-exact.
(Previously: this requirement described only the staged-blob hash model; it now states explicitly that the verifier remains pure-hash for web links and does not perform URL freshness checks.)

#### Scenario: Working-tree noise does not affect verdicts

- GIVEN a staged set fully consistent with the manifest
- WHEN an unrelated unstaged modification exists in a registered working-tree file (PDF, link, or Markdown)
- THEN the verdict derives solely from staged content and the commit proceeds

#### Scenario: Accepts a complete web pair

- GIVEN a commit staging a complete registered web pair: a `.txt` link with a single absolute URL and its verbatim `.md` mirror, both with manifest lines
- WHEN the commit runs with hooks active
- THEN it is accepted
