#!/usr/bin/env bats

setup() {
    export PROJECT_ROOT="$(pwd)"
    # Create a mock bin directory
    export MOCK_BIN="${PROJECT_ROOT}/tests/mock_bin"
    mkdir -p "$MOCK_BIN"
    touch "${MOCK_BIN}/kind" "${MOCK_BIN}/eksctl" "${MOCK_BIN}/gcloud" "${MOCK_BIN}/az" "${MOCK_BIN}/kubectl" "${MOCK_BIN}/aws"
    chmod +x "${MOCK_BIN}/"*
    export PATH="${MOCK_BIN}:${PROJECT_ROOT}/scripts:${PATH}"
}

teardown() {
    rm -rf "$MOCK_BIN"
}

@test "k8s.cluster.create.sh: kind mapping" {
    run k8s.cluster.create.sh --platform kind --name dev --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "kind/clusters/kind-cluster-create.sh --name kind-latest-standard-dev" ]]
}

@test "k8s.cluster.create.sh: eks mapping" {
    run k8s.cluster.create.sh --platform eks --name lab --region us-west-2 --version 1.29 --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "eks/clusters/create.sh --name eks-1-29-standard-lab --region us-west-2 --version 1.29 --config standard" ]]
}

@test "k8s.cluster.create.sh: aks mapping (region to location)" {
    run k8s.cluster.create.sh --platform aks --name test --region eastus --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "aks/clusters/create.sh --name aks-latest-standard-test --location eastus --resource-group aks-latest-standard-test" ]]
}

@test "k8s.cluster.delete.sh: kind deletion mapping" {
    run k8s.cluster.delete.sh --platform kind --name dev --yes --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "kind delete cluster --name dev" ]]
}

@test "k8s.cluster.delete.sh: eks deletion mapping" {
    run k8s.cluster.delete.sh --platform eks --name lab --region us-east-1 --yes --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "eksctl delete cluster --name lab --region us-east-1" ]]
}

@test "k8s.addon.install.sh: search priority (platform over shared)" {
    # ingress-nginx exists in both gke/addons and shared/plugins
    run k8s.addon.install.sh --platform gke --addon ingress-nginx --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "gke/addons/ingress-nginx/install.sh" ]]
}

@test "k8s.addon.install.sh: shared plugin fallback" {
    # metrics-server exists in shared/plugins but not in platform specific
    run k8s.addon.install.sh --platform kind --addon metrics-server --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "shared/plugins/metrics-server/install.sh" ]]
}
