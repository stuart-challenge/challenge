# challenge

A 1-master/1-node/1-bastion OpenShift Origin 3.9 multiple cloud (AWS and GCP) setup, bridged with an IPSec tunnel. Tested with Ansible 2.5.1 & Terraform 0.11.7.

## Setup

Rename `terraform/providers/aws/ca_central_1/secrets.tf.example` and `terraform/providers/gcp/us_east1/secrets.tf.example` to `secrets.tf`, and update to match your target environment.

### Quick start
Ensure your AWS and gcloud CLI tools are configured for your account, and:

```bash
$ make
```

This will execute all build steps described below.

### Build infrastructure commands
- `make infrastructure` - Build AWS and GCP infrastructure. Calls all other build steps.
- `make infrastructure_aws` - Build AWS infrastructure only.
- `make infrastructure_gcp` - Build GCP infrastructure only.
- `make infrastructure_global` - Build AWS/GCP cross-cloud VPN.

### Build OpenShift clusters commands
- `make openshift` - Builds AWS and GCP OpenShift clusters. Calls all other OpenShift steps.
- `make admin_password` - Generate the OpenShift admin password.
- `make openshift_aws` - Build AWS OpenShift cluster only.
- `make openshift_gcp` - Build GCP OpenShift cluster only.

### Destroy infrastructure commands

- `make destroy_infrastructure` - Destroy AWS and GCP infrastructure. Calls all other `destroy` steps.
- `make destroy_infrastructure_global` - Destroy AWS/GCP cross-cloud VPN.
- `make destroy_infrastructure_aws` - Destroy AWS infrastructure only.
- `make destroy_infrastructure_gcp` - Destroy GCP infrastructure only.
