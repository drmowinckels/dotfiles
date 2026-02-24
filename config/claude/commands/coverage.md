---
description: Check test coverage and suggest improvements
---

Run `Rscript -e "covr::package_coverage()"` and analyze the results.

Based on the coverage report:
1. Identify untested or poorly-tested functions
2. Suggest which functions need more tests
3. Prioritize by importance (exported functions first)
