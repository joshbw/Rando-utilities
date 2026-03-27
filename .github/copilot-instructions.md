# Copilot Instructions for Rando-utilities

## Repository overview

A collection of cross-platform shell utilities and external tool submodules. No build system, test framework, or package manager — these are standalone scripts.

## Repository structure

- `src/helpful_scripts/` — Original shell utilities, each implemented as a .cmd/.ps1/.sh triplet (except `RefreshEnv.cmd` and `setup_machine.ps1` which are Windows-only)
- `src/external/` — Git submodules pulling in other utility repos (e.g., `rscalc`). These have their own build systems and copilot instructions — defer to those.

## Conventions

### Cross-platform triplets

`math`, `up`, and `mdcd` each exist as `.cmd`, `.ps1`, and `.sh` files implementing identical behavior per platform. When modifying logic in one variant, update all three to stay in sync.

### Script documentation

- PowerShell scripts use full comment-based help blocks (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`)
- Bash scripts use inline comments
- CMD scripts have minimal or no comments

### Naming

Lowercase filenames, no underscores in utility names (except `setup_machine.ps1` which is a provisioning script, not a daily utility).

## CI/CD

`release.yml` runs on push/PR to `master`:
1. Signs `.ps1` files via Azure Trusted Signing
2. Zips all utilities into `jbw_utils.zip`
3. Creates a GitHub Release with date-based tag (`v2025.03.27-abc1234`)

**Important**: The zip step must explicitly list every file to include. When adding new scripts, update the `Compress-Archive` file list in `.github/workflows/release.yml`.

## Submodules

This repo uses git submodules under `src/external/`. Always clone with `--recurse-submodules` or run `git submodule update --init --recursive` after cloning. Submodules have their own copilot instructions — follow those when working inside them.
