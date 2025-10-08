# Hypercommit Infrastructure

Docker-based deployment setup for Hypercommit with Caddy reverse proxy.

## Prerequisites

- Docker and Docker Compose installed on your VPS
- Domain DNS configured:
  - `hypercommit.com` → Your VPS IP
  - `www.hypercommit.com` → Your VPS IP

## Quick Start

1. **Clone the repository** on your VPS:

   ```bash
   git clone <your-repo-url>
   cd hypercommit/infra
   ```

2. **Configure environment variables**:

   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   vim .env
   ```

3. **Deploy**:

   ```bash
   chmod +x start.sh
   ./start.sh
   ```

## What's Included

- **Hypercommit**: Next.js app built with Bun (port 3000, internal)
- **Caddy**: Automatic HTTPS with Let's Encrypt, reverse proxy (ports 80, 443)
- **Domain redirect**: `hypercommit.com` → `www.hypercommit.com`

## Files

- `docker-compose.yml` - Service definitions
- `Caddyfile` - Caddy configuration with HTTPS
- `start.sh` - Deployment script
- `.env.example` - Environment template

## Manual Commands

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# Rebuild after code changes
docker compose down
docker compose build --no-cache
docker compose up -d

# Check service status
docker compose ps
```

## SSL Certificates

Caddy automatically obtains and renews SSL certificates from Let's Encrypt. Certificates are stored in the `caddy-data` volume.

## Logs

- Application logs: `docker compose logs -f hypercommit`
- Caddy logs: `docker compose logs -f caddy`
- Access logs: Stored in the Caddy container at `/data/access.log`

## Updating

```bash
cd hypercommit/infra
./start.sh
```

The script will automatically pull the latest code and rebuild.

## Troubleshooting

**Services not starting:**

```bash
docker compose logs
```

**Certificate issues:**

- Ensure DNS is properly configured
- Check Caddy logs: `docker compose logs caddy`

**Port conflicts:**

- Ensure ports 80 and 443 are available
- Check with: `sudo netstat -tulpn | grep -E ':(80|443)'`
