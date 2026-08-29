#!/usr/bin/env bash
# =============================================================================
# 3-deploy-langfuse.sh — Deploy Langfuse manifests and wait for readiness
# Usage: ./scripts/3-deploy-langfuse.sh
# =============================================================================
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

LANGFUSE_MANIFEST="${SCRIPT_DIR}/../langfuse.yaml"
HOST_PORT=9000
TIMEOUT=300

# ─── Preflight ────────────────────────────────────────────────────────────────
command -v kubectl >/dev/null 2>&1 || error "kubectl is not installed"
[[ -f "${LANGFUSE_MANIFEST}" ]] || error "Langfuse manifest not found at ${LANGFUSE_MANIFEST}"

if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  error "Kind cluster '${CLUSTER_NAME}' does not exist. Run 1-create-cluster.sh first."
fi

# ─── Apply manifests ─────────────────────────────────────────────────────────
info "Applying Langfuse manifests..."
kubectl apply -f "${LANGFUSE_MANIFEST}"
ok "Manifests applied"

# ─── Wait for rollouts ───────────────────────────────────────────────────────
DEPLOYMENTS=(langfuse-postgres langfuse-clickhouse langfuse-redis langfuse-minio langfuse-web langfuse-worker)

info "Waiting for deployments to be ready (timeout: ${TIMEOUT}s)..."
echo ""

for deploy in "${DEPLOYMENTS[@]}"; do
  info "  Waiting for ${deploy}..."
  if kubectl -n "${NAMESPACE}" rollout status "deployment/${deploy}" --timeout="${TIMEOUT}s" 2>/dev/null; then
    ok "  ${deploy} is ready"
  else
    warn "  ${deploy} did not become ready within ${TIMEOUT}s"
    warn "  Check logs: kubectl -n ${NAMESPACE} logs deployment/${deploy}"
  fi
done

# ─── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Langfuse deployment complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${CYAN}UI:${NC}        http://localhost:${HOST_PORT}"
echo -e "  ${CYAN}Login:${NC}     admin@kagent.local / kagent-admin"
echo ""
echo -e "  ${CYAN}Public Key:${NC}  pk-lf-29e5bcac-0553-4312-b34c-ba22bfa9c9ca"
echo -e "  ${CYAN}Secret Key:${NC}  sk-lf-ee7a2001-ee1b-427b-aabb-fabb89c7aed3"
echo ""
echo -e "  ${CYAN}Namespace:${NC}   ${NAMESPACE}"
echo -e "  ${CYAN}Pods:${NC}"
kubectl -n "${NAMESPACE}" get pods -o wide 2>/dev/null | sed 's/^/    /'
echo ""
echo -e "  To tear down: ${YELLOW}kind delete cluster --name ${CLUSTER_NAME}${NC}"
echo ""
