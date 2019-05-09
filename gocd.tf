provider "google" {
  credentials = "${file("./cred/sec.json")}"
  project = "techops-events"
  region  = "us-central1"
}

resource "google_compute_network" "vpc_network" {
  name = "gocd-vpc-network"
}

resource "google_container_cluster" "gke-cluster" {
  name               = "gocd-cluster"
  network            = "gocd-vpc-network"
  zone               = "us-central1-b"
  initial_node_count = 3
  depends_on = ["google_compute_network.vpc_network"]
}

resource "kubernetes_cluster_role_binding" "clusterRoleBinding" {
    metadata {
        name = "terraform-example"
    }
    role_ref {
        api_group = "rbac.authorization.k8s.io"
        kind = "ClusterRole"
        name = "cluster-admin"
    }
    subject {
        kind = "ServiceAccount"
        name = "default"
        namespace = "kube-system"
    }
    depends_on = ["google_container_cluster.gke-cluster"]
}

data "helm_repository" "stable" {
    name = "stable"
    url  = "https://kubernetes-charts.storage.googleapis.com"
}

resource "helm_release" "example" {
    name      = "gocd"
    chart     = "stable/gocd"
    namespace = "gocd"

    set {
        name  = "name"
        value = "gocd"
    }

    set {
        name = "namespace"
        value = "gocd"
    }
    depends_on = ["kubernetes_cluster_role_binding.clusterRoleBinding"]
}
