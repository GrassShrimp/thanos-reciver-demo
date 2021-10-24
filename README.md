# thanos-reciver-demo

This is a demo for test thanos reciver, thanos reciver let Prometheus as a stateless service

## Prerequisites

- [terraform](https://www.terraform.io/downloads.html)
- [docker](https://www.docker.com/products/docker-desktop)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [helm](https://helm.sh/docs/intro/install/)

download GCS service account credentials to JSON file names gcs_key.json and put it to .keys at project root path

## Usage

initialize terraform module

```bash
$ terraform init
```

create k8s cluster with kind, and install all components - istio, metallb, prometheus, thanos

```
$ terraform apply -auto-approve
```

for destroy

```bash
$ terraform destroy -auto-approve
```

![thanos-reciver](https://github.com/GrassShrimp/thanos-reciver-demo/blob/master/thanos-reciver.png)