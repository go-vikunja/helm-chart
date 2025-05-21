# Vikunja Helm Chart

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/vikunja)](https://artifacthub.io/packages/search?repo=vikunja)
[![CI](https://github.com/go-vikunja/helm-chart/actions/workflows/ci.yml/badge.svg)](https://github.com/go-vikunja/helm-chart/actions/workflows/ci.yml)

This Helm Chart deploys the [Vikunja](https://hub.docker.com/r/vikunja/vikunja) container
in addition to other Kubernetes resources for a full-featured Vikunja deployment.
This includes Bitnami's [PostgreSQL](https://github.com/bitnami/charts/tree/main/bitnami/postgresql) 
and [Redis](https://github.com/bitnami/charts/tree/main/bitnami/redis) as subcharts if you want,
so Vikunja can use them as database and cache respectively.

See https://artifacthub.io/packages/helm/vikunja/vikunja 
for version information and installation instructions.

## Upgrading to v1

Both Vikunja containers got merged into one with Vikunja version 0.23.
A separate `frontend` configuration is now obsolete,
so deleting that and renaming the key `api` to `vikunja`
should "just work".
The only other major change is that the `configMaps.config` key was renamed to `api-config` 
to highlight again that it only applies to the API.
The Configmap name in the cluster stays the same.

## Quickstart

The Helm chart is published to GitHub Container Registry. To install it:

1. Add the Helm repository:

```bash
helm repo add vikunja oci://ghcr.io/go-vikunja/helm-chart
helm repo update
```

2. Install the chart:

```bash
helm install vikunja vikunja/vikunja -f values.yaml
```

Define ingress settings according to your controller to access the application.
You can configure Vikunja API options as yaml under `vikunja.configMaps.api-config.data.config.yml`:
https://vikunja.io/docs/config-options

For minimal configuration, your `values.yaml` should at least set up ingress:

```yaml
vikunja:
  ingress:
    main:
      enabled: true
      hosts:
        - host: your-domain.com
          paths:
            - path: /
```

For example, you can disable registration (if you do not with to allow others to register on your Vikunja),
by providing the following values in your `values.yaml`:

```yaml
vikunja:
  configMaps:
    api-config:
      enabled: true
      data:
        config.yml:
          service:
            enableregistration: false
```

You can still create new users by executing the following command in the `vikunja` container:

```bash
./vikunja user create --email <user@email.com> --user <user1> --password <password123>
```

To upgrade an existing installation:

```bash
helm upgrade vikunja vikunja/vikunja -f values.yaml
```

## Advanced Features

### Replicas

To effectively run multiple replicas of the API, 
make sure to set up the redis cache as well
by setting `vikunja.configMaps.api-config.data.config.yml.keyvalue.type` to `redis`,
configuring the redis subchart (see [values.yaml](./values.yaml#L119))
and the connection [in Vikunja](https://vikunja.io/docs/config-options/#redis)

### Use an existing file volume claim

In the `values.yaml` file, you can either define your own existing Persistent Volume Claim (PVC) 
or have the chart create one on your behalf.

To have the chart use your pre-existing PVC:

```yaml
vikunja:
  persistence:
    data:
      enabled: true
      existingClaim: <your-claim>
```

To have the chart create one on your behalf:

```yaml
# You can find the default values 
vikunja:
  enabled: true
  persistence:
    data:
      enabled: true
      accessMode: ReadWriteOnce
      size: 10Gi
      mountPath: /app/vikunja/files
      storageClass: storage-class
```

### Utilizing environment variables from Kubernetes secrets

Each environment variable that is "injected" into a pod can be sourced from a Kubernetes secret.
This is useful when you wish to add values that you would rather keep as secrets in your GitOps repo
as environment variables in the pods.

Assuming that you had a Kubernetes secret named `vikunja-env`, 
this is how you would add the value stored at key `VIKUNJA_DATABASE_PASSWORD` as the environment variable named `VIKUNJA_DATABASE_PASSWORD`:

```yaml
vikunja:
  env:
    VIKUNJA_DATABASE_PASSWORD:
      valueFrom:
        secretKeyRef:
          name: vikunja-env
          key: VIKUNJA_DATABASE_PASSWORD
    VIKUNJA_DATABASE_USERNAME: "db-user"
```

If the keys within the secret are the names of environment variables,
you can simplify passing multiple values to this:

```yaml
vikunja:
  envFrom:
    - secretRef:
      name: vikunja-secret-env
  env:
    VIKUNJA_DATABASE_USERNAME: "db-user"
```

This will add all keys within the Kubernetes secret named `vikunja-secret-env` as environment variables to the `vikunja` pod. Additionally, if you did not have the key `VIKUNJA_DATABASE_USERNAME` in the `vikunja-secret-env` secret, you could still define it as an environment variable seen above.

How the `envFrom` key works can be seen [here](https://github.com/bjw-s/helm-charts/blob/a081de53024d8328d1ae9ff7e4f6bc500b0f3a29/charts/library/common/values.yaml#L155).

### Utilizing a Kubernetes secret as the `config.yml` file instead of a ConfigMap

If you did not wish to use the ConfigMap provided by the chart, and instead wished to mount your own Kubernetes secret as the `config.yml` file in the `vikunja` pod, you could provide values such as the following (assuming `asdf-my-custom-secret1` was the name of the secret that had the `config.yml` file):

```yaml
vikunja:
  persistence:
    config:
      type: secret
      name: asdf-my-custom-secret1
```

Then your secret should look something like the following so that it will mount properly:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: asdf-my-custom-secret1
  namespace: vikunja
type: Opaque
stringData:
  config.yml: |
    key1: value1
    key2: value2
    key3: value3
```

### Modifying Deployed Resources

Oftentimes, modifications need to be made to a Helm chart to allow it to operate in your Kubernetes cluster.
Anything you see [in bjw-s' `common` library](https://github.com/bjw-s/helm-charts/blob/a081de53024d8328d1ae9ff7e4f6bc500b0f3a29/charts/library/common/values.yaml),
including the top-level keys, can be added and subtracted from this chart's `values.yaml`, 
underneath the `vikunja` and (optionally) `typesense` key.

For example, if you wished to create a `serviceAccount` as can be seen [here](https://github.com/bjw-s/helm-charts/blob/a081de53024d8328d1ae9ff7e4f6bc500b0f3a29/charts/library/common/values.yaml#L85-L87) for the `vikunja` pod:

```yaml
vikunja:
  serviceAccount: 
    create: true
```

## Publishing

The following steps are automatically performed when a git tag for a new version is pushed to the repository.
They are only listed here for reference.

1. Pull all dependencies before packaging.

  ```shell
  helm dependency update
  ```

2. Package the Helm chart.

  ```shell
  helm package .
  ```

3. Push the package to GitHub Container Registry (OCI).

  ```shell
  echo "$TOKEN" | helm registry login "ghcr.io" --username "$USERNAME" --password-stdin
  helm push vikunja-*.tgz oci://ghcr.io/go-vikunja/helm-chart
  ```

The Helm chart is available at `oci://ghcr.io/go-vikunja/helm-chart`.
