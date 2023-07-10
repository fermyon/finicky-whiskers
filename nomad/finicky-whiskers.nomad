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
        source = "git::https://github.com/fermyon/finicky-whiskers"
        destination = "local/repo"
      }

      env {
        RUST_LOG = "spin=debug"
      }

      config {
        command = "bash"
        args = [
          "-c",
          "cd local/repo/session && make && cd .. && spin up --log-dir ${NOMAD_ALLOC_DIR}/logs --file spin.toml --listen ${NOMAD_ADDR_http}"
        ]
      }
    }

  }
}
