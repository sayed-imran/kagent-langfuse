#!/usr/bin/env bash
# =============================================================================
# create-langfuse-otel-secret.sh
# Creates or updates the langfuse-otel-auth secret in the kagent namespace
# =============================================================================
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

LANGFUSE_PUBLIC_KEY="${LANGFUSE_PUBLIC_KEY:-pk-lf-29e5bcac-0553-4312-b34c-ba22bfa9c9ca}"
LANGFUSE_SECRET_KEY="${LANGFUSE_SECRET_KEY:-sk-lf-ee7a2001-ee1b-427b-aabb-fabb89c7aed3}"
TARGET_NAMESPACE="${TARGET_NAMESPACE:-kagent}"
SECRET_NAME="langfuse-otel-auth"

info "Generating Langfuse OTel Basic Auth header..."
AUTH_BASE64=$(echo -n "${LANGFUSE_PUBLIC_KEY}:${LANGFUSE_SECRET_KEY}" | base64 | tr -d '\n')
HEADER_VAL="Authorization=Basic ${AUTH_BASE64}"

info "Creating/updating secret '${SECRET_NAME}' in namespace '${TARGET_NAMESPACE}'..."
kubectl create namespace "${TARGET_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "${TARGET_NAMESPACE}" create secret generic "${SECRET_NAME}" \
  --from-literal=AUTH="${HEADER_VAL}" \
  --dry-run=client -o yaml | kubectl apply -f -

ok "Secret '${SECRET_NAME}' successfully created in namespace '${TARGET_NAMESPACE}'"
