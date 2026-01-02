# Keycloak Monitoring Setup

## Steps to Deploy

1. **Create the keycloak network first:**

   ```bash
   cd /Users/imshakil/cloudOps/keycloak
   docker-compose up -d
   ```

2. **Start monitoring stack:**

   ```bash
   cd /Users/imshakil/cloudOps/monitoring
   docker-compose up -d
   ```

3. **Import Keycloak Dashboard:**

   - Open Grafana at http://localhost:9094
   - Go to Dashboards → Import
   - Upload the `keycloak-dashboard.json` file
   - Select "Loki" as the data source

## LogQL Queries for Keycloak

- **All Keycloak logs:** `{container_name="keycloak"}`
- **Error logs only:** `{container_name="keycloak"} |~ "(?i)(error|exception|failed|warn)"`
- **Auth events:** `{container_name="keycloak"} |~ "(?i)(login|logout|auth|token)"`
- **Specific time range:** `{container_name="keycloak"} |~ "pattern" | json`

## Troubleshooting

- Check if containers are running: `docker ps`
- Verify logs are being collected: `docker logs promtail`
- Test Loki connection: `curl http://localhost:3100/ready`