Vikunja Helm Chart
===

This Helm Chart deploys both the Vikunja [frontend](https://hub.docker.com/r/vikunja/frontend) and Vikunja [api](https://hub.docker.com/r/vikunja/api) containers, in addition to other Kubernetes resources so that you'll have a fully functioning Vikunja deployment quickly. Also, you can deploy Bitnami's [PostgreSQL](https://github.com/bitnami/charts/tree/main/bitnami/postgresql) and [Redis](https://github.com/bitnami/charts/tree/main/bitnami/redis) as subcharts if you want, as Vikunja can utilize them as its database and caching mechanism (respectively).

## Requirements

- Kubernetes >= 1.19  
- Helm >= 3

## Quickstart

The majority of default values defined in `values.yaml` should be compatible for your deployment. Additionally, if you utilize an Ingress for both the API and Frontend, you will be able to access the frontend out of the box. However, it won't have any default credentials. So, you'll need to create an account using the registration button.

That should be it!

### Use an existing file volume claim

In the `values.yaml` file, you can either define your own existing Persistent Volume Claim (PVC) or have the chart create one on your behalf.

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
      storageClass: storage-class
```

### Modifying Deployed Resources

Often times, modifications need to be made to a Helm chart to allow it to operate in your Kubernetes cluster. By utilizing bjw-s's `common` library, there are quite a few options that can be easily modified.

Anything you see [here](https://github.com/bjw-s/helm-charts/blob/a081de53024d8328d1ae9ff7e4f6bc500b0f3a29/charts/library/common/values.yaml), including the top-level keys, can be added and subtracted from this chart's `values.yaml`, underneath the `api`, `frontend`, and (optionally) `typesense` key.

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

### Another Example of Modifying `config.yml` (Enabling Registration)

You can disable registration (if you do not with to allow others to register on your Vikunja), by providing the following values in your `values.yaml`:

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

If you need to create another user, you could opt to execute the following command on the `api` container:

```bash
./vikunja user create --email <user@email.com> --user <user1> --password <password123>
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
