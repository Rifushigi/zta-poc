## Implementation Guide: Zero Trust Architecture in Hybrid Cloud (Chapters 1–3)

Follow these sequential steps to build your PoC. Each major task is numbered and broken down into clear substeps.

### Core Zero Trust Principles (for reference)

- **1. Never Trust, Always Verify**
- **2. Least Privilege**
- **3. Encrypt All Traffic**
- **4. Continuous Monitoring**

---

### Step 0: Prepare Your Repository

1. **Create project directory**: `project-root`
2. **Initialize Git**: run `git init` (or equivalent).
3. **Add top‑level files and folders** using the structure below:
   ```text
   project-root/
   ├── README.md
   ├── docker-compose.yml
   ├── networks/
   │   ├── onprem-net.yml
   │   └── cloud-net.yml
   ├── identity/
   │   └── keycloak/
   │       ├── realm-config.json
   │       └── client-setup.json
   ├── policy/
   │   └── authz.rego
   ├── certs/
   │   ├── ca.{key,crt}
   │   ├── server.{key,crt}
   │   └── client.{key,crt}
   ├── services/
   │   └── api-gateway/
   │       └── gateway-config.yaml
   └── monitoring/
       ├── logstash.conf
       ├── prometheus.yml
       └── grafana-dashboard.json
   ```
4. **Commit initial layout**: `git add . && git commit -m "Initial project structure"`

---

### Step 1: Simulate the Hybrid Network

1. **Define On‑Prem Network**: Author a Docker network definition file (`networks/onprem-net.yml`) specifying a private subnet (e.g., `172.18.0.0/16`).
2. **Define Cloud Network**: Create `networks/cloud-net.yml` with a distinct subnet (e.g., `192.168.0.0/16`).
3. **Apply Networks**: Have your automation execute creation commands, ensuring idempotency by checking existence first.
4. **Verify**: List Docker networks and confirm both `onprem-net` and `cloud-net` appear, isolated from each other.

---

### Step 2: Deploy Identity Provider (Keycloak)

1. **Start Container**: Launch Keycloak attached to `onprem-net`, exposing admin and token ports.
2. **Configure Realm**:
   - Create a realm named `zero-trust`.
3. **Register Client**:
   - Add a confidential client (e.g., `myapp`), note its client secret.
4. **Create Users & Roles**:
   - Define user accounts (e.g., `adminUser`, `regularUser`) and assign appropriate roles.
5. **Verify Endpoints**: Ensure REST endpoints for token issuance and JWKS retrieval are accessible within the network.

---

### Step 3: Implement Policy Enforcement (OPA)

1. **Launch OPA**: Start OPA server on `onprem-net`, listening on port `8181`.
2. **Write Authorization Policy**:
   - In `policy/authz.rego`, define rules that fetch JWKS from Keycloak, validate JWTs, and enforce role-based access.
3. **Load Policy**: Push `authz.rego` to OPA via its REST API.
4. **Health & Policy Check**: Query OPA’s `/health` and `/data/authz/allow` endpoints to confirm readiness and correct policy behavior.

---

### Step 4: Secure Communication with mTLS

1. **Bootstrap CA**:
   - Generate root CA key and certificate; store in `certs/ca.{key,crt}`.
2. **Generate Service Certificates**:
   - For each service (API gateway, OPA, etc.), create CSR and sign with the CA; store as `service.{key,crt}`.
3. **Distribute Trust**:
   - Configure each service’s trust store to include `ca.crt`.
4. **Test mTLS Handshake**:
   - Use a TLS client tool to attempt connections; expect success with valid certs and failure otherwise.

---

### Step 5: Integrate Authentication & Authorization Flow

1. **Configure API Gateway**:
   - Extract bearer tokens from incoming requests.
2. **Authenticate Tokens**:
   - Gateway queries Keycloak’s JWKS endpoint to verify signature and token claims.
3. **Authorize via OPA**:
   - Send token metadata to OPA’s decision endpoint and receive `allow` or `deny`.
4. **Enforce Decision**:
   - If `allow`, proxy request to backend; if `deny`, respond with `403 Forbidden` or `401 Unauthorized` as appropriate.
5. **Error Handling**:
   - Define clear behaviors for missing/expired tokens and failed mTLS handshakes.

---

### Step 6: Implement Observability

1. **Deploy ELK Stack**:
   - Configure Logstash to ingest logs from Keycloak, OPA, and gateway; parse essential fields.
2. **Set Up Prometheus**:
   - Scrape metrics endpoints from all services (e.g., request rates, latency, policy decision counts).
3. **Create Grafana Dashboards**:
   - Visualize key metrics (e.g., denial rate, average decision latency).
4. **Configure Alerts**:
   - Define thresholds and alerts (e.g., spike in denial rate) to notify via email or Slack.

---

### Step 7: Automate & Validate

1. **Idempotency**: Before each step, check resource existence.
2. **Retries & Backoff**: Implement retry logic for transient errors.
3. **Secrets Management**: Pull credentials from secure stores, not hard‑coded files.
4. **Post‑step Verification**:
   - After setting up each component, run checks (e.g., token fetch, network connectivity test).
5. **Logging**:
   - Record each action’s result in an audit log for traceability.

---

### Step 8: Testing & Validation

After your PoC is deployed, verify each component and the end-to-end flow:

1. **Network Isolation Test**:
   - Attempt to ping a service container on the cloud network from the on-prem network.
   - Expect no connectivity if isolation is working.
2. **Identity Provider Test**:
   - Request a token for each user role via Keycloak’s token endpoint.
   - Confirm valid JWTs are returned and contain expected claims (e.g., `realm`, `client_id`, `roles`).
3. **OPA Policy Test**:
   - Send sample JWTs to OPA’s policy API (`/data/authz/allow`) and verify the response is `true` or `false` as per the policy rules.
4. **mTLS Verification**:
   - Use a TLS-capable client to connect to your API gateway endpoint over HTTPS.
   - Test with a valid client certificate: expect a successful TLS handshake.
   - Test without or with an untrusted certificate: expect handshake failure.
5. **End-to-End Flow Test**:
   - Use an HTTP client to send a request to the gateway with a valid bearer token and valid mTLS credentials: expect a `200 OK` response from your backend service.
   - Repeat with a token for a user lacking required roles: expect a `403 Forbidden` response.
   - Repeat without a token: expect `401 Unauthorized`.
6. **Observability Check**:
   - In Kibana, search logs for sample request trace IDs and confirm log entries exist with proper timestamp and metadata.
   - In Grafana, view dashboards: verify metrics for request counts, decision latencies, and error rates reflect your test activity.
7. **Automated Smoke Tests**:
   - Optionally, script basic checks to run after deployment (e.g., health endpoints, sample request flows) to validate readiness.

---

Use these numbered steps as the AI agent’s execution plan. Each step is self‑contained and includes verification points to ensure reliability.

