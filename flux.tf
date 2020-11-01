resource "kubernetes_namespace" "flux-ns" {
  metadata {
    annotations = {
      name = "flux"
    }

    labels = {
      name = "flux"
    }

    name = "flux"
  }
}

resource "kubernetes_secret" "flux-secret" {
  metadata {
    name = "flux-git-deploy"
    namespace = "flux"
  }

  type = "Opaque"
}


resource "kubernetes_service_account" "flux-sa" {
  metadata {
    name = "flux"
    namespace = "flux"
    labels = {
      name = "flux"
    }
  }
}

resource "kubernetes_cluster_role" "flux-cr" {
  metadata {
    name = "flux"
    labels = {
      name = "flux"
    }
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    non_resource_urls  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_cluster_role_binding" "flux-crb" {
  metadata {
    name = "flux"
    labels = {
      name = "flux"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "flux"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "flux"
    namespace = "flux"
  }
}

resource "kubernetes_deployment" "flux-dep" {
  metadata {
    name = "flux"
    namespace = "flux"
    labels = {
      name = "flux"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        name = "flux"
      }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          name = "flux"
        }
        annotations = {
          "prometheus.io.port" = "3031"
        }
      }

      spec {
        service_account_name = "flux"
        automount_service_account_token = true
        volume {
          name = "git-key"
          secret {
            secret_name = "flux-git-deploy"
            default_mode = "0400"
          }
        }

        volume {
          name = "git-keygen"
          empty_dir {
            medium = "Memory"
          }
        }

        volume {
          name = "ssh-config"
          config_map {
            name = "flux-ssh-config"
          }
        }

        container {
          name = "flux"
          image = "docker.io/fluxcd/flux:1.20.2"
          image_pull_policy = "IfNotPresent"

          resources {
            requests {
              cpu = "200m"
              memory = "256Mi"
            }
          }

          port {
            container_port = 3030
          }

          volume_mount {
            name = "git-key"
            mount_path = "/etc/fluxd/ssh"
            read_only = true
          }

          volume_mount {
            name = "git-keygen"
            mount_path = "/var/fluxd/keygen"
          }

          args = [
            "--ssh-keygen-dir=/var/fluxd/keygen",
            "--git-url=git@github.com:lkravi/fluxcd-demo.git",
            "--git-branch=master",
            "--git-path=workloads",
            "--git-label=flux",
            "--git-email=lkravi@users.noreply.github.com",
            "--listen-metrics=:3031",
            "--git-poll-interval=2m",
            "--sync-interval=2m",
            "--git-ci-skip=true",
            "--sync-garbage-collection=true"
          ]
        }
      }
    }
  }
  depends_on = [kubernetes_service_account.flux-sa]
}

resource "kubernetes_service" "memcached-svc" {
  metadata {
    name = "memcached"
    namespace = "flux"
  }
  spec {
    selector = {
      name = "memcached"
    }
    port {
      port = 11211
      name = "memcached"
    }
    cluster_ip = "None"
  }
}


resource "kubernetes_deployment" "memcached-dep" {
    metadata {
      name = "memcached"
      namespace = "flux"
      labels = {
        name = "memcached"
      }
    }

    spec {
      replicas = 1

      selector {
        match_labels = {
          name = "memcached"
        }
      }

      template {
        metadata {
          labels = {
            name = "memcached"
          }
        }

        spec {
          container {
            name = "memcached"
            image = "memcached:1.4.25"
            image_pull_policy = "IfNotPresent"

            port {
              container_port = 11211
              name = "clients"
            }

            args = [
              "-m 64",
              "-p 11211"
            ]

          }
        }
      }
    }
  }
