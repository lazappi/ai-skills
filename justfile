# Run `just --list` to list tasks.

# Dependencies
skills_ref_version := "0.1.1"

# List recipes
default:
    @just --list

# Validate skills, plugin manifests and private data
validate:
    #!/usr/bin/env bash
    set -euo pipefail
    for skill in skills/*/; do
        [ -f "${skill}SKILL.md" ] || continue
        uvx --quiet --from "skills-ref=={{ skills_ref_version }}" agentskills validate "$skill"
    done
    uv run --quiet scripts/validate_skills.py skills --claude-dir claude/skills
    if command -v claude >/dev/null; then
        claude plugin validate . >/dev/null
        claude plugin validate .claude-plugin/marketplace.json >/dev/null
    else
        echo "warning: claude not found, skipping plugin validation" >&2
    fi
    just check-private

# Check for personal data and secrets
check-private:
    #!/usr/bin/env bash
    set -euo pipefail
    uv run --quiet scripts/check_private.py
    if command -v gitleaks >/dev/null; then
        # Scan only publishable files, the same set check_private.py reads
        config="$PWD/.gitleaks.toml"
        tmp="$(mktemp -d)"
        trap 'rm -rf "$tmp"' EXIT
        git ls-files --cached --others --exclude-standard -z |
            while IFS= read -r -d '' f; do [ -e "$f" ] && printf '%s\0' "$f"; done |
            tar --null -T - -cf - | tar -xf - -C "$tmp"
        (cd "$tmp" && gitleaks dir . --no-banner --log-level warn --config "$config")
    else
        echo "warning: gitleaks not found, skipping secret scan" >&2
    fi

# Run the tests
test:
    #!/usr/bin/env bash
    set -euo pipefail
    uv run --quiet --with pytest --with pyyaml pytest tests -q
    # Run the shell tests on macOS's bash 3.2 when it is there, because the
    # scripts must support it
    shell=bash
    if [ -x /bin/bash ] && /bin/bash -c '[ "${BASH_VERSINFO[0]}" -lt 4 ]'; then
        shell=/bin/bash
        export PATH="/bin:$PATH"
    fi
    for t in tests/test_*.sh; do
        [ -f "$t" ] || continue
        "$shell" "$t"
    done

# Use the repo's git hooks
setup:
    git config core.hooksPath .githooks

# Run eval cases for one skill (calls agents)
eval skill *args:
    claude plugin eval . --tag {{ skill }} --no-publish --max-cost-usd 2 {{ args }}

# Link skills and instructions into each agent tool (add --dry-run to preview)
install *args:
    scripts/install.sh install {{ args }}

# Pull this repo, then install again (add --dry-run to preview)
update *args:
    scripts/install.sh update {{ args }}

# Remove only what install created (add --dry-run to preview)
uninstall *args:
    scripts/install.sh uninstall {{ args }}

# Build claude.ai upload zips in dist/ (all skills, or the ones named)
package *skills: validate
    scripts/package.sh {{ skills }}
