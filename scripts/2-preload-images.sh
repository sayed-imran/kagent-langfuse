#!/usr/bin/env bash
# =============================================================================
# 2-preload-images.sh — Pull and load container images into Kind (3 at a time)
# Usage: ./scripts/2-preload-images.sh
# =============================================================================
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

PARALLEL=3

# Langfuse & Kagent images
IMAGES=(
  # Langfuse components
  "postgres:16-alpine"
  "clickhouse/clickhouse-server:24.12-alpine"
  "redis:7-alpine"
  "langfuse/langfuse:3"
  "langfuse/langfuse-worker:3"
  "minio/minio:latest"

  # Kagent components
  "cr.kagent.dev/kagent-dev/kagent/controller:0.9.12"
  "cr.kagent.dev/kagent-dev/kagent/ui:0.9.12"
  "cr.kagent.dev/kagent-dev/kagent/app:0.9.12"
  "ghcr.io/kagent-dev/kagent/tools:0.2.1"
  "postgres:18.3-alpine"
)

# ─── Preflight ────────────────────────────────────────────────────────────────
command -v docker >/dev/null 2>&1 || error "docker is not installed"
command -v kind   >/dev/null 2>&1 || error "kind is not installed"

if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  error "Kind cluster '${CLUSTER_NAME}' does not exist. Run 1-create-cluster.sh first."
fi

# ─── Helper: run jobs in batches ──────────────────────────────────────────────
run_parallel() {
  local -n _images=$1
  local action_fn=$2

  local pids=()
  local batch_imgs=()

  for img in "${_images[@]}"; do
    "${action_fn}" "${img}" &
    pids+=($!)
    batch_imgs+=("${img}")

    if (( ${#pids[@]} >= PARALLEL )); then
      for i in "${!pids[@]}"; do
        if ! wait "${pids[$i]}"; then
          error "Failed: ${batch_imgs[$i]}"
        fi
      done
      pids=()
      batch_imgs=()
    fi
  done

  # Remaining
  for i in "${!pids[@]}"; do
    if ! wait "${pids[$i]}"; then
      error "Failed: ${batch_imgs[$i]}"
    fi
  done
}

# ─── Pull action ──────────────────────────────────────────────────────────────
pull_image() {
  local img="$1"
  if docker image inspect "${img}" >/dev/null 2>&1; then
    echo -e "  ${GREEN}[CACHED]${NC}  ${img}"
  else
    echo -e "  ${CYAN}[PULL]${NC}    ${img}"
    if docker pull "${img}" >/dev/null 2>&1; then
      echo -e "  ${GREEN}[PULLED]${NC}  ${img}"
    else
      echo -e "  ${RED}[FAIL]${NC}    ${img}" >&2
      return 1
    fi
  fi
}

# ─── Load action ──────────────────────────────────────────────────────────────
load_image() {
  local img="$1"
  echo -e "  ${CYAN}[LOAD]${NC}    ${img}"
  if kind load docker-image "${img}" --name "${CLUSTER_NAME}" >/dev/null 2>&1; then
    echo -e "  ${GREEN}[LOADED]${NC}  ${img}"
  else
    echo -e "  ${RED}[FAIL]${NC}    ${img}" >&2
    return 1
  fi
}

# ─── Execute ──────────────────────────────────────────────────────────────────
info "Pulling ${#IMAGES[@]} images (${PARALLEL} at a time)..."
echo ""
run_parallel IMAGES pull_image
echo ""
ok "All images pulled"
echo ""

info "Loading ${#IMAGES[@]} images into Kind cluster '${CLUSTER_NAME}' (${PARALLEL} at a time)..."
echo ""
run_parallel IMAGES load_image
echo ""
ok "All images loaded into '${CLUSTER_NAME}'"
