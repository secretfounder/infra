#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Hypercommit Infrastructure Initialization ===${NC}\n"

# Function to generate secure random password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-32
}

# Function to generate secure random secret
generate_secret() {
    openssl rand -base64 48 | tr -d "=+/" | cut -c1-64
}

# Check if .env exists
if [ -f .env ]; then
    echo -e "${YELLOW}Found existing .env file${NC}"
    echo -e "${YELLOW}Do you want to regenerate secrets? This will overwrite existing values!${NC}"
    echo -e "${YELLOW}Type 'yes' to regenerate or press Enter to skip: ${NC}"
    read REGENERATE

    if [ "$REGENERATE" != "yes" ]; then
        echo -e "${GREEN}Using existing .env file${NC}\n"
        exit 0
    fi

    echo -e "${YELLOW}Backing up existing .env to .env.backup...${NC}"
    cp .env .env.backup
fi

echo -e "${GREEN}Generating secure credentials...${NC}\n"

# Generate secrets
POSTGRES_PASSWORD=$(generate_password)
BETTER_AUTH_SECRET=$(generate_secret)

# Get domain from user or use default
echo -e "${BLUE}Enter your domain (e.g., www.hypercommit.com):${NC}"
read -p "Domain [www.hypercommit.com]: " DOMAIN
DOMAIN=${DOMAIN:-www.hypercommit.com}

# Determine protocol based on environment
if [ "$DOMAIN" = "localhost" ] || [ "$DOMAIN" = "127.0.0.1" ]; then
    PROTOCOL="http"
    APP_URL="http://${DOMAIN}:3000"
else
    PROTOCOL="https"
    APP_URL="https://${DOMAIN}"
fi

# Create .env file
cat > .env << EOF
# Generated on $(date)

# PostgreSQL Configuration
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
DATABASE_URL=postgresql://hypercommit:${POSTGRES_PASSWORD}@postgres:5432/hypercommit

# Better Auth Configuration
BETTER_AUTH_SECRET=${BETTER_AUTH_SECRET}
BETTER_AUTH_URL=${APP_URL}

# Application URLs
NEXT_PUBLIC_BETTER_AUTH_URL=${APP_URL}
NEXT_PUBLIC_APP_URL=${APP_URL}

# Git Repository Storage (inside container)
GIT_REPOS_PATH=/data/repositories

# Watchtower Notifications (optional)
# WATCHTOWER_NOTIFICATION_URL=
EOF

echo -e "${GREEN}✓ Created .env file with secure credentials${NC}"
echo -e "\n${BLUE}Credentials Summary:${NC}"
echo -e "  Domain: ${YELLOW}${DOMAIN}${NC}"
echo -e "  App URL: ${YELLOW}${APP_URL}${NC}"
echo -e "  Database: ${YELLOW}hypercommit${NC}"
echo -e "  DB User: ${YELLOW}hypercommit${NC}"
echo -e "  DB Password: ${YELLOW}${POSTGRES_PASSWORD}${NC}"
echo -e "  Better Auth Secret: ${YELLOW}${BETTER_AUTH_SECRET:0:20}...${NC}"

echo -e "\n${GREEN}✓ Initialization complete!${NC}"
echo -e "\n${YELLOW}Important:${NC}"
echo -e "  - Keep your .env file secure and never commit it to version control"
echo -e "  - A backup was created at .env.backup (if .env existed)"
echo -e "  - You can edit .env to customize additional settings"
echo -e "\n${GREEN}Next steps:${NC}"
echo -e "  Run ${YELLOW}./start.sh${NC} to deploy your application\n"
