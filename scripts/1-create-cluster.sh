#!/usr/bin/env bash
# =============================================================================
# 1-create-cluster.sh — Create a Kind cluster
# Usage: ./scripts/1-create-cluster.sh
# =============================================================================
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

KIND_CONFIG="${SCRIPT_DIR}/../kind-config/kind-config.yaml"

# ─── Preflight ────────────────────────────────────────────────────────────────
command -v kind >/dev/null 2>&1 || error "kind is not installed. Install from https://kind.sigs.k8s.io/"
[[ -f "${KIND_CONFIG}" ]] || error "Kind config not found at ${KIND_CONFIG}"

# ─── Create cluster ──────────────────────────────────────────────────────────
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  warn "Kind cluster '${CLUSTER_NAME}' already exists — skipping creation"
else
  info "Creating Kind cluster '${CLUSTER_NAME}'..."
  kind create cluster --config "${KIND_CONFIG}"
  ok "Kind cluster '${CLUSTER_NAME}' created"
fi

# Verify connectivity
kubectl cluster-info --context "kind-${CLUSTER_NAME}" >/dev/null 2>&1 \
  || error "Failed to connect to Kind cluster"
ok "kubectl connected to kind-${CLUSTER_NAME}"
