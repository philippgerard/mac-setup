# Public release safety

A public release is ready only when `main` starts from the signed, PII-safe root,
no public branch or tag references unsafe history, and the public tree plus exact
`main` history pass the repository safety checks and Gitleaks.

History replacement does not remove old objects from existing clones or guarantee immediate deletion from GitHub's unreachable-object caches. GitHub Support may need to purge cached commit views and run server-side garbage collection; any third-party clone remains outside the repository owner's control.

For any future sensitive-data incident:

1. commit and tag the new tree using the exact public repository-owner display
   name and GitHub noreply address for both author/committer and tagger
   identities;
2. run `scripts/check-public-safety` on the tree;
3. run `gitleaks dir --redact <filtered-public-tree>`,
   `gitleaks git --staged --redact <repository>`, and
   `gitleaks git --redact <repository>` (all are included in
   `scripts/validate` for the filtered working tree, index, and current
   history);
4. publish from a new sanitized root commit or rewrite the affected history with a reviewed allowlist;
5. run `scripts/check-history-safety <branch-or-commit>` against the exact history that will be published;
6. rotate any credential that was ever committed, even if history is rewritten;
7. update the tested bootstrap revision or release tag.

Before every GitHub web merge, confirm that both the account's display name is
the public repository-owner handle and its commit-email setting uses the
private noreply address. A locally safe branch can otherwise acquire a private
identity on the server-generated merge commit. After merging, run
`scripts/check-history-safety origin/main`, not only against the source branch.
After fetching and pruning every public ref, also run
`scripts/check-history-safety` (its default is `--all`) and
`gitleaks git --redact --log-opts='--all' <repository>`. Normal validation
intentionally scans only the current branch history so a known unsafe remote
ref cannot make unrelated local development permanently red. Gitleaks does not
enforce safe author/tagger identities, so both all-ref checks are required.

Rewriting or replacing public Git history is destructive for existing clones and cannot make already published information unseen. It requires a deliberate force-push or a new repository and is never performed automatically by setup scripts.
