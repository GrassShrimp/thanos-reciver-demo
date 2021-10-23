resource "helm_release" "thanos" {
  name       = "thanos"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "thanos"
  version    = var.THANOS_VERSION
  namespace  = "thanos"
  values = [
    <<EOF
  objstoreConfig: |-
    type: GCS
    config:
      bucket: thanos-c99c6b4736ae76bd36
      service_account: '${replace(file("${path.root}/.keys/gcs_key.json"), "\n", "")}'
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
      enabled: true
      storageClass: "standard"
  storegateway:
    enabled: true
    replicaCount: 1
    persistence:
      enabled: true
      storageClass: "standard"
  ruler:
    persistence:
      enabled: true
      storageClass: "standard"
  receive:
    enabled: true
    replicaCount: 1
    service:
      remoteWrite:
        port: 10908
    persistence:
      enabled: true
      storageClass: "standard"
  minio:
    enabled: true
    accessKey:
      password: "minio"
    secretKey:
      password: "minio123"
    defaultBuckets: thanos-c99c6b4736ae76bd36
  EOF
  ]
  create_namespace = true
  depends_on = [
    kind_cluster.k8s-cluster
  ]
}
resource "local_file" "thanos_route" {
  content = <<-EOF
  apiVersion: networking.istio.io/v1beta1
  kind: Gateway
  metadata:
    name: thanos-query-frontend
  spec:
    selector:
      istio: ingressgateway
    servers:
    - port:
        number: 80
        name: http
        protocol: HTTP
      hosts:
      - thanos.pinjyun.local
  ---
  apiVersion: networking.istio.io/v1beta1
  kind: VirtualService
  metadata:
    name: thanos-query-frontend
  spec:
    hosts:
    - thanos.pinjyun.local
    gateways:
    - thanos-query-frontend
    http:
    - route:
      - destination:
          host: thanos-query-frontend
          port:
            number: 9090
  ---
  apiVersion: networking.istio.io/v1beta1
  kind: Gateway
  metadata:
    name: thanos-minio
  spec:
    selector:
      istio: ingressgateway
    servers:
    - port:
        number: 80
        name: http
        protocol: HTTP
      hosts:
      - minio.pinjyun.local
  ---
  apiVersion: networking.istio.io/v1beta1
  kind: VirtualService
  metadata:
    name: thanos-minio
  spec:
    hosts:
    - minio.pinjyun.local
    gateways:
    - thanos-minio
    http:
    - route:
      - destination:
          host: thanos-minio
          port:
            number: 9001
  EOF
  filename = "${path.root}/configs/thanos_route.yaml"
  provisioner "local-exec" {
    command = "kubectl apply -f ${self.filename} -n ${helm_release.thanos.namespace}"
  }
  depends_on = [
    time_sleep.wait_istio_ready
  ]
}
