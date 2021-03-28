resource "helm_release" "thanos" {
  name              = "thanos"
  repository        = "https://charts.bitnami.com/bitnami" 
  chart             = "thanos"
  version           = "3.14.1"
  namespace         = "thanos"

  values = [
  <<EOF
  objstoreConfig: |-
    type: s3
    config:
      bucket: thanos
      endpoint: {{ include "thanos.minio.fullname" . }}.thanos.svc.cluster.local:9000
      access_key: minio
      secret_key: minio123
      insecure: true
  query:
    replicaCount: 1
    replicaLabel: 
    - cluster
    - prometheus_replica
    - replica
  queryFrontend:
    replicaCount: 1
  compactor:
    enabled: true
    persistence:
      storageClass: "standard"
  storegateway:
    enabled: true
    replicaCount: 1
  receive:
    enabled: true
    replicaCount: 1
    service:
      remoteWrite:
        port: 10908
    persistence:
      storageClass: "standard"
  minio:
    enabled: true
    accessKey:
      password: "minio"
    secretKey:
      password: "minio123"
    defaultBuckets: thanos
  EOF
  ]

  create_namespace  = true

  depends_on = [
    kind_cluster.thanos-reciver
  ]
}

resource "null_resource" "install_thanos_route" {
  provisioner "local-exec" {
    command = "kubectl apply -f ./thanos-route.yaml -n ${helm_release.thanos.namespace}"
  }

  depends_on = [
    null_resource.installing-istio
  ]
}