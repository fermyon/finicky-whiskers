variable "domain" {
  type        = string
  default     = "www.finickywhiskers.com"
  description = "hostname"
}

variable "region" {
  type = string
}

job "finicky-whiskers" {
  datacenters = [
    "${var.region}a",
    "${var.region}b",
    "${var.region}c",
    "${var.region}d",
    "${var.region}e",
    "${var.region}f"
  ]
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
        "traefik.http.routers.finicky-whiskers.entryPoints=websecure",
        "traefik.http.routers.finicky-whiskers.tls=true",
        "traefik.http.routers.finicky-whiskers.tls.certresolver=letsencrypt-tls-prod",
        "traefik.http.routers.finicky-whiskers.tls.domains[0].main=${var.domain}"
      ]

      check {
        type     = "http"
        path     = "/healthz"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "server" {
      driver = "exec"

      vault {
        policies = ["nomad-server"]
      }

      artifact {
        // TODO: not sure if v0.1.0 will suffice or if we need a more recent build
        // source = "https://github.com/fermyon/spin/releases/download/v0.1.0/spin-v0.1.0-linux-amd64.tar.gz"
        // options {
        //   checksum = "sha256:de01ecd8d67dc218fc82690fd987e67cd8247477d24f0f1ac443a03e549c54ca"
        // }

        // Pinned to https://github.com/fermyon/spin/commit/1d606c707c06f1d4a81e31c2812fdc64e6bdb5f6
        source      = "https://spin-downloads.s3.amazonaws.com/spin-g1d606c7-linux-amd64.tar.gz"
        options {
          checksum  = "sha256:279cda9db7d8e644079435e0f058d6c50abe138de08bcf073234cb69c7b135bd"
        }
      }

      // Added via:
      // vault kv put kv/finicky_whiskers git_ssh_key="$(cat ~/.ssh/finickywhiskers_deploy_key_ed25519)"
      template {
        data = <<-EOH
        {{ with secret "kv/finicky_whiskers"}}{{ .Data.data.git_ssh_key }}{{end}}
        EOH

        destination = "${NOMAD_SECRETS_DIR}/ssh_key"
        perms = "444"
      }

      env {
        RUST_LOG = "spin=debug"
      }

      template {
        data = <<-EOF
        #!/bin/bash
        set -euo pipefail

        export GIT_SSH_COMMAND="ssh -i ${NOMAD_SECRETS_DIR}/ssh_key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

        repo_dir="${NOMAD_ALLOC_DIR}/finicky-whiskers"

        # Directory and contents may be non-empty if this job goes through a retry cycle
        rm -rf ${repo_dir}
        git clone git@github.com:fermyon/finicky-whiskers.git ${repo_dir}

        cd ${repo_dir}/session
        make
        cd ${repo_dir}

        {{ with service "finicky-whiskers-redis" }}{{ with index . 0 }}
        REDIS_ADDRESS=redis://finicky-whiskers-redis.service.consul:{{ .Port }}
        {{ end }}{{ end }}

        perl -i -pe "s/localhost:6379/${REDIS_ADDRESS}/" spin.toml

        ${NOMAD_TASK_DIR}/spin up \
          --log-dir ${NOMAD_ALLOC_DIR}/logs \
          --file spin.toml \
          --listen ${NOMAD_ADDR_http} \
          --env REDIS_ADDRESS=${REDIS_ADDRESS}
        EOF
        destination = "${NOMAD_TASK_DIR}/run.bash"
        perms       = "700"
      }

      config {
        command = "${NOMAD_TASK_DIR}/run.bash"
      }
    }
  }

  group "finicky-whiskers-backend" {
    network {
      port "db" {
        to = 6379
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
      driver = "exec"

      vault {
        policies = ["nomad-server"]
      }

      artifact {
        // TODO: not sure if v0.1.0 will suffice or if we need a more recent build
        // source = "https://github.com/fermyon/spin/releases/download/v0.1.0/spin-v0.1.0-linux-amd64.tar.gz"
        // options {
        //   checksum = "sha256:de01ecd8d67dc218fc82690fd987e67cd8247477d24f0f1ac443a03e549c54ca"
        // }

        // Pinned to https://github.com/fermyon/spin/commit/1d606c707c06f1d4a81e31c2812fdc64e6bdb5f6
        source      = "https://spin-downloads.s3.amazonaws.com/spin-g1d606c7-linux-amd64.tar.gz"
        options {
          checksum  = "sha256:279cda9db7d8e644079435e0f058d6c50abe138de08bcf073234cb69c7b135bd"
        }
      }

      // Added via:
      // vault kv put kv/finicky_whiskers git_ssh_key="$(cat ~/.ssh/finickywhiskers_deploy_key_ed25519)"
      template {
        data = <<-EOH
        {{ with secret "kv/finicky_whiskers"}}{{ .Data.data.git_ssh_key }}{{end}}
        EOH

        destination = "${NOMAD_SECRETS_DIR}/ssh_key"
        perms = "444"
      }

      env {
        RUST_LOG = "spin=debug"
      }

      template {
        data = <<-EOF
        #!/bin/bash
        set -euo pipefail

        export GIT_SSH_COMMAND="ssh -i ${NOMAD_SECRETS_DIR}/ssh_key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

        repo_dir="${NOMAD_ALLOC_DIR}/finicky-whiskers"

        # Directory and contents may be non-empty if this job goes through a retry cycle
        rm -rf ${repo_dir}
        git clone git@github.com:fermyon/finicky-whiskers.git ${repo_dir}

        cd ${repo_dir}
        perl -i -pe "s/localhost:6379/${NOMAD_HOST_ADDR_db}/" spin-morsel.toml

        ${NOMAD_TASK_DIR}/spin up \
          --log-dir ${NOMAD_ALLOC_DIR}/logs \
          --file spin-morsel.toml \
          --env REDIS_ADDRESS=redis://${NOMAD_HOST_ADDR_db}
        EOF
        destination = "${NOMAD_TASK_DIR}/run.bash"
        perms       = "700"
      }

      config {
        command = "${NOMAD_TASK_DIR}/run.bash"
      }
    }
  }
}
