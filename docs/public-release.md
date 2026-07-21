# Public release safety

The published `main` branch was replaced with a signed, PII-safe root commit. No other public branch or tag references the previous history. The public tree and exact `main` history pass the repository safety checks and Gitleaks.

History replacement does not remove old objects from existing clones or guarantee immediate deletion from GitHub's unreachable-object caches. GitHub Support may need to purge cached commit views and run server-side garbage collection; any third-party clone remains outside the repository owner's control.

For any future sensitive-data incident:

1. commit the new tree using the pseudonymous public identity and GitHub noreply address;
2. run `scripts/check-public-safety` on the tree;
3. publish from a new sanitized root commit or rewrite the affected history with a reviewed allowlist;
4. run `scripts/check-history-safety <branch-or-commit>` against the exact history that will be published;
5. rotate any credential that was ever committed, even if history is rewritten;
6. update the tested bootstrap revision or release tag.

Rewriting or replacing public Git history is destructive for existing clones and cannot make already published information unseen. It requires a deliberate force-push or a new repository and is never performed automatically by setup scripts.
