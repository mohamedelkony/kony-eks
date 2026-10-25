# Tools

## Infrastructure setup

These tools are needed to run `./init-infra.sh` and bootstrap this cluster:

| Tool | Purpose |
| --- | --- |
| Bash | Runs the infrastructure scripts. |
| AWS CLI | Creates the kubeconfig and accesses AWS. Configure credentials and a default region first. |
| Terraform | Plans and applies the AWS and Kubernetes infrastructure in `terraform/`. |
| kubectl | Checks cluster access and is used by the Flux bootstrap script. |
| Flux CLI | Bootstraps Flux and reconciles the Git repository into the cluster. |
| Git | Supports repository and Flux GitHub operations. |

## Kubernetes and repository work

| Tool | Purpose |
| --- | --- |
| Helm CLI | Useful for inspecting and managing charts manually. Terraform uses its Helm provider, so the Helm CLI is not called directly by `init-infra.sh`. |
| SOPS | Encrypts and decrypts secrets stored in Git. |
| age | Recipient-based encryption and decryption for SOPS. |
| curl | Downloads tool binaries for user-local installation. |
| jq | Optional utility for inspecting JSON from the AWS CLI and Kubernetes APIs. |

The shell scripts also use standard Unix utilities such as `awk`, `grep`, `sed`, and `coreutils`.

## Local setup notes

- Put user-installed binaries in `~/.local/bin` and ensure that directory is on `PATH`.
- `init-infra.sh` needs valid AWS credentials and a configured AWS region.
- `bootstrap-flux.sh` needs cluster-admin access and a GitHub token. It reads the token from `GITHUB_TOKEN` or `~/.netrc`.
- SOPS and age are optional for the current bootstrap path; use them when adding encrypted secrets.
