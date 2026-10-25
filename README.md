# kony-eks scripts
sds
Small helper scripts for creating, pausing, resuming, deploying to, and destroying the EKS workshop cluster.

## Configuration

The infrastructure scripts read these environment variables:

```bash
CLUSTER_NAME=elkony-cluster
EXTERNAL_DNS_ENABLED=true
EXTERNAL_DNS_HOSTED_ZONE_ID=Z08854981YJMPOX3Z1L
```

Defaults live in `infra-common.sh`. Override them inline when needed:

```bash
CLUSTER_NAME=my-cluster ./init-infra.sh
```

## Scripts

### `init-infra.sh`

Creates or updates the Terraform infrastructure, updates kubeconfig, and invokes `bootstrap-flux.sh`.

```bash
./init-infra.sh
```

### `bootstrap-flux.sh`

Updates kubeconfig, checks Flux prerequisites, and bootstraps or reconciles Flux. On a new cluster, it reads the GitHub token from `~/.netrc` unless `GITHUB_TOKEN` is already set.

`init-infra.sh` invokes this automatically. Run it directly when you only need to bootstrap or reconcile Flux:

```bash
./bootstrap-flux.sh
```

Flux then applies changes from `manifests/base-application` after they are pushed to GitHub.

### `pause-infra.sh`

Scales managed node groups and Cluster Autoscaler down or back up.

```bash
./pause-infra.sh pause
./pause-infra.sh resume
```

No argument means `pause`.
The script scales the Cluster Autoscaler deployment and calls AWS EKS directly to change managed node group desired sizes because the EKS Terraform module ignores `desired_size` changes after node group creation.

### `deploy-app.sh`

Applies the base application manifests only.

```bash
./deploy-app.sh
```

### `destroy-infra.sh`

Destroys the Terraform infrastructure and performs best-effort cleanup for Kubernetes load balancer resources and residual Elastic IPs.

```bash
./destroy-infra.sh
```

### `check-eks-cluster.sh`

Lists EKS clusters across AWS regions.

```bash
./check-eks-cluster.sh
```
