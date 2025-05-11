# Feature Branch Deployment with FluxCD

This document explains how to use the feature branch deployment system for testing application changes in isolated namespaces.

## Media Feature Branch Deployment

The configuration in `media-feature.yaml` creates:

1. A GitRepository resource that tracks the `feature/media` branch
2. A Kustomization resource that deploys the media application into the `media-feature` namespace using a feature-specific overlay

## How to Use

1. Create your feature branch from main:
   ```bash
   git checkout -b feature/media
   ```

2. Make your changes to the media application in the `apps/staging/media/feature-overlay` directory or in `apps/base/media`.

3. Push your feature branch to GitHub:
   ```bash
   git push -u origin feature/media
   ```

4. FluxCD will automatically detect the new branch and deploy the application to the `media-feature` namespace.

5. Access your feature branch deployment using the `-feature` suffix in resource names.

## Creating Deployments for Other Applications

To create feature branch deployments for other applications:

1. Create a dedicated overlay directory: `apps/staging/<app>/feature-overlay/kustomization.yaml`
2. Create a new GitRepository and Kustomization in a file named `<app>-feature.yaml`
3. Create a namespace for the feature deployment in `<app>-feature-namespace.yaml`

## Cleaning Up

Once your feature branch is merged to main, you can delete the feature branch from GitHub and remove the feature deployment:

```bash
kubectl delete -f clusters/homelab/media-feature.yaml
kubectl delete -f clusters/homelab/media-feature-namespace.yaml
``` 