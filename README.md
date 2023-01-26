# gcp-nodes
Example terraform for gcp nodes with network config.

## Overview
Create a simple network with two-nodes, for use with Rancher's Custom Cluster feature, where nodes are pre-provisioned.  Then one can pass other configurations/automations to install a Kubernetes distribution like RKE2/K3S/RKE1.
* Requies valid gcp credentials in `.env` file in local working directory
``` 
## example .env
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/project-name-hexidentity.json"
export GCLOUD_PROJECT=$(jq -r '.project_id' $GOOGLE_APPLICATION_CREDENTIALS)
export GCLOUD_REGION="northamerica-northeast2"
```
* Requires ssh key in local dir as well
* uses NVME scratch disk for Longhorn experimentation
* sets up trusted-services (ssl, ssh, vpn) and trusted-nets (local & remote)

## What is the purpose?
I had a [reference architecture](https://github.com/flrichar/fred-arfa) used in AWS for a long time, and wondered how to quickly emulate the same in GCP given proper pre-existing access. 
