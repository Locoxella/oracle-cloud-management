# Git Management Rules

To ensure our work is versioned, recoverable, and professional, I (the Agent) will follow these rules:

## 1. Commits on Milestones
- Every time a significant change or a new feature is completed, I will create a commit.
- Commit messages must be descriptive and follow a clear structure (e.g., `feat:`, `docs:`, `fix:`, `infra:`).

## 2. Protected Files (Gitignore)
- I will NEVER commit sensitive information (passwords, private SSH keys, OCI configuration files with secrets).
- I will exclude transient files like logs (`*.log`), temporary files, or binary artifacts that don't belong in the repo.

## 3. Atomic Changes
- I will try to keep commits atomic (one logical change per commit) to make rollbacks easier.

## 4. Documentation First
- Before starting a major task, I will ensure there is a corresponding markdown file in `memory/` or an update to `Backlog.md`.

## 5. Local Source of Truth
- This repository is the "Seed". Even before we have Gitea, this local folder is the primary source of truth for our Oracle Cloud management.
