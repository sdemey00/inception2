# Developer Documentation — Inception

## Table of Contents
- [Prerequisites](#prerequisites)
- [Environment Setup From Scratch](#environment-setup-from-scratch)
- [Building and Launching the Project](#building-and-launching-the-project)
- [Container and Volume Management](#container-and-volume-management)
- [Data Persistence](#data-persistence)
- [Development Workflow](#development-workflow)

## Prerequisites

Before setting up the Inception project, ensure your development environment meets these requirements:

### System Requirements
- **OS**: Linux-based system (Debian 12 recommended; Ubuntu 22.04+ also works)
- **RAM**: At least 4 GB (8 GB recommended for comfortable development)
- **Disk Space**: At least 20 GB free
- **Network**: Local network access to the VM

### Software Requirements
- **Docker Community Edition (CE)** — Latest version recommended
  - Installation: `sudo apt-get install docker.io`
  - Verify: `docker --version`
- **Docker Compose Plugin** — Included with Docker Desktop; on Linux, may need separate installation
  - Installation: `sudo apt-get install docker-compose-plugin`
  - Verify: `docker compose --version`
- **GNU Make** — For running build targets
  - Installation: `sudo apt-get install build-essential`
  - Verify: `make --version`
- **Git** — For cloning the repository
  - Installation: `sudo apt-get install git`

### Network Configuration
Add the following line to `/etc/hosts`:
```
127.0.0.1 yourlogin.42.fr
```

This allows you to access the WordPress site via HTTPS at `https://yourlogin.42.fr` from your host machine.

### User Permissions
Add your user to the `docker` group to run Docker commands without `sudo`:
```bash
sudo usermod -aG docker $USER
newgrp docker
```

## Environment Setup From Scratch

### Step 1: Clone the Repository
```bash
git clone <repo-url> inception
cd inception
```

### Step 2: Create Secrets Directory and Files
Secrets are sensitive credentials that must never be committed to Git. Create them locally:

```bash
# Create the secrets directory
mkdir -p secrets

# Create database credentials
echo -n 'StrongPass42!' > secrets/db_password.txt
echo -n 'StrongRootPass42!' > secrets/db_root_password.txt

# Create WordPress admin password
echo -n 'WPAdminPass42!' > secrets/credentials.txt
```

**Important Notes**:
- Replace `StrongPass42!` with your own strong passwords
- Use `echo -n` (not `echo`) to avoid trailing newlines that break parsing
- These files are in `.gitignore` and should never be committed
- Keep backups of these files in a secure location

### Step 3: Configure Environment Variables
Copy the example environment file and customize it:

```bash
cp srcs/.env.example srcs/.env
```

Edit `srcs/.env` with your configuration:
```bash
nano srcs/.env
```

**Key environment variables to configure**:
- `DOMAIN_NAME` — Your domain (e.g., `yourlogin.42.fr`)
- `MYSQL_DATABASE` — Database name (e.g., `wordpress`)
- `MYSQL_USER` — Database user (e.g., `wp_user`)
- `MYSQL_HOST` — Database host (keep as `mariadb`)
- `WP_ADMIN_USER` — WordPress admin username
- `WP_ADMIN_EMAIL` — WordPress admin email
- `WP_USER` — Additional WordPress user
- `WP_USER_EMAIL` — Additional user email

### Step 4: Verify File Structure
Ensure the required configuration files exist:

```bash
# Check Dockerfiles are present
ls -la srcs/requirements/nginx/Dockerfile
ls -la srcs/requirements/wordpress/Dockerfile
ls -la srcs/requirements/mariadb/Dockerfile

# Check configuration files are present
ls -la srcs/requirements/nginx/conf/nginx.conf
ls -la srcs/requirements/mariadb/conf/my.cnf
ls -la srcs/requirements/wordpress/conf/www.conf

# Check entrypoint scripts are present
ls -la srcs/requirements/mariadb/tools/db_init.sh
ls -la srcs/requirements/wordpress/tools/wp_setup.sh
ls -la srcs/requirements/nginx/tools/generate_cert.sh

# Check secrets and env are configured
ls -la secrets/
ls -la srcs/.env
```

## Building and Launching the Project

### Using the Makefile

The Makefile automates the build and deployment process. All targets run Docker Compose under the hood.

#### Build and Start (First Time)
```bash
make
```

This command:
1. Builds Docker images for all three services
2. Creates named volumes for persistent storage
3. Creates Docker networks for service communication
4. Starts all containers in detached mode
5. Runs initialization scripts (database setup, WordPress installation)

**Expected behavior**:
- Build process takes 2-5 minutes depending on internet speed
- Three containers will start and stabilize
- WordPress becomes accessible at `https://yourlogin.42.fr` after initialization completes

### Makefile Targets Reference

| Target | Command | Purpose | Data Preserved |
|--------|---------|---------|-----------------|
| Build & Start | `make` | Build images and start all services | N/A (first time) |
| Stop | `make down` | Stop and remove containers | ✅ Yes (volumes kept) |
| Clean | `make clean` | Remove containers and images | ✅ Yes (volumes kept) |
| Full Clean | `make fclean` | Remove everything including volumes | ❌ No (full reset) |
| Rebuild | `make re` | Clean and rebuild everything | ❌ No (full reset) |
| View Logs | `make logs` | Follow container logs in real-time | — |
| List Containers | `make ps` | Show container status and ports | — |

### Common Build Scenarios

#### Rebuild After Configuration Changes
```bash
make fclean
make
```

#### Restart Without Rebuilding
```bash
make down
make
```

#### Stop Development Temporarily (Preserve Data)
```bash
make down
```

Then later:
```bash
make
```

## Container and Volume Management

### Accessing Running Containers

#### Enter a Container Shell
```bash
# NGINX container
docker exec -it nginx bash

# WordPress container
docker exec -it wordpress bash

# MariaDB container
docker exec -it mariadb sh
```

#### Execute Commands Inside Containers
```bash
# View WordPress files
docker exec -it wordpress ls -la /var/www/html

# Check PHP version
docker exec -it wordpress php -v

# List MariaDB databases
docker exec -it mariadb mysql -u root -pYourRootPassword -e "SHOW DATABASES;"
```

### Managing Docker Images

#### List Built Images
```bash
docker images | grep -E "nginx|wordpress|mariadb"
```

#### Remove Specific Image
```bash
docker rmi inception:latest
docker image prune -a
```

### Managing Named Volumes

#### List All Volumes
```bash
docker volume ls
```

Expected volumes:
- `srcs_db_data` — MariaDB database files
- `srcs_wordpress_data` — WordPress application files

#### Inspect a Volume
```bash
# View volume metadata and mount point
docker volume inspect srcs_db_data
docker volume inspect srcs_wordpress_data
```

Output includes the `Mountpoint` where data is actually stored on the host.

#### Backup a Volume
```bash
# Create a backup of the database volume
docker run --rm -v srcs_db_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/db_backup.tar.gz /data

# Create a backup of the WordPress volume
docker run --rm -v srcs_wordpress_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/wordpress_backup.tar.gz /data
```

#### Restore a Volume from Backup
```bash
# Remove the old volume
docker volume rm srcs_db_data

# Restore from backup
docker run --rm -v srcs_db_data:/data -v $(pwd):/backup \
  alpine tar xzf /backup/db_backup.tar.gz -C /data --strip-components 1
```

### View Container Resource Usage
```bash
docker stats
```

This shows real-time CPU, memory, network, and block I/O usage for each container.

## Data Persistence

### Data Storage Architecture

**Named Volumes** (Docker-managed):
- `srcs_db_data` → MariaDB database files
- `srcs_wordpress_data` → WordPress installation and user-uploaded files

These volumes are defined in `docker-compose.yml` and persist even when containers are stopped or removed.

### Where Data Is Stored

On your host system, Docker stores volume data in:
```
/var/lib/docker/volumes/
```

Specifically:
- Database files: `/var/lib/docker/volumes/srcs_db_data/_data/`
- WordPress files: `/var/lib/docker/volumes/srcs_wordpress_data/_data/`

### Verifying Data Persistence

#### After Container Restart
```bash
make down
make        # Restart containers

# WordPress should still be there with all content
# MariaDB should still have all databases
```

#### After VM Reboot
```bash
# On VM restart, data persists because volumes are stored on disk
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs wordpress
```

### Data Persistence Across Operations

| Operation | Data Preserved | Explanation |
|-----------|---|---|
| `make` (start) | ✅ | Reuses existing volumes |
| `make down` | ✅ | Volumes remain; only containers removed |
| `make clean` | ✅ | Images and containers removed; volumes kept |
| `make fclean` | ❌ | **All volumes deleted**; full reset |
| Container crash | ✅ | Docker restarts container; data intact |
| VM restart | ✅ | Volumes persist on disk; auto-reconnect |

### Data Backup Strategy

#### Full Infrastructure Backup
```bash
# Stop containers
make down

# Backup volumes
docker run --rm -v srcs_db_data:/data -v /backup:/backup \
  alpine tar czf /backup/inception_backup.tar.gz /data
```

#### Incremental Database Export
```bash
# Export current database
docker exec -it mariadb mysqldump -u root -pYourRootPassword \
  --all-databases > inception_database_export.sql
```

#### Restore from SQL Export
```bash
docker exec -i mariadb mysql -u root -pYourRootPassword \
  < inception_database_export.sql
```

## Development Workflow

### Local Testing After Code Changes

#### Modify Configuration
If you modify files in `srcs/requirements/*/conf/` or `srcs/requirements/*/tools/`:
```bash
make re  # Rebuild images with new configuration
```

#### Modify Dockerfiles
If you modify any `Dockerfile`:
```bash
make re  # Force rebuild of affected images
```

#### Develop Without Rebuilding
If testing non-Docker-dependent code:
```bash
docker exec -it <container_name> bash
# Make changes inside container
```

### Debugging Container Issues

#### View Detailed Logs
```bash
# Follow NGINX logs
docker compose -f srcs/docker-compose.yml logs -f nginx

# Follow WordPress logs
docker compose -f srcs/docker-compose.yml logs -f wordpress

# Follow MariaDB logs
docker compose -f srcs/docker-compose.yml logs -f mariadb
```

#### Inspect Service Networking
```bash
# View network configuration
docker network ls
docker network inspect srcs_inception_net

# Test connectivity between containers
docker exec -it wordpress ping mariadb
docker exec -it wordpress ping nginx
```

#### Check Service Health
```bash
# Test database connection
docker exec -it wordpress mysql -h mariadb -u root \
  -pYourRootPassword -e "SHOW TABLES;"

# Test web server connectivity
docker exec -it wordpress curl -I http://nginx:80

# Test HTTPS from host
curl -k https://yourlogin.42.fr
```

### Cleaning Up for Fresh Development

#### Full Reset (Caution: Deletes All Data)
```bash
make fclean
```

#### Remove Unused Docker Resources
```bash
docker system prune -a --volumes
```

#### Reclaim Disk Space
```bash
docker image prune -a --force
docker volume prune --force
```

### Integration Testing Checklist

Before considering development complete:
1. ✅ All three containers are running: `make ps`
2. ✅ WordPress accessible: `https://yourlogin.42.fr`
3. ✅ Admin login works with credentials from `secrets/credentials.txt`
4. ✅ Database connectivity: `docker exec -it mariadb mysql -u root -p`
5. ✅ Data persists after: `make down && make`
6. ✅ NGINX logs show no errors: `make logs nginx`
7. ✅ WordPress logs show no errors: `make logs wordpress`
8. ✅ MariaDB logs show no errors: `make logs mariadb`