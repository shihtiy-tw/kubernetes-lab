---
id: spec-013
title: Developer Experience & Tooling
type: enhancement
priority: medium
status: planned
assignable: true
estimated_hours: 10
tags: [dx, tooling, vscode]
---

# Developer Experience & Tooling for kubernetes-lab

## Overview
Improve developer experience with comprehensive tooling and configurations.

## Tasks

### VS Code Configuration (5 tasks)
- [ ] Create .vscode/settings.json with project settings
- [ ] Write .vscode/tasks.json for common tasks
- [ ] Create .vscode/launch.json for debugging
- [ ] Write .vscode/extensions.json with recommended extensions
- [ ] Create .vscode/snippets/ for code snippets

### Development Scripts (5 tasks)
- [ ] Write environment setup script (./scripts/setup-dev.sh)
- [ ] Create version checker script (./scripts/check-versions.sh)
- [ ] Write dependency installer (./scripts/install-deps.sh)
- [ ] Create alias definitions (.lab-aliases)
- [ ] Write command completion scripts (bash/zsh)

### Developer Documentation (3 tasks)
- [ ] Create developer onboarding checklist
- [ ] Write local development guide
- [ ] Create debugging guide

### Container Development (2 tasks)
- [ ] Create .devcontainer configuration
- [ ] Write Docker Compose for local development

## Configuration Examples

### VS Code Settings
```json
{
  "files.associations": {
    "*.yaml": "yaml",
    "*.yml": "yaml",
    "Makefile": "makefile"
  },
  "editor.formatOnSave": true,
  "editor.rulers": [80, 120],
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "[yaml]": {
    "editor.defaultFormatter": "redhat.vscode-yaml",
    "editor.tabSize": 2
  },
  "[shellscript]": {
    "editor.defaultFormatter": "foxundermoon.shell-format"
  }
}
```

### VS Code Tasks
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Lint All Scripts",
      "type": "shell",
      "command": "make lint",
      "problemMatcher": []
    },
    {
      "label": "Run Tests",
      "type": "shell",
      "command": "make test",
      "problemMatcher": []
    }
  ]
}
```

### Recommended Extensions
```json
{
  "recommendations": [
    "ms-kubernetes-tools.vscode-kubernetes-tools",
    "redhat.vscode-yaml",
    "foxundermoon.shell-format",
    "timonwong.shellcheck",
    "ms-azuretools.vscode-docker",
    "hashicorp.terraform",
    "gruntfuggly.todo-tree"
  ]
}
```

## Acceptance Criteria
- VS Code workspace is fully configured
- Development scripts are executable and tested
- All recommended extensions are documented
- Developer documentation is comprehensive
- Setup scripts work on fresh systems

## Dependencies
- None

## Notes
- Test configurations on Linux, macOS, and Windows (WSL)
- Document minimum required versions
- Provide fallback options for optional tools
- Include troubleshooting section
