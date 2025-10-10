#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Hypercommit Deployment Script ===${NC}\n"

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}No .env file found. Running initialization script...${NC}\n"
    ./init.sh
    echo ""
fi

# Verify .env has been properly configured
if grep -q "change-me-run-init-script" .env; then
    echo -e "${RED}Error: .env file contains placeholder values!${NC}"
    echo -e "${YELLOW}Please run ${GREEN}./init.sh${YELLOW} to generate secure credentials${NC}"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! docker compose version &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not installed${NC}"
    exit 1
fi

# Pull latest code (if in a git repo)
if [ -d ../.git ]; then
    echo -e "${GREEN}Pulling latest code...${NC}"
    cd ..
    git pull
    cd infra
fi

# Build and start services
echo -e "${GREEN}Building and starting services...${NC}"
docker compose down
docker compose build --no-cache
docker compose up -d

# Wait for PostgreSQL to be healthy
echo -e "${GREEN}Waiting for PostgreSQL to be healthy...${NC}"
sleep 5

# Run database migrations
echo -e "${GREEN}Running database migrations...${NC}"
docker compose exec -T hypercommit sh -c "cd /app && bun run db:push"

# Wait for all services to be healthy
echo -e "${GREEN}Waiting for all services to be healthy...${NC}"
sleep 5

# Check service status
if docker compose ps | grep -q "Up"; then
    echo -e "\n${GREEN}✓ Deployment successful!${NC}"
    echo -e "\n${GREEN}Services status:${NC}"
    docker compose ps
    echo -e "\n${GREEN}Logs:${NC}"
    echo -e "  View all logs: ${YELLOW}docker compose logs -f${NC}"
    echo -e "  View app logs: ${YELLOW}docker compose logs -f hypercommit${NC}"
    echo -e "  View caddy logs: ${YELLOW}docker compose logs -f caddy${NC}"
else
    echo -e "\n${RED}✗ Deployment failed!${NC}"
    echo -e "${YELLOW}Checking logs...${NC}"
    docker compose logs
    exit 1
fi
