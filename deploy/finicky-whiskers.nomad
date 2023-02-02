variable "domain" {
  type        = string
  default     = "finickywhiskers.com"
  description = "hostname"
}

variable "production" {
  type        = bool
  default     = false
  description = "Whether or not this job should run in production mode. Default: false."
}

variable "region" {
  type = string
}

variable "git_ref" {
  type        = string
  default     = "refs/heads/main"
  description = "Git ref to use for the repo clone. Default: refs/heads/main"
}

variable "commit_sha" {
  type        = string
  default     = ""
  description = "Specific commit SHA to check out. Default: empty/none"
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

  # If no commit is provided, we need to attach unique metadata if we want the
  # job to always be recreated and pull the latest changes from the specified
  # git_ref.
  meta {
    run_uuid = var.commit_sha == "" ? "${uuidv4()}" : ""
  }

  group "finicky-whiskers-frontend" {
    count = 3

    update {
      max_parallel      = 1
      canary            = 3
      min_healthy_time  = "10s"
      healthy_deadline  = "10m"
      progress_deadline = "15m"
      auto_revert       = true
      auto_promote      = true
    }

    network {
      port "http" {}
    }

    service {
      name = "finicky-whiskers-${NOMAD_NAMESPACE}"
      port = "http"

      tags = var.production ? [
        # Prod config
        #
        "traefik.enable=true",
        "traefik.http.routers.finicky-whiskers-${NOMAD_NAMESPACE}.rule=Host(`${var.domain}`, `www.${var.domain}`)",
        "traefik.http.routers.finicky-whiskers-${NOMAD_NAMESPACE}.entryPoints=websecure",
        "traefik.http.routers.finicky-whiskers-${NOMAD_NAMESPACE}.tls=true",
        "traefik.http.routers.finicky-whiskers-${NOMAD_NAMESPACE}.tls.certresolver=letsencrypt-cf-prod",
        "traefik.http.routers.finicky-whiskers-${NOMAD_NAMESPACE}.tls.domains[0].main=www.${var.domain}",
        "traefik.http.routers.finicky-whiskers-${NOMAD_NAMESPACE}.tls.domains[1].main=${var.domain}",
        # NOTE: middleware name MUST be unique across a given namespace.
        # If there are duplicates, Traefik errors out and each site using the
        # duplicated name will not be routed to (404).
        "traefik.http.routers.finicky-whiskers-${NOMAD_NAMESPACE}.middlewares=www-redirect",
        "traefik.http.middlewares.www-redirect.redirectregex.regex=^https?://${var.domain}/(.*)",
        "traefik.http.middlewares.www-redirect.redirectregex.replacement=https://www.${var.domain}/$${1}",
        "traefik.http.middlewares.www-redirect.redirectregex.permanent=true",
      ] : [
        # Staging config
        #
        "traefik.enable=true",
        "traefik.http.routers.finicky-whiskers-${NOMAD_NAMESPACE}.rule=Host(`canary.${var.domain}`)",
        "traefik.http.routers.finicky-whiskers-${NOMAD_NAMESPACE}.entryPoints=websecure",
        "traefik.http.routers.finicky-whiskers-${NOMAD_NAMESPACE}.tls=true",
        "traefik.http.routers.finicky-whiskers-${NOMAD_NAMESPACE}.tls.certresolver=letsencrypt-cf-prod",
        "traefik.http.routers.finicky-whiskers-${NOMAD_NAMESPACE}.tls.domains[0].main=canary.${var.domain}"
      ]

      check {
        type     = "http"
        path     = "/.well-known/spin/health"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "server" {
      driver = "exec"

      // Finicky Whiskers can spike quite high for CPU during the initial
      // `spin up` but then settles back down with small CPU spikes
      // during gameplay. Mem appears to stay at around 600-700MB.
      resources {
        cpu = 1000
        memory = 800
      }

      artifact {
        source = "https://github.com/fermyon/spin/releases/download/v0.8.0/spin-v0.8.0-linux-amd64.tar.gz"
        options {
          checksum = "sha256:0ef31fe6e2b4d34ddd089b01a1f88820f88c456276bfe4e1477836a6087654c1"
        }
      }

      artifact {
        source = "https://github.com/kateinoigakukun/wasi-vfs/releases/download/v0.1.1/wasi-vfs-cli-x86_64-unknown-linux-gnu.zip"
        options {
          checksum = "sha256:195148bb459410d40f6250610b5d79824df8b183225acbd8477058d078a0a002"
        }
      }

      env {
        RUST_LOG = "spin=debug"
      }

      template {
        data = <<-EOF
        #!/bin/bash
        set -euxo pipefail

        # Add /local to path for wasi-vfs, spin, etc
        export PATH=${NOMAD_TASK_DIR}:${PATH}

        repo_dir="${NOMAD_ALLOC_DIR}/finicky-whiskers"

        # Capture branch/tag name from full ref
        readonly branch="$(echo ${var.git_ref} | cut -d'/' -f3-)"

        # Directory and contents may be non-empty if this job goes through a retry cycle
        rm -rf ${repo_dir}
        git clone -b ${branch} https://github.com/fermyon/finicky-whiskers.git ${repo_dir}
        cd ${repo_dir}
        # Check out commit if provided
        [[ "${var.commit_sha}" == "" ]] || git checkout ${var.commit_sha}

        cd session && make
        cd ${repo_dir}

        # There may be a cleaner way to do this, but templating doesn't support using
        # a var within the templating directives.
        # For example, 'with service "finicky-whiskers-redis-${NOMAD_NAMESPACE}' isn't allowed.
        {{ with service "finicky-whiskers-redis-prod" }}{{ with index . 0 }}
        export REDIS_ADDRESS_prod=finicky-whiskers-redis-prod.service.consul:{{ .Port }}
        {{ end }}{{ end }}

        {{ with service "finicky-whiskers-redis-staging" }}{{ with index . 0 }}
        export REDIS_ADDRESS_staging=finicky-whiskers-redis-staging.service.consul:{{ .Port }}
        {{ end }}{{ end }}

        if [[ "${var.production}" == "true" ]]; then
          perl -i -pe "s/localhost:6379/${REDIS_ADDRESS_prod}/" spin.toml

          spin up \
            --log-dir ${NOMAD_ALLOC_DIR}/logs \
            --file spin.toml \
            --listen ${NOMAD_ADDR_http} \
            --env REDIS_ADDRESS=redis://${REDIS_ADDRESS_prod}
        else
          perl -i -pe "s/localhost:6379/${REDIS_ADDRESS_staging}/" spin.toml

          spin up \
            --log-dir ${NOMAD_ALLOC_DIR}/logs \
            --file spin.toml \
            --listen ${NOMAD_ADDR_http} \
            --env REDIS_ADDRESS=redis://${REDIS_ADDRESS_staging}
        fi
        EOF
        destination = "${NOMAD_TASK_DIR}/run.bash"
        perms       = "700"
      }

      config {
        command = "${NOMAD_TASK_DIR}/run.bash"
      }
    }
  }

  group "finicky-whiskers-redis" {
    count = 1

    update {
      max_parallel      = 1
      canary            = 1
      min_healthy_time  = "10s"
      healthy_deadline  = "5m"
      progress_deadline = "10m"
      auto_revert       = true
      auto_promote      = true
    }

    network {
      port "db" {
        to = 6379
      }
    }

    task "redis" {
      driver = "docker"

      service {
        name = "finicky-whiskers-redis-${NOMAD_NAMESPACE}"
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
  }

  group "finicky-whiskers-morsel" {
    count = 1

    update {
      max_parallel      = 1
      canary            = 1
      min_healthy_time  = "10s"
      healthy_deadline  = "5m"
      progress_deadline = "10m"
      auto_revert       = true
      auto_promote      = true
    }

    restart {
      attempts = 5
      interval = "10m"
      delay = "30s"
      mode = "fail"
    }

    task "morsel" {
      driver = "exec"

      artifact {
        source = "https://github.com/fermyon/spin/releases/download/v0.8.0/spin-v0.8.0-linux-amd64.tar.gz"
        options {
          checksum = "sha256:0ef31fe6e2b4d34ddd089b01a1f88820f88c456276bfe4e1477836a6087654c1"
        }
      }

      env {
        RUST_LOG = "spin=debug"
      }

      template {
        data = <<-EOF
        #!/bin/bash
        set -euo pipefail

        repo_dir="${NOMAD_ALLOC_DIR}/finicky-whiskers"

        # Capture branch/tag name from full ref
        readonly branch="$(echo ${var.git_ref} | cut -d'/' -f3-)"

        # Directory and contents may be non-empty if this job goes through a retry cycle
        rm -rf ${repo_dir}
        git clone -b ${branch} https://github.com/fermyon/finicky-whiskers.git ${repo_dir}
        cd ${repo_dir}
        # Check out commit if provided
        [[ "${var.commit_sha}" == "" ]] || git checkout ${var.commit_sha}

        # There may be a cleaner way to do this, but templating doesn't support using
        # a var within the templating directives.
        # For example, 'with service "finicky-whiskers-redis-${NOMAD_NAMESPACE}' isn't allowed.
        {{ with service "finicky-whiskers-redis-prod" }}{{ with index . 0 }}
        export REDIS_ADDRESS_prod=finicky-whiskers-redis-prod.service.consul:{{ .Port }}
        {{ end }}{{ end }}

        {{ with service "finicky-whiskers-redis-staging" }}{{ with index . 0 }}
        export REDIS_ADDRESS_staging=finicky-whiskers-redis-staging.service.consul:{{ .Port }}
        {{ end }}{{ end }}

        if [[ "${var.production}" == "true" ]]; then
          perl -i -pe "s/localhost:6379/${REDIS_ADDRESS_prod}/" spin-morsel.toml

          ${NOMAD_TASK_DIR}/spin up \
            --log-dir ${NOMAD_ALLOC_DIR}/logs \
            --file spin-morsel.toml \
            --env REDIS_ADDRESS=redis://${REDIS_ADDRESS_prod}
        else
          perl -i -pe "s/localhost:6379/${REDIS_ADDRESS_staging}/" spin-morsel.toml

          ${NOMAD_TASK_DIR}/spin up \
            --log-dir ${NOMAD_ALLOC_DIR}/logs \
            --file spin-morsel.toml \
            --env REDIS_ADDRESS=redis://${REDIS_ADDRESS_staging}
        fi
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
