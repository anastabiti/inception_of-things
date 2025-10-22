# Kubernetes & K3s Learning Guide

A comprehensive guide to understanding Kubernetes concepts, K3s architecture, and container orchestration fundamentals.

---

## Table of Contents

- [Introduction](#introduction)
- [Core Concepts](#core-concepts)
  - [Cluster Architecture](#cluster-architecture)
  - [Kubernetes Components](#kubernetes-components)
  - [Application Layer](#application-layer)
- [K3s Specifics](#k3s-specifics)
  - [What is K3s?](#what-is-k3s)
  - [K3s Architecture](#k3s-architecture)
  - [K3s vs Standard Kubernetes](#k3s-vs-standard-kubernetes)
- [K3d (K3s in Docker)](#k3d-k3s-in-docker)
- [Networking](#networking)
  - [Services](#services)
  - [Ingress](#ingress)
- [Storage & Configuration](#storage--configuration)
- [ArgoCD Integration](#argocd-integration)
- [Useful Commands](#useful-commands)
- [References](#references)

---

## Introduction

**Why Kubernetes?**

Kubernetes solves critical production challenges:
- **Self-healing**: Automatically restarts crashed containers
- **Scaling**: Runs multiple replicas and load balances traffic
- **Zero-downtime updates**: Rolling updates without service interruption

Think of Kubernetes as a restaurant manager who ensures chefs (containers) are always working, adds more staff during busy times, and handles shift changes seamlessly.

---

## Core Concepts

### Cluster Architecture

A **Cluster** is the complete Kubernetes system consisting of:

1. **Control Plane** (Server/Brain 🧠)
   - Makes all scheduling and management decisions
   - Runs core Kubernetes components

2. **Worker Nodes** (Agents/Muscle 💪)
   - Execute workloads (run your containers)
   - Report status back to control plane

```
┌─────────────────────────────────────┐
│       Control Plane (Server)        │
│  ├── API Server                     │
│  ├── Scheduler                      │
│  ├── Controller Manager             │
│  └── etcd (database)                │
└─────────────────────────────────────┘
              ↓ manages
┌─────────────────────────────────────┐
│         Worker Nodes                │
│  ├── Kubelet (node agent)           │
│  ├── Container Runtime (containerd) │
│  └── Kube-proxy (networking)        │
└─────────────────────────────────────┘
```

### Kubernetes Components

#### Control Plane Components

| Component | Role | Analogy |
|-----------|------|---------|
| **API Server** | Front-end for all cluster operations | Building reception desk |
| **etcd** | Stores all cluster data and state | Database/memory |
| **Scheduler** | Assigns pods to nodes based on resources | Job scheduler |
| **Controller Manager** | Maintains desired state (deployments, replicas, etc.) | Department supervisors |

#### Node Components

| Component | Role | Analogy |
|-----------|------|---------|
| **Kubelet** | Ensures containers are running on the node | Factory foreman |
| **Container Runtime** | Actually runs containers (containerd, CRI-O) | Physical machine engine |
| **Kube-proxy** | Manages networking and service routing | Network mailman |

### Application Layer

#### Pod
- **Smallest deployable unit** in Kubernetes
- Wraps one or more containers
- Containers in a pod share network and storage
- Analogy: A house containing people (containers)

#### Container
- The actual application running (nginx, python app, etc.)
- Isolated process with its own filesystem
- Analogy: Person living in the house (pod)

#### Deployment
- Declares desired state for your application
- Manages pod creation, scaling, and updates
- Provides self-healing and rolling updates
- Analogy: Boss managing a team of workers (pods)

#### Namespace
- Virtual cluster for organizing resources
- Isolates different environments (dev, prod, system)
- Analogy: Departments in a company

---

## K3s Specifics

### What is K3s?

K3s is a **lightweight, certified Kubernetes distribution** packaged as a single binary (<100MB).

**Key Features:**
- All control plane components run in a single process
- Uses SQLite instead of etcd (for single-node)
- Pre-packages essential add-ons (containerd, flannel, traefik)
- Perfect for edge computing, IoT, and development

### K3s Architecture

```
┌─────────────────────────────────────────────┐
│  Single Process: k3s server (PID 2883)      │
│  ├── API Server                             │
│  ├── Scheduler                              │
│  ├── Controller Manager                     │
│  └── etcd/SQLite                            │
└─────────────────────────────────────────────┘
                ↓ manages
┌─────────────────────────────────────────────┐
│  Pre-installed Add-ons (run as pods)        │
│  ├── CoreDNS (DNS resolution)               │
│  ├── Traefik (Ingress controller)           │
│  ├── Metrics Server (resource monitoring)   │
│  └── Local Path Provisioner (storage)       │
└─────────────────────────────────────────────┘
```

### K3s vs Standard Kubernetes

| Feature | Standard K8s | K3s |
|---------|-------------|-----|
| **Binary Size** | ~1GB+ | <100MB |
| **Components** | Separate processes | Single process |
| **Datastore** | etcd cluster | SQLite (single-node) or etcd |
| **Add-ons** | Manual installation | Pre-packaged |
| **Use Case** | Production at scale | Edge, IoT, development |

### K3s Components

**Server Node (Control Plane):**
```bash
# Runs with: k3s server
- API Server
- Scheduler
- Controller Manager
- SQLite/etcd datastore
```

**Agent Node (Worker):**
```bash
# Runs with: k3s agent --server https://<server>:6443 --token <token>
- Kubelet
- Container Runtime (containerd)
- Kube-proxy
```

**Agent Registration Process:**
1. Agent initiates WebSocket connection to server
2. Built-in load balancer manages connection
3. Connects to API server on port 6443
4. Retrieves list of available API servers
5. Maintains stable connections with automatic failover

---

## K3d (K3s in Docker)

**K3d** runs K3s clusters inside Docker containers for local development.

### Why K3d?

| Direct K3s Install | K3d |
|-------------------|-----|
| Single cluster | Multiple clusters simultaneously |
| Modifies host system | Isolated in containers |
| Manual cleanup | `k3d cluster delete` removes everything |
| Permanent | Temporary, disposable clusters |

### Creating a Cluster

```bash
# Create cluster with port mappings
k3d cluster create atabiti \
  --port "8080:30007" \    # Map host 8080 to NodePort 30007
  --port "8888:30080"      # Map host 8888 to NodePort 30080

# List nodes
k3d node list

# Access via kubectl
kubectl get nodes
```

### How kubectl Connects

```
kubectl → ~/.kube/config → localhost:44407 (Docker port) 
  → Docker forwards to container:6443 
  → K3s API Server processes request
```

---

## Networking

### Services

A **Service** provides a stable network endpoint for pods.

#### Service Types

| Type | Description | Use Case | Accessibility |
|------|-------------|----------|---------------|
| **ClusterIP** | Internal IP only | Internal communication | Cluster only |
| **NodePort** | Exposes service on node port (30000-32767) | Testing, development | Node IP + port |
| **LoadBalancer** | Creates external load balancer | Production external access | Public IP |
| **ExternalName** | DNS alias to external service | Access external APIs | N/A |

**Example:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
    - port: 80
      targetPort: 8080
```

### Ingress

An **Ingress** routes external HTTP/HTTPS traffic to services based on rules.

**Architecture:**
```
Internet 
  ↓
Ingress Controller (Traefik/Nginx)
  ↓ (routes based on hostname/path)
Services (ClusterIP)
  ↓
Pods
```

**How Ingress Works:**
1. **Ingress Resource**: YAML file defining routing rules
2. **Ingress Controller**: Program (Traefik, Nginx) that implements the rules
3. Routes traffic based on:
   - Hostname: `api.example.com` → api-service
   - Path: `/api` → api-service, `/blog` → blog-service

**Example:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
```

---

## Storage & Configuration

### ConfigMaps & Secrets

| Resource | Purpose | Security | Example Use |
|----------|---------|----------|-------------|
| **ConfigMap** | Non-sensitive configuration | Plain text | App settings, URLs |
| **Secrets** | Sensitive data | Base64 encoded | Passwords, API keys |

**Usage:**
```yaml
# ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  DATABASE_URL: "postgres://db:5432"
  
# Secret
apiVersion: v1
kind: Secret
metadata:
  name: db-password
type: Opaque
data:
  password: cGFzc3dvcmQxMjM=  # base64 encoded
```

### Persistent Storage

**PersistentVolume (PV)**: Physical storage resource
**PersistentVolumeClaim (PVC)**: Request for storage

**Workflow:**
1. Admin creates PV (storage unit)
2. User creates PVC (storage request)
3. Kubernetes binds PVC to matching PV
4. Pod mounts the volume
5. Data persists across pod restarts

---

## ArgoCD Integration

**ArgoCD** is a GitOps continuous delivery tool for Kubernetes.

### Components

| Component | Role |
|-----------|------|
| **API Server** | Web UI and CLI interface |
| **Repository Server** | Caches Git repos and generates manifests |
| **Application Controller** | Monitors apps and syncs desired state |

### GitOps Workflow

```
Developer pushes to Git
  ↓
ArgoCD detects change (polls every 3 min)
  ↓
Repo Server fetches updated manifests
  ↓
Application Controller compares Git vs Cluster
  ↓
Applies changes to Kubernetes API
  ↓
Deployment Controller creates/updates pods
  ↓
Scheduler assigns pods to nodes
  ↓
Kubelet pulls images and starts containers
```

### Installation

```bash
# Create namespace and install
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Access ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get initial password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

---

## Useful Commands

### Cluster Management

```bash
# K3s
sudo k3s server                          # Start server
sudo k3s agent --server <url> --token <token>  # Join agent

# K3d
k3d cluster create <name>                # Create cluster
k3d cluster delete <name>                # Delete cluster
k3d node list                            # List nodes
```

### Resource Management

```bash
# Pods
kubectl get pods -A                      # All pods in all namespaces
kubectl describe pod <name> -n <ns>      # Pod details
kubectl logs <pod> -n <ns>               # Pod logs
kubectl exec -it <pod> -n <ns> -- sh     # Shell into pod

# Services
kubectl get svc -A                       # All services
kubectl describe svc <name> -n <ns>      # Service details

# Ingress
kubectl get ingress -A                   # All ingress rules
kubectl get ingress -o yaml              # Ingress YAML

# Deployments
kubectl get deployments -A               # All deployments
kubectl scale deployment <name> --replicas=3  # Scale deployment
```

### Debugging

```bash
# Cluster info
kubectl cluster-info
kubectl top nodes                        # Node resource usage
kubectl top pods -A                      # Pod resource usage

# API resources
kubectl api-resources                    # List all resource types
kubectl explain <resource>               # Resource documentation

# ConfigMaps & Secrets
kubectl get configmaps -A
kubectl get secrets -A
kubectl get secret <name> -o yaml        # View secret contents
```

### Container Runtime (containerd)

```bash
# List containers
sudo ctr -n k8s.io containers list

# List images
sudo ctr -n k8s.io images list

# Inside K3d container
docker exec -it <container-id> sh
ctr containers list
crictl ps                                # List running containers
crictl pods                              # List pods
```

---

## References

### Official Documentation
- [Kubernetes Docs](https://kubernetes.io/docs/)
- [K3s Documentation](https://docs.k3s.io/)
- [K3d Documentation](https://k3d.io/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)

### Key Concepts
- [Kubernetes Architecture](https://kubernetes.io/docs/concepts/architecture/)
- [Container Runtime Interface](https://kubernetes.io/docs/concepts/architecture/#container-runtime)
- [Networking](https://kubernetes.io/docs/concepts/services-networking/)
- [Storage](https://kubernetes.io/docs/concepts/storage/)

### Learning Resources
- [Containers vs Pods](https://labs.iximiuz.com/tutorials/containers-vs-pods)
- [K3s GitHub](https://github.com/k3s-io/k3s)

---

## Network Setup Notes

### VirtualBox Network Configuration

**Vagrant VMs:**
- `atabitiS` (server): 192.168.56.110
- `atabitiSW` (worker): 192.168.56.111

**Network Adapters:**
- Adapter 1: NAT (internet access)
- Adapter 2: Host-only Adapter (vboxnet0) - private communication

**How it works:**
- `vboxnet0` acts as virtual switch
- Connects host machine and VMs
- Isolated private network for cluster communication

### Flannel CNI

**Flannel** is K3s's default Container Network Interface plugin.
- Creates overlay network for pod-to-pod communication
- Enables pods on different nodes to communicate
- Handles network routing automatically

---
