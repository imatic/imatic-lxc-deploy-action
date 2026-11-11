# Imatic LXC Deploy Action

Deploys project to LXC instance.

## Requirements

This action require a docker-compose according to certain rules. The compose
file will be given same environment variables as in the build action. The rest
should be placed into deploy directory on the server, into the .env file.

Any references to `env_file` for services in docker-compose files will be
**removed**. Use explicit passing of environment variables in docker-compose file.
This removes the risk of passing variables to services which do not need them.

### Configuration

#### `DEPLOY_KEY`

This key is base64 encoded private key for ssh connection to the server. It needs
to be added to the server as authorized key for root user. It also needs to be
added to the **jumphost**.

## Usage in workflow

This is an example of deployment to stage.

```yaml
name: Deploy

on:
  workflow_call:
    inputs:
      version:
        type: string
        description: "Version to deploy"
        required: false
    secrets:
      DEPLOY_KEY:
        required: true
  workflow_dispatch:
    inputs:
      version:
        description: "Version to deploy"
        required: false
    secrets:
      DEPLOY_KEY:
        required: true

env:
  REGISTRY: ghcr.io
  PROJECT: your-project-name-goes-here

jobs:
  deploy:
    name: Deploy
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Deploy
        uses: imatic/imatic-lxc-deploy-action@dev
        with:
          server: "root@${{ env.PROJECT }}-stage.lxc.imatic.cz"
          server_deploy_key: ${{ secrets.DEPLOY_KEY }}
          server_deploy_dir: "/opt/${{ env.PROJECT }}-stage"
          project_domain_name: "stage.${{ env.PROJECT }}.dev.imatic.cz"
          registry: ${{ env.REGISTRY }}
          version: ${{ inputs.version }}
```

**Pin a version** – `@dev` follows the latest changes; for stable deploys pin a release tag or commit SHA:

```yaml
- uses: imatic/imatic-lxc-deploy-action@v0.1.0
```

## Features

**Core deployment**
- Deploys a Docker Compose stack to an LXC server over SSH via a jumphost
- Evaluates the compose file before deploying (resolves includes/anchors)
- Strips `env_file` entries from all services before deploy

**Configuration**
- Custom registry, image tag, compose file(s), single service, `docker compose down` options and external network

```yaml
- uses: imatic/imatic-lxc-deploy-action@dev
  with:
    # ...
    registry: ghcr.io
    version: ${{ inputs.version }}
    docker_compose_file: .docker/docker-compose.yml -f .docker/docker-compose.prod.yml
    service: app
    down_options: --remove-orphans
    external_network: my-network
```

**File copying**
- Copies files or directories from the repository to the server before deploy (`source:destination`, relative to `server_deploy_dir`)
- Directory contents are copied into the destination directory

```yaml
- uses: imatic/imatic-lxc-deploy-action@dev
  with:
    # ...
    copy_files: >-
      path/to/file.conf:destination/file.conf
      path/to/directory:destination/directory
```

**Image cleanup**
- Runs automatically before pulling, to free disk space
- Removes old versions of project images (repositories starting with `PROJECT_IMAGE`, e.g. the `-dbtools` variant); after the deploy the server holds the deployed version plus `image_keep_n` previous ones
- Images used by any container are never removed; 3rd-party images are left untouched
- Redeploying the same version pulls nothing new, so only `image_keep_n` versions remain afterwards
- A cleanup failure doesn't fail the deploy

```yaml
- uses: imatic/imatic-lxc-deploy-action@dev
  with:
    # ...
    image_keep_n: 2 # default: 1
```

**Post-deploy hook**
- Runs a project `make` target on the server after `make start` succeeds
- The target must be defined in a makefile copied to the server via `copy_files` as `tools/<name>/include.mk` — keep it versioned in the project rather than adding it manually on the host

```yaml
- uses: imatic/imatic-lxc-deploy-action@dev
  with:
    # ...
    copy_files: >-
      .docker/Makefile.stage:tools/local/include.mk
    post_deploy_make_target: post_deploy
```

**Label generation**
- Generates `imatic.server.*` Docker labels for the LXC proxy from a list of domain names and injects them into a compose service
- Implemented as a separate script (`bin/generate-labels.sh`) — independently testable and removable

```yaml
- uses: imatic/imatic-lxc-deploy-action@dev
  with:
    # ...
    app_servers: >-
      www.example.com
      example.com
    labels_target: app # default: app
    proxy_pass_port: 8080 # default: 8080
```

## Make targets

Available on the server in `server_deploy_dir`:

- `make start [SERVICE=...] [DOWN_OPTIONS=...]` — pull images, recreate and start the stack (or a single service)
- `make docker-cleanup [IMAGE_KEEP_N=1]` — remove old versions of project images, keeping the `IMAGE_KEEP_N` most recent
- `make compose <args>` — run any `docker compose` command with the deploy env files (e.g. `make compose ps`)
