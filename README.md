Vikunja Helm Chart
===

This Helm Chart deploys both the Vikunja [frontend](https://hub.docker.com/r/vikunja/frontend) and Vikunja [api](https://hub.docker.com/r/vikunja/api) containers, in addition to other Kubernetes resources so that you'll have a fully functioning Vikunja deployment quickly. Also, you can deploy Bitnami's [PostgreSQL](https://github.com/bitnami/charts/tree/main/bitnami/postgresql) and [Redis](https://github.com/bitnami/charts/tree/main/bitnami/redis) as subcharts if you want, as Vikunja can utilize them as its database and caching mechanism (respectively).

See https://artifacthub.io/packages/helm/vikunja/vikunja for version information and installation instructions.

## Quickstart

Define ingress settings according to your controller (for both API and Frontend) to access the application.
You can set all Vikunja API options as yaml under `api.configMaps.config.data.config.yml`: https://vikunja.io/docs/config-options

For example, you can disable registration (if you do not with to allow others to register on your Vikunja), by providing the following values in your `values.yaml`:

```yaml
api:
  configMaps:
    config:
      enabled: true
      data:
        config.yml:
          service:
            enableregistration: false
```

You can still create new users by executing the following command in the `api` container:

```bash
./vikunja user create --email <user@email.com> --user <user1> --password <password123>
```

## Advanced Features

### Replicas

To effectively run multiple replicas of the API, 
make sure to set up the redis cache as well
by setting `api.configMaps.config.data.config.yml.keyvalue.type` to `redis`,
configuring the redis subchart (see [values.yaml](./values.yaml#L119))
and the connection [in Vikunja](https://vikunja.io/docs/config-options/#redis)

### Use an existing file volume claim

In the `values.yaml` file, you can either define your own existing Persistent Volume Claim (PVC) 
or have the chart create one on your behalf.

To have the chart use your pre-existing PVC:

```yaml
api:
  persistence:
    data:
      enabled: true
      existingClaim: <your-claim>
```

To have the chart create one on your behalf:

```yaml
# You can find the default values 
api:
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
api:
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
api:
  envFrom:
    - secretRef:
      name: vikunja-secret-env
  env:
    VIKUNJA_DATABASE_USERNAME: "db-user"
```

This will add all keys within the Kubernetes secret named `vikunja-secret-env` as environment variables to the `api` pod. Additionally, if you did not have the key `VIKUNJA_DATABASE_USERNAME` in the `vikunja-secret-env` secret, you could still define it as an environment variable seen above.

How the `envFrom` key works can be seen [here](https://github.com/bjw-s/helm-charts/blob/a081de53024d8328d1ae9ff7e4f6bc500b0f3a29/charts/library/common/values.yaml#L155).

### Utilizing a Kubernetes secret as the `config.yml` file instead of a ConfigMap

If you did not wish to use the ConfigMap provided by the chart, and instead wished to mount your own Kubernetes secret as the `config.yml` file in the `api` pod, you could provide values such as the following (assuming `asdf-my-custom-secret1` was the name of the secret that had the `config.yml` file):

```yaml
api:
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
underneath the `api`, `frontend`, and (optionally) `typesense` key.

For example, if you wished to create a `serviceAccount` as can be seen [here](https://github.com/bjw-s/helm-charts/blob/a081de53024d8328d1ae9ff7e4f6bc500b0f3a29/charts/library/common/values.yaml#L85-L87) for the `api` pod:

```yaml
api:
  serviceAccount: 
    create: true
```

Then, (for some reason), if you wished to deploy the `frontend` as a `DaemonSet` ([as can be seen here](https://github.com/bjw-s/helm-charts/blob/a081de53024d8328d1ae9ff7e4f6bc500b0f3a29/charts/library/common/values.yaml#L12-L17)), you could do the following:

```yaml
frontend:
  controller:
    type: daemonset
```  

## Publishing

The following steps are automatically performed when a git tag for a new version is pushed to the repository.
They are only listed here for reference.

1. Pull all dependencies before packaging.

  ```shell
  helm dependency update
  ```

2. In order to publish the chart, you have to either use curl or helm cm-push.

  ```shell
  helm package .
  curl --user '<username>:<password>' -X POST --upload-file './<archive>.tgz' https://kolaente.dev/api/packages/vikunja/helm/api/charts
  ```

  ```shell
  helm package .
  helm repo add --username '<username>' --password '<password>' vikunja https://kolaente.dev/api/packages/vikunja/helm
  helm cm-push './<archive>.tgz' vikunja
  ```

  As you can see, you do not have to specify the name of the repository, just the name of the organization.
