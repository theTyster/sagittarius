# repo-map

`kb/bin/repo-map` writes the C4 map of one repo, at level C1 (system context) and level C2
(containers), as Mermaid diagrams in Markdown. On request it writes level C3 (components) for one
container (ticket T29 c8: C3 "occasionally", u60). It is a separate tool from `orbit-kb`: it has no
`CONTRACT.md` entry. Its tests are `kb/tests/test_repo_map.sh`. Ticket T12 (claims c1 to c3).
The only engine is SWI-Prolog. It reads two files as data, runs nothing from them, and uses no
network.

```sh
kb/bin/repo-map --facts KB_PL --containers CONTAINERS_PL [--level c1|c2|both] [--strict]
kb/bin/repo-map --facts KB_PL --containers CONTAINERS_PL --level c3 --container ID [--strict]
```

Exit 0 and Markdown on stdout. Exit 2 on a usage error: a missing or unreadable file, an unknown
argument, a `--level` that is not `c1`, `c2`, `c3` or `both`, a containers file with no `repo/1`
fact, `--level c3` without `--container`, `--container` with another level, or a `--container` ID
that has no `container/4` fact. `both` is C1 and C2; C3 is written only with `--level c3`.

## Bad input

- A line that does not parse is skipped, with a warning on stderr that names the file and the line
  (`repo-map: warning: FILE:LINE: ...`). A second `repo(Name)` in the containers file, and a
  repeated `repo(Name, _)` in the facts file, are ignored with the same kind of warning.
- With `--strict`, any such warning makes the tool exit 1 and write no map.
- Two different names that give the same Mermaid id (for example `'a b'` and `a_b`, both `a_b`)
  are refused: exit 2, no map, a message that names both. The ids are not renamed with a suffix,
  so an id in the diagram always equals the name in the file.
- The H1 title is Markdown-escaped, so a repo name cannot add markup or HTML to the title.

## Inputs

1. **The facts file** (`--facts`): the `kb.pl` of a project KB. Only `repo(Name, Location)`
   facts are read. Each one is a system in the C1 list. Every other term is ignored. `Location`
   is never printed.
2. **The containers file** (`--containers`): Prolog facts, one repo per file, committed in that
   repo. The example for this repo is `sagittarius.containers.pl`.

| Fact | Meaning |
|---|---|
| `repo(Name)` | Required. The repo that this file describes. It is the `System` in C1 and the boundary in C2. |
| `about(Name, Text)` | Optional text of a repo or system. |
| `person(Id, Label, Text)` | A person. |
| `external(Id, Label, Text)` | A system that is not a repo (for example a tool). |
| `container(Id, Label, Technology, Text)` | A container of this repo. |
| `component(Id, Container, Label, Technology, Text)` | A component of a container of this repo (C3 only). |
| `link(From, To, Label)` | A link. The ends are person, container, component, repo or external ids. A link from a container shows at C1 as a link from this repo. A link that has a component at one end shows only at C3. |

The example facts are `example-kb.pl`.

## Output

- A title, the line `map@<12 hex>`, then a `C4Context` and a `C4Container` diagram in
  ```` ```mermaid ```` fences.
- C1: the persons, one system per `repo/2` fact (this repo as `System`, the others as
  `System_Ext`), the externals, and the links lifted to the repo level.
- C2: the containers in a `Container_Boundary`; the persons, repos and externals that a link
  touches; the links.
- C3 (`--level c3 --container ID`): a `C4Component` diagram, in place of C1 and C2, under the
  heading `## C3 Components of ID`. The components of container ID in a `Container_Boundary`; the
  links that have a component of ID at one end (each one once); and the other end of each such
  link: a person, a container (`Container`), a component of another container
  (`Component_Ext`), a repo or an external (`System_Ext`).
- Facts that the diagrams do not need are not printed. An end of a link that is not declared is
  dropped from C2 and C1.

## The input hash (`map@`)

`map@` is followed by the first 12 hex digits of the SHA-256 of these bytes, in this order: the
bytes of the facts file, one NUL byte (0x00), the bytes of the containers file. File names,
directories and the clock are not inputs. Equal bytes give an equal map. The check:

```sh
{ cat KB_PL; printf '\0'; cat CONTAINERS_PL; } | sha256sum | cut -c1-12
```

## What the map never carries

The output has no path of any input file, no repo location, and no name of the directory that
holds the project KB. The tool does not know which hub, if any, holds the KB. The map is safe to
commit to a tracker.

## Limits

The Mermaid is checked for structure by the tests (fences, diagram type, known C4 keywords,
balanced parentheses, quotes and braces). It is not rendered by any Mermaid version. C3 covers
one container at a time; C4 (code) is not written.
