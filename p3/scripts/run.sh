apt-get update
apt install -y docker.io
systemctl enable docker --now
snap install kubectl --classic
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd
alias k="sudo kubectl"


k3d cluster create atabiti   --port "8080:30007"    --port "8888:30080"
sleep 5


kubectl create namespace argocd
kubectl create namespace dev


kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for ArgoCD pods to be created..."
until  kubectl get pods -n argocd 2>/dev/null | grep -q argocd-server; do
    sleep 5
done




kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort", "ports": [ { "port": 80, "nodePort": 30007 } ]}}'


until  kubectl -n argocd get secret argocd-initial-admin-secret &> /dev/null; do
    sleep 5
done

ARGO_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
sleep 10



argocd login 127.0.0.1:8080 --username admin --password "$ARGO_PASS" --insecure
argocd app create myapp \
  --repo "https://github.com/anastabiti/atabiti-Kubernetes-manifests" \
  --path "." \
  --dest-server "https://kubernetes.default.svc" \
  --dest-namespace "dev" \
  --sync-policy "automated" 

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo "    <---- argocd password:   "
