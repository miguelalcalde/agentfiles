# Drift

Audit **before** acting. Labels are a signal, not the truth.

| Signal | Likely fix |
| ------ | ---------- |
| `phase:implement` but no AC / thin body | `phase:refine` |
| `phase:refine` but plan.md bar already met | `phase:implement` |
| `phase:research` but facts and questions are already on the issue | `phase:refine` |
| `phase:qa` but no reviewable change | `phase:implement` |
| `status:doing` with no recent activity and no claim comment | Ask; or restore `status:open` |
| `type:fix` but the body is a new capability | `type:feat` |
| Multiple `phase:*` or `status:*` | Keep one of each |
| Legacy `status:unknown` | `phase:refine` + `status:open` |
| Legacy `status:ready` | `phase:implement` + `status:open` |
| Plan file contains file paths / task order | Strip them; still `phase:refine` if product spec is incomplete |

Always comment *why* when relabeling.
