# Testing Infrastructure

This directory contains the testing framework for kubernetes-lab.

## Structure

```
tests/
├── README.md             # This file
├── test_helper/          # BATS helpers and utilities
│   ├── common.bash       # Common test utilities
│   ├── bats-support/     # BATS support library (git submodule)
│   └── bats-assert/      # BATS assert library (git submodule)
├── cli/                  # CLI 12-factor compliance tests
│   └── cli-compliance.bats
├── addons/               # Addon-specific tests
│   └── ingress-nginx.bats
├── scenarios/            # Scenario tests
│   └── api-gateway.bats
└── integration/          # Integration tests (require cluster)
```

## Prerequisites

1. Install BATS:
   ```bash
   # macOS
   brew install bats-core

   # Ubuntu
   sudo apt-get install bats

   # From source
   git clone https://github.com/bats-core/bats-core.git
   sudo ./bats-core/install.sh /usr/local
   ```

2. Install helper libraries:
   ```bash
   git clone https://github.com/bats-core/bats-support.git tests/test_helper/bats-support
   git clone https://github.com/bats-core/bats-assert.git tests/test_helper/bats-assert
   ```

## Running Tests

### All Tests

```bash
bats tests/
# or
make test
```

### Specific Test File

```bash
bats tests/cli/cli-compliance.bats
```

### Specific Test

```bash
bats tests/cli/cli-compliance.bats --filter "has --help"
```

### With Verbose Output

```bash
bats tests/ --verbose-run
```

### TAP Output (for CI)

```bash
bats tests/ --formatter tap
```

## Writing Tests

### Basic Test

```bash
#!/usr/bin/env bats

load 'test_helper/common'

@test "script exists and is executable" {
  [ -x "./eks/addons/ingress-nginx/install.sh" ]
}

@test "script has --help flag" {
  run ./eks/addons/ingress-nginx/install.sh --help
  assert_success
  assert_output --partial "Usage:"
}
```

### Using Assertions

```bash
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

@test "exit code is 0 on success" {
  run ./script.sh --help
  assert_success  # exit code 0
}

@test "exit code is 1 on error" {
  run ./script.sh --invalid
  assert_failure  # non-zero exit code
}

@test "output contains expected text" {
  run ./script.sh --version
  assert_output --partial "version"
}

@test "output matches pattern" {
  run ./script.sh --version
  assert_output --regexp "v[0-9]+\\.[0-9]+\\.[0-9]+"
}
```

### Setup and Teardown

```bash
setup() {
  # Run before each test
  export TEST_VAR="value"
}

teardown() {
  # Run after each test
  unset TEST_VAR
}

setup_file() {
  # Run once before all tests in file
}

teardown_file() {
  # Run once after all tests in file
}
```

## Test Categories

### Unit Tests (No Cluster Required)

- CLI compliance (--help, --version, --dry-run)
- Argument parsing
- Input validation
- File structure verification

### Integration Tests (Cluster Required)

- Addon installation/uninstallation
- Resource creation verification
- End-to-end workflows

## CI Integration

Tests run automatically in GitHub Actions:

```yaml
- name: Run Tests
  run: bats tests/
```

## Coverage

To see what's tested:

```bash
# List all test files
find tests -name "*.bats"

# Count tests
grep -r "@test" tests/ | wc -l
```

---

*Last updated: 2026-01-31*
