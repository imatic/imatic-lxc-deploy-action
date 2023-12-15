# Imatic LXC Deploy Action

Deploys project to LXC instance.

## Requirements

This action require a docker-compose according to certain rules. The compose
file will be given same environment variables as in the build action. The rest
should be placed into deploy directory on the server, into the .env file.

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
