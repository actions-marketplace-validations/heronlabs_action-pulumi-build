# Pulumi Build Action

A GitHub Action that runs a Pulumi command against an **engine** repository (the Pulumi program), overlaying the **caller repo's** stack configuration on top of it, then publishes the command output as both a job summary and an uploaded artifact.

The action checks out a pinned ref of the engine, copies the caller's `Pulumi.yaml`, per-stack `Pulumi.<stack>.yaml`, and `environments/` onto it, installs dependencies with pnpm, and invokes [`pulumi/actions@v6`](https://github.com/pulumi/actions) for the requested `command`/`stack`.

## Requirements

### Prerequisite: checkout the caller repo

The action overlays the stack config from the **current workspace**, so the calling workflow must `actions/checkout` its own repository first. These must be present at the workspace root:

- `Pulumi.yaml`
- one or more `Pulumi.<stack>.yaml`
- an `environments/` directory

The engine itself (the Pulumi program plus `package.json`, `.node-version`, and `pnpm-lock.yaml`) is checked out by the action from `engine-repo`.

### Secrets

| Secret | Used for |
|--------|----------|
| `pat` | A GitHub PAT with **read** access to `engine-repo` (the default `GITHUB_TOKEN` cannot read other repos). |
| `pulumi-token` | A Pulumi access token used as `PULUMI_ACCESS_TOKEN` to authenticate with the Pulumi backend. |

### Supported Runners

- `ubuntu-24.04` (recommended)
- `ubuntu-22.04`
- `ubuntu-latest`

### Dependencies (internal)

- `actions/checkout@v6`
- `pnpm/action-setup@v5`
- `actions/setup-node@v6`
- `pulumi/actions@v6`
- `actions/upload-artifact@v4`

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `command` | Pulumi command to run (e.g. `preview`, `up`, `destroy`, `refresh`) | Yes | — |
| `environment` | Pulumi stack name to target (e.g. `production`, `sandbox`, `shared`) | Yes | — |
| `engine-repo` | Repo (`owner/name`) holding the Pulumi engine (program, `package.json`, `.node-version`, pnpm lockfile) | Yes | — |
| `engine-ref` | Git ref (tag, branch, or SHA) of `engine-repo` to check out | Yes | — |
| `pat` | GitHub PAT with read access to the engine repository | Yes | — |
| `pulumi-token` | Pulumi access token (`PULUMI_ACCESS_TOKEN`) | Yes | — |

## Outputs

| Name | Description |
|------|-------------|
| `output` | Raw stdout from the Pulumi command. |

The action also writes a `pulumi-report.txt` to the workspace and uploads it as artifact `pulumi-<environment>-<command>`. The same report is appended to the job summary. Both run on `always()`, so the report is produced even when the Pulumi step fails.

## Usage

```yaml
name: Deploy

on:
  workflow_dispatch:
    inputs:
      command:
        description: Pulumi command
        required: true
        default: preview
      environment:
        description: Stack name
        required: true
        default: sandbox

permissions:
  contents: read

jobs:
  cd:
    name: ${{ inputs.command }} | ${{ inputs.environment }}
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v6

      - uses: heronlabs/action-pulumi-build@v1
        with:
          command: ${{ inputs.command }}
          environment: ${{ inputs.environment }}
          engine-repo: my-org/my-engine
          engine-ref: v1.4.0
          pat: ${{ secrets.PAT }}
          pulumi-token: ${{ secrets.PULUMI_TOKEN }}
```

## Notes

- **Engine is pinned via `engine-ref`**, so deployments are reproducible. Bump it to adopt a new engine version.
- **Overlay precedence.** `Pulumi.yaml`, `Pulumi.*.yaml`, and `environments/` from the caller are copied *into* the engine checkout, overwriting any engine defaults of the same name.
- **Node/pnpm versions come from the engine.** `node-version-file` and the pnpm lockfile are read from `engine/`, so the toolchain matches whatever the engine pins.
- **Environment protection / approval gates** are configured on the GitHub Environment, not in this action. To require manual approval before `up`/`destroy`, add Required Reviewers to the matching environment in repo settings.

## License

MIT
