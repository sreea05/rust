## What and why

<!-- What does this PR change, and why? Link related issues: "Closes #123". -->

## Checklist

- [ ] PR title follows [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, ...; add `!` for breaking changes)
- [ ] These pass locally: `just ci`{% if uses_unsafe %}, `just miri`{% endif %}{% if fuzzing %}, `just fuzz`{% endif %}
- [ ] Tests added or updated for the change
- [ ] Public items are documented
