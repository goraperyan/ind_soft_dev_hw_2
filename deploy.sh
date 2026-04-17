#!/usr/bin/env bash
set -euo pipefail

NS="logging-hw"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is not installed"
  exit 1
fi

if ! command -v istioctl >/dev/null 2>&1; then
  echo "istioctl is not installed"
  echo "Install it first with: brew install istioctl"
  exit 1
fi

echo "[0/13] Installing or updating Istio"
istioctl install --set profile=demo -y

echo "[0.1/13] Waiting for Istio control plane"
kubectl wait --for=condition=available deployment/istiod -n istio-system --timeout=300s
kubectl wait --for=condition=available deployment/istio-ingressgateway -n istio-system --timeout=300s

echo "[1/13] Applying namespace"
kubectl apply -f k8s/namespace.yaml
kubectl label namespace "$NS" istio-injection=enabled --overwrite

echo "[2/13] Applying ConfigMap"
kubectl apply -f k8s/configmap.yaml

echo "[3/13] Recreating initial test Pod"
kubectl delete pod custom-app-pod-test -n "$NS" --ignore-not-found
kubectl apply -f k8s/pod.yaml
kubectl wait --for=condition=Ready pod/custom-app-pod-test -n "$NS" --timeout=180s

echo "[4/13] Applying Deployment"
kubectl apply -f k8s/deployment.yaml
kubectl rollout status deployment/custom-app -n "$NS" --timeout=300s

echo "[5/13] Applying Service"
kubectl apply -f k8s/service.yaml

echo "[6/13] Applying RBAC for log-agent"
kubectl apply -f k8s/rbac-log-agent.yaml

echo "[7/13] Applying DaemonSet"
kubectl apply -f k8s/daemonset.yaml
kubectl rollout status daemonset/log-agent -n "$NS" --timeout=300s || true

echo "[8/13] Applying StatefulSet"
kubectl apply -f k8s/statefulset.yaml
kubectl rollout status statefulset/backup-store -n "$NS" --timeout=300s || true

echo "[9/13] Applying RBAC for CronJob"
kubectl apply -f k8s/rbac-log-archiver.yaml

echo "[10/13] Applying CronJob"
kubectl apply -f k8s/cronjob.yaml

echo "[11/13] Applying Istio Gateway"
kubectl apply -f k8s/istio-gateway.yaml

echo "[12/13] Applying Istio DestinationRule"
kubectl apply -f k8s/istio-destinationrule.yaml

echo "[13/13] Applying Istio VirtualService"
kubectl apply -f k8s/istio-virtualservice.yaml

echo
echo "===== APP OBJECTS ====="
kubectl get all -n "$NS"

echo
echo "===== ISTIO OBJECTS ====="
kubectl get gateway,virtualservice,destinationrule -n "$NS"

echo
echo "To test via Istio ingress:"
echo "kubectl port-forward -n istio-system svc/istio-ingressgateway 8081:80"
echo "curl http://127.0.0.1:8081/"