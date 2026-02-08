# Spec 004 Data Model

## Directory Structure
```text
scenarios/
├── general/                 # Platform-agnostic
│   ├── pod-basic/
│   │   ├── README.md
│   │   ├── manifests/
│   │   │   └── pod.yaml
│   │   └── kuttl-test.yaml
│   └── network-policy/
│       ├── manifests/
│       │   └── deny-all.yaml
│       └── kuttl-test.yaml
├── network/                 # CNI-Specific
│   ├── cilium/
│   │   └── l7-policy/
│   └── calico/
│       └── global-policy/
├── eks/
├── gke/
└── aks/
```

## Scenario Interface (KUTTL)

### `kuttl-test.yaml`
```yaml
apiVersion: kuttl.dev/v1beta1
kind: TestSuite
testDirs:
  - ./
commands:
  - command: kubectl apply -f manifests/
```

## Automation Command
`.opencode/command/k8s.test.integration.md` -> `scripts/test.sh`

**Arguments:**
- `--suite [general|network|eks|gke|aks]`: Run a category of tests
- `--scenario [path/to/scenario]`: Run single test
- `--cni [cilium|calico|native]`: (Metadata tag) Inform test runner of current CNI
