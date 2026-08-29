#!/bin/bash
set -euo pipefail

echo "[INFO] Installing kagent-crds..."
helm upgrade --install kagent-crds oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds \
    --namespace kagent \
    --create-namespace

echo "[INFO] Installing kagent with Langfuse OTel tracing..."
helm upgrade --install kagent oci://ghcr.io/kagent-dev/kagent/helm/kagent \
    --namespace kagent \
    -f values.yaml

echo "[INFO] Exposing kagent-ui on NodePort 30000..."
kubectl patch svc kagent-ui -n kagent --type='json' -p='[{"op": "replace", "path": "/spec/type", "value": "NodePort"}, {"op": "add", "path": "/spec/ports/0/nodePort", "value": 30000}]'

echo "[INFO] Creating Langfuse OTel auth secret..."
"$(dirname "${BASH_SOURCE[0]}")/create-langfuse-otel-secret.sh"

echo "[INFO] Applying k8s-reader-agent..."
kubectl apply -k agents/k8s-reader-agent/

echo "[OK] Kagent installation complete."
