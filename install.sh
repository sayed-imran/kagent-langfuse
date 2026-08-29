#!/usr/bin/env bash
# =============================================================================
# install.sh — Full Langfuse deployment orchestrator
# Runs all three steps: cluster → images → deploy
# Usage: ./install.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  Langfuse on Kind — Full Install"
echo "══════════════════════════════════════════════════════════════"
echo ""

echo "── Step 1/3: Create Kind Cluster ─────────────────────────────"
"${SCRIPT_DIR}/scripts/1-create-cluster.sh"
echo ""

echo "── Step 2/3: Preload Container Images ────────────────────────"
"${SCRIPT_DIR}/scripts/2-preload-images.sh"
echo ""

echo "── Step 3/4: Deploy Langfuse ─────────────────────────────────"
"${SCRIPT_DIR}/scripts/3-deploy-langfuse.sh"
echo ""

echo "── Step 4/4: Install Kagent & Agents ─────────────────────────"
"${SCRIPT_DIR}/scripts/4-install-kagent.sh"
echo ""
