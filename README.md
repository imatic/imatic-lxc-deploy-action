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
        uses: imatic/imatic-lxc-deploy-action
        with:
          server: "root@${{ env.PROJECT }}-stage.lxc.imatic.cz"
          server_deploy_key: ${{ secrets.DEPLOY_KEY }}
          server_deploy_dir: "/opt/${{ env.PROJECT }}-stage"
          project_domain_name: "stage.${{ env.PROJECT }}.dev.imatic.cz"
          registry: ${{ env.REGISTRY }}
          version: ${{ inputs.version }}
```

## Features

**Core deployment**
- Deploys a Docker Compose stack to an LXC server over SSH via a jumphost
- Evaluates the compose file before deploying (resolves includes/anchors)
- Strips `env_file` entries from all services before deploy

**Configuration**
- Configurable registry (default: `ghcr.io`), image tag (`version`), and compose file path
- Targets a specific service or all services (`service` input)
- Supports `docker compose down` options (e.g. `--remove-orphans`, `--volumes`)
- Creates an external Docker network if specified (`external_network`)

**File copying**
- Copies arbitrary files or directories from the repository to the server before deploy (`copy_files` — space-separated `source:destination` pairs)
- Directories are copied recursively using rsync (contents of source → destination); single files use scp

**Image cleanup**
- Before pulling, removes older versions of any images we build (repositories whose name starts with `PROJECT_IMAGE`, e.g. the `-dbtools` variant), keeping the latest plus `image_keep_n` previous versions (default: `1` — i.e. the version currently running plus the one before it); 3rd-party images are left untouched
- Runs once per deploy, not on every `make start` (e.g. a manual restart after `down` won't trigger it)

**Post-deploy hook**
- Runs an arbitrary `make` target on the server after `make start` succeeds (`post_deploy_make_target`)

**Label generation**
- Generates `imatic.server.*` Docker labels from a list of domain names (`app_servers`)
- Injects labels into a target service (`labels_target`, default: `app`)
- Configurable proxy port (`proxy_pass_port`, default: `8080`)
- Implemented as a separate script (`generate-labels/`) — independently testable and removable
