# Astronomy Shop on EKS

Kubernetes manifests for running the ecommerce-final-project microservices on the
Final-Project EKS cluster (`aws-network-and-eks-deployment`), deployed by
Argo CD with Kustomize.

## Layout

| Folder | Namespace | Contents | Argo CD wave |
|---|---|---|---|
| `00-base/` | cluster-wide | 4 namespaces, `gp3` StorageClass, `letsencrypt-prod-mergeable` ClusterIssuer, optional NetworkPolicies | -1 |
| `10-ecommerce-data/` | `ecommerce-data` | PostgreSQL, Valkey, Kafka (StatefulSets on gp3) | 1 |
| `20-logging/` | `logging` | OpenSearch, OpenSearch Dashboards | 2 |
| `30-observability/` | `observability` | OTel Collector, OpAMP, Jaeger, Prometheus, Grafana | 3 |
| `40-ecommerce-app/` | `ecommerce-app` | flagd, flagd-ui, 17 shop services | 4 |
| `50-ingress/` | per service | 5 HTTPS Ingresses - **applied by hand after DNS** | — |
| `argocd/` | `argocd` | The Argo CD `Application` | — |
| `create-secrets.sh` | all | Creates every Secret (never stored in Git) | — |

## Public URLs

| URL | Service | Login |
|---|---|---|
| https://shop.digitalwitch.online | Shop (flags at `/feature`, Locust at `/loadgen/`) | public |
| https://grafana.digitalwitch.online | Grafana | Grafana admin (`grafana-admin` Secret) |
| https://jaeger.digitalwitch.online | Jaeger | basic auth |
| https://prometheus.digitalwitch.online | Prometheus | basic auth |
| https://logs.digitalwitch.online | OpenSearch Dashboards | basic auth |

## Prerequisites (EKS Terraform project)

1. Nodes big enough: about 5.5 GiB memory requested, 9.4 GiB limits -> 3 x `t3.large`.
2. `aws-ebs-csi-driver` add-on (for the `gp3` StorageClass).
3. Already there: NGINX ingress, cert-manager + `letsencrypt-prod`, Argo CD, EFS (`efs-sc`).
4. Images in ECR: run the "Build and Push Images to ECR" workflow.

## Deploy

```bash
# 1. Secrets (once)
bash create-secrets.sh

# 2. Give Argo CD read access to this private repo (UI -> Settings -> Repositories)

# 3. Deploy everything except the Ingresses
kubectl apply -f argocd/ecommerce-app.yaml
#    (without Argo CD: kubectl apply --server-side -k .)

# 4. DNS: CNAME shop, grafana, jaeger, prometheus, logs -> NGINX load balancer
#    (terraform output load_balancer_hostname in the EKS project)

# 5. After every name resolves:
kubectl apply -k 50-ingress
kubectl get certificate -A
```

Always use **server-side apply** (`--server-side`): two Grafana dashboard
ConfigMaps are larger than the 256 KB client-side apply allows.

## Updating config copied from ecommerce-final-project

These files are copies (Kustomize can't read outside this folder). Re-copy them
when the originals change:

| Copy | Original |
|---|---|
| `10-ecommerce-data/config/01-init.sql` | `ecommerce-final-project/src/postgresql/init.sql` |
| `30-observability/config/grafana/dashboards/*.json` | `ecommerce-final-project/src/grafana/provisioning/dashboards/demo/*.json` |
| `30-observability/config/grafana/alerting/*` | `ecommerce-final-project/src/grafana/provisioning/alerting/*` |
| `30-observability/config/prometheus-config.yaml` | `ecommerce-final-project/src/prometheus/prometheus-config.yaml` |
| `30-observability/config/jaeger-ui-config.json` | `ecommerce-final-project/src/jaeger/ui-config.json` |
| `40-ecommerce-app/config/otel-config.yml` | `ecommerce-final-project/otel-config.yml` |
| `40-ecommerce-app/config/demo.flagd.json` | `ecommerce-final-project/src/flagd/demo.flagd.json` |

Adapted (not plain copies): `otelcol-config.yml`, `jaeger-config.yml`,
`grafana.ini`, `datasources.yaml`, `app.env`.
