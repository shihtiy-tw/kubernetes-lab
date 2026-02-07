# Quickstart: Project Structure

## Navigation
- **I want to run a scenario**: Go to `<platform>/scenarios/<category>/<name>`.
- **I want to fix a broken script**: Go to `<platform>/utils/` or `<platform>/clusters/`.
- **I want to add a new scenario**: Add generic logic to `shared/scenarios/` then platform wrappers in `<platform>/scenarios/`.

## Common Commands
```bash
# Check structure compliance
make check-structure

# Find where a file belongs
grep -r "my-script" .specify/specs/001-project-structure/data-model.md
```
