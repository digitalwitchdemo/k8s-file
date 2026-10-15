#!/bin/bash
# Runs once, right after 01-init.sql, on the first start of an empty database.
# 01-init.sql creates the users with the demo's default passwords; replace them
# with the real passwords from the postgres-secrets Kubernetes Secret.
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<SQL
ALTER USER astronomy_user WITH PASSWORD '${POSTGRES_ASTRONOMY_PASSWORD}';
ALTER USER monitoring_user WITH PASSWORD '${POSTGRES_MONITORING_PASSWORD}';
SQL
