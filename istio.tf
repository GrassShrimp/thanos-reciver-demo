resource "null_resource" "installing-istio-operator" {
  provisioner "local-exec" {
    command = "istioctl operator init"
  }

  depends_on = [ kubernetes_config_map.metallb-config ]
}

resource "kubernetes_namespace" "istio-system" {
  metadata {
    name = "istio-system"
  }
}

resource "null_resource" "installing-istio" {
  provisioner "local-exec" {
    command = "kubectl apply -f ./istio-profile.yaml -n ${kubernetes_namespace.istio-system.metadata[0].name}"
  }

  provisioner "local-exec" {
    command = "sleep 30"
  }

  provisioner "local-exec" {
    command = "kubectl wait deployment --all --timeout=-1s --for=condition=Available -n ${kubernetes_namespace.istio-system.metadata[0].name}"
  }

  provisioner "local-exec" {
    command = "kubectl wait --for=condition=Established --all crd"
  }
  
  depends_on = [ null_resource.installing-istio-operator ]
}