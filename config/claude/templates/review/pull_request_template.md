## Summary

<!-- What changed and why. Link the issue: Closes #N -->

## Testing

<!-- Only what CI does not already prove. Manual checks, visual inspection, depends-only
     runs, snapshot acceptance rationale. Do not restate "tests pass" or "R CMD check clean" —
     CI shows that. If CI covers it entirely, write "Covered by CI." -->

## Risk

<!-- Tier and why. See RISK_TIERS.md -->

- [ ] **T0** — docs, tests, internal refactor with no behaviour change
- [ ] **T1** — new behaviour, additive, no existing contract touched
- [ ] **T2** — exported API, shipped data, dependencies, release, or CI gates

Reverse dependencies affected: <!-- none / list -->

## How to revert

<!-- The specific one-step path. See ROLLBACK.md -->
