variable "domain" {
  type        = string
  default     = "finicky-whiskers.local.fermyon.link"
  description = "hostname"
}

job "finicky-whiskers" {
  datacenters = ["dc1"]
  type        = "service"

  group "finicky-whiskers-frontend" {
    count = 2

    network {
      port "http" {}
    }

    service {
      name = "finicky-whiskers"
      port = "http"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.finicky-whiskers.rule=Host(`${var.domain}`)",
      ]

      check {
        port     = "http"
        name     = "alive"
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "server" {
      driver = "raw_exec"

      artifact {
        source      = "git::git@github.com:fermyon/finicky-whiskers"
        destination = "local/repo"
        options {
          sshkey = "${base64encode(file(pathexpand("~/.ssh/id_rsa")))}"
        }
      }

      env {
        RUST_LOG = "spin=debug"
      }

      config {
        command = "bash"
        args = [
          "-c",
          "cd local/repo/session && make && cd .. && spin up --log-dir ${NOMAD_ALLOC_DIR}/logs --file spin.toml --listen ${NOMAD_ADDR_http} --env REDIS_ADDRESS=redis://${NOMAD_IP_http}:6379"
        ]
      }
    }

  }

  group "finicky-whiskers-backend" {
    network {
      port "db" {
        static = 6379
      }
    }

    task "redis" {
      driver = "docker"

      service {
        name = "finicky-whiskers-redis"
        port = "db"

        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
      config {
        image = "redis:7"
        ports = ["db"]
      }
    }

    task "morsel" {
      driver = "raw_exec"

      artifact {
        source      = "git::git@github.com:fermyon/finicky-whiskers"
        destination = "local/repo"
        options {
          sshkey = "${base64encode(file(pathexpand("~/.ssh/id_rsa")))}"
        }
      }

      env {
        RUST_LOG = "spin=debug"
      }

      config {
        command = "bash"
        args = [
          "-c",
          "cd local/repo && perl -i -pe 's/localhost:6379/${NOMAD_ADDR_db}/' spin-morsel.toml && spin up --log-dir ${NOMAD_ALLOC_DIR}/logs --file spin-morsel.toml --env REDIS_ADDRESS=redis://${NOMAD_ADDR_db}"
        ]
      }
    }

  }
}
