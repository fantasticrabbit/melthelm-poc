# Example Meltano Project Deployed to a Local Kubernetes Cluster

**Warning:** Here be dragons. This is an attempt to arrive at a minimal config required to launch Meltano on k8s, for design, planning and documentation purposes. It is not yet intended for production use.

## Setup

Before getting started with the deployment, a few tools are needed. These are all cross-platform (MacOS and Windows at least) ad are installable via `brew` or `chocolatey` respectively:

- Docker Desktop for running containers locally
- Kind for deploying Kubernetes into containers
- Terraform for manading the deployment and configuration of Kind
- `kubectl` for interacting with Kubernetes
- `helm` for deploying apps onto Kubernetes
- Lens for exploring the deployment in a lovely UI

If you have deployed applications before, you may already have many of these tools.

## Deployment 🚀

With the above in place, deployment is as simple as:

```bash
# change to the local deployment dir
cd deploy/local
# Initialise Terraform. This installs the required providers.
terraform init
# See what terraform will create
terraform plan
# Apply to deploy
terraform apply
```

## What is actually deployed?

Quite a lot...

- A local docker registry, to push and pull images to and from.
- Promethius for logging of container and kubernetes cluster metrics.
- A Postgres database instance, configured with two databases for Meltano and Airflow.
- An NFS file server provisioner, for logs and output data.
- Nginx ingress controller, to expose Meltano at [localhost](http://localhost) and Airflow at [localhost/airflow](http://localhost/airflow).
- The Meltano UI.
- Airflow.
  - Airflow is deployed in two containers, for the webserver and scheduler.
  - It is configured to use the Kubernetes Executor, which dynamically provisions a pod per task.
  - Logging is centralised using a shared NFS volume mount.

## How do I see what it is doing?

- Check out the respective UI's; Meltano at [localhost](http://localhost) and Airflow at [localhost/airflow](http://localhost/airflow).
- For seeing the containers created, and for connecting directly to them, I recommend using Lens to explore.
  - Meltano and Airflow are deployed into a namespace called `meltano`. Each container can be connected to directly.
- Airflow logs are centralised using a shared NFS volume mounted at `/project/.meltano/run/airflow/logs`. This can be used to access log files directly. Logs are viewable for each task in the Airflow UI too as normal.

## What do I do if something goes wrong?

As kubernetes is just running in docker locally, the ultimate recourse to fixing things is to drop the cluster and start again:

```bash
kind delete cluster --name="meltano-cluster"
```

At that point you will also want to delete the state files generated by terraform too, as they relate to the resources we just deleted. You'll be prompted to run `terraform init` again as we removed the `.terraform` folder for good measure:

```bash
.terraform
.terraform.lock.hcl
terraform.tfstate
terraform.tfstate.backup
meltano-cluster-config
```

Finally, delete the local registry container in Docker Desktop to avoid name-clashes if/when you redeploy.
