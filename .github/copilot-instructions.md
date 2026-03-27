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

## Building

Run `./build.ps1` (requires PowerShell and `cargo`) to build all Rust projects in `src/external/` for the current platform and assemble output into `.dist/`. Use `-Clean` to wipe `.dist/` first.

## CI/CD

`release.yml` runs on push/PR to `master`:
1. **Build job** (matrix: windows, linux, macos): checks out with submodules, installs Rust, builds all Rust projects in `src/external/`, collects binaries + scripts into `.dist/`, uploads as artifacts
2. **Release job** (push only, windows runner): downloads all platform artifacts, signs `.exe` and `.ps1` files via Azure Trusted Signing, copies signed `.ps1` files to other platform bundles, creates per-platform zip archives, publishes GitHub Release

When adding new Rust projects to `src/external/`, the build discovers them automatically via `Cargo.toml`. No workflow changes needed for new projects. New scripts in `src/helpful_scripts/` are also picked up automatically.

## Submodules

This repo uses git submodules under `src/external/`. Always clone with `--recurse-submodules` or run `git submodule update --init --recursive` after cloning. Submodules have their own copilot instructions — follow those when working inside them.
