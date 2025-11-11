#!/bin/bash

# OpenSearch Dashboards Deployment Script
# This script deploys OpenSearch Dashboards to your Kubernetes cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="oodle-otel-demo"
DEPLOYMENT_NAME="opensearch-dashboards"
SERVICE_NAME="opensearch-dashboards"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}OpenSearch Dashboards Deployment Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

# Check if namespace exists
echo -e "${YELLOW}Checking if namespace '${NAMESPACE}' exists...${NC}"
if ! kubectl get namespace ${NAMESPACE} &> /dev/null; then
    echo -e "${YELLOW}Namespace '${NAMESPACE}' does not exist. Creating it...${NC}"
    kubectl create namespace ${NAMESPACE}
else
    echo -e "${GREEN}Namespace '${NAMESPACE}' exists.${NC}"
fi

# Check if OpenSearch is running
echo -e "${YELLOW}Checking if OpenSearch is running...${NC}"
if ! kubectl get statefulset opensearch -n ${NAMESPACE} &> /dev/null; then
    echo -e "${RED}Warning: OpenSearch StatefulSet not found in namespace '${NAMESPACE}'${NC}"
    echo -e "${YELLOW}OpenSearch Dashboards requires OpenSearch to be running.${NC}"
    read -p "Do you want to continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}OpenSearch is deployed.${NC}"
    
    # Check if OpenSearch pods are ready
    READY_PODS=$(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=opensearch -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' | grep -o "True" | wc -l | tr -d ' ')
    if [ "$READY_PODS" -eq "0" ]; then
        echo -e "${YELLOW}Warning: OpenSearch pods are not ready yet.${NC}"
        echo -e "${YELLOW}You may want to wait for OpenSearch to be ready before deploying dashboards.${NC}"
    else
        echo -e "${GREEN}OpenSearch pods are ready.${NC}"
    fi
fi

# Deploy OpenSearch Dashboards
echo ""
echo -e "${YELLOW}Deploying OpenSearch Dashboards...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kubectl apply -f "${SCRIPT_DIR}/opensearch-dashboards.yaml"

# Wait for deployment to be ready
echo ""
echo -e "${YELLOW}Waiting for OpenSearch Dashboards to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/${DEPLOYMENT_NAME} -n ${NAMESPACE} || {
    echo -e "${RED}Deployment did not become ready within 5 minutes${NC}"
    echo -e "${YELLOW}Checking pod status...${NC}"
    kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=${DEPLOYMENT_NAME}
    echo ""
    echo -e "${YELLOW}Recent logs:${NC}"
    kubectl logs -n ${NAMESPACE} -l app.kubernetes.io/name=${DEPLOYMENT_NAME} --tail=20
    exit 1
}

echo -e "${GREEN}OpenSearch Dashboards deployed successfully!${NC}"

# Display access information
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "To access OpenSearch Dashboards:"
echo ""
echo -e "${YELLOW}1. Port Forward (Local Access):${NC}"
echo -e "   kubectl port-forward -n ${NAMESPACE} svc/${SERVICE_NAME} 5601:5601"
echo -e "   Then open: ${GREEN}http://localhost:5601${NC}"
echo ""
echo -e "${YELLOW}2. Check Status:${NC}"
echo -e "   kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=${DEPLOYMENT_NAME}"
echo ""
echo -e "${YELLOW}3. View Logs:${NC}"
echo -e "   kubectl logs -n ${NAMESPACE} -l app.kubernetes.io/name=${DEPLOYMENT_NAME} --tail=50 -f"
echo ""
echo -e "${YELLOW}4. Default Credentials:${NC}"
echo -e "   Username: ${GREEN}admin${NC}"
echo -e "   Password: ${GREEN}admin${NC}"
echo -e "   ${RED}(Change these in production!)${NC}"
echo ""

# Ask if user wants to port-forward now
read -p "Do you want to start port-forwarding now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Starting port-forward...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    echo -e "Opening ${GREEN}http://localhost:5601${NC} in your browser..."
    sleep 2
    
    # Try to open in browser (works on macOS, Linux with xdg-open, Windows with start)
    if command -v open &> /dev/null; then
        open "http://localhost:5601" &
    elif command -v xdg-open &> /dev/null; then
        xdg-open "http://localhost:5601" &
    elif command -v start &> /dev/null; then
        start "http://localhost:5601" &
    fi
    
    kubectl port-forward -n ${NAMESPACE} svc/${SERVICE_NAME} 5601:5601
fi

