Vikunja Helm Chart
===

Deployes both frontend and backend. Also, you can deploy bitnami's PostgreSQL and Redis as subcharts if you want.

## Requirements

Kubernetes >= 1.19  
Helm >= 3

## Quickstart

Default settings should work for you and if you define ingress settings according to your controller (for both API and Frontend), you will be able to access the frontend. Anyway, it won't have any default credentials. In order to create a user, you **have to enable registration** and register a new user.

```yaml
api:
  config:
    service:
      enableregistration: true
```

Once you have registered, you can disable registration back if you do not need it.

## Advanced features

### Raw resources

Often happens, that you have to deploy some cloud-specific resources that are not a part of the application chart itself. You have to either create an extra chart for that, or manage them with other tools (kustomize, plain manifests etc.). That is painful. We have a solution. If you want to create anything that is not present in the chart, *just add it in raw*!

Let's say, you are hosted in [GKE](https://cloud.google.com/kubernetes-engine) and want to use Google-managed TLS certificates. In order to do that, you have to create a ManagedCertificate resource. It can be done this way.

```yaml
frontend:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: gce
    networking.gke.io/managed-certificates: gmc-example-com
  hosts:
  - host: example.com
    paths:
    - path: /
      pathType: Prefix

raw:
- apiVersion: networking.gke.io/v1
  kind: ManagedCertificate
  metadata:
    name: gmc-example-com
  spec:
    domains:
    - example.com
```

Or, let's say, you have decided to use Google SQL database instead of self-hosted, and placed credentials in Google Secret Manager. You plan to use [ExternalSecrets](https://external-secrets.io/v0.7.2/) to get that credentials. These can be easily integrated as well.

```yaml
# Disable embedded database
postgresqlEnabled: false

api:
  config:
    database:
      # Use PostgreSQL database anyway
      type: postgres
  envFrom:
  # Bind env variables from the secret
  - name: VIKUNJA_DATABASE_USER
    valueFrom:
      secretKeyRef:
        name: postgresql-credentials
        key: username
  - name: VIKUNJA_DATABASE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: postgresql-credentials
        key: password
  - name: VIKUNJA_DATABASE_HOST
    valueFrom:
      secretKeyRef:
        name: postgresql-credentials
        key: hostname
  - name: VIKUNJA_DATABASE_DATABASE
    valueFrom:
      secretKeyRef:
        name: postgresql-credentials
        key: database

raw:
- apiVersion: external-secrets.io/v1beta1
  kind: SecretStore
  metadata:
    name: gcpsm
  spec:
    refreshInterval: 300
    provider:
      gcpsm:
        projectID: my-google-project-id

- apiVersion: external-secrets.io/v1beta1
  kind: ExternalSecret
  metadata:
    name: postgresql-credentials
  spec:
    secretStoreRef:
      kind: SecretStore
      name: gcpsm
    target:
      deletionPolicy: Delete
    refreshInterval: 5m
    dataFrom:
    - extract:
        key: cloud-sql-credentials
```

Enjoy!

### Use an existing file volume claim

In the `values.yaml` file, you can configure wether to create the Persistent Volume Claim or use an existing one:


```yaml
    # Specifies whether a PVC should be created
    create: true
    # The name of the PVC to use.
    # If not set and create is true, a name is generated using the fullname template
    name: "" 
```

This is helpful when migrating from a different k8s chart and want to re-use the existing volume or if you need more control over how the volume is created.

## Publishing

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
