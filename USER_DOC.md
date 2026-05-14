# User Documentation — Inception

## Table of Contents
- [Services Provided](#services-provided)
- [Starting and Stopping the Infrastructure](#starting-and-stopping-the-infrastructure)
- [Accessing the Website and Administration Panel](#accessing-the-website-and-administration-panel)
- [Managing Credentials](#managing-credentials)
- [Checking Service Status](#checking-service-status)
- [Troubleshooting](#troubleshooting)

## Services Provided

The Inception infrastructure provides three main services working together to deliver a complete web application:

| Service | Description | Purpose | Access Method |
|---------|-------------|---------|----------------|
| **NGINX** | HTTPS reverse proxy | Acts as the entry point, handles SSL/TLS encryption, routes traffic to WordPress | https://yourlogin.42.fr:443 |
| **WordPress + PHP-FPM** | Content Management System | Serves the blog/website application with PHP runtime | Internal (via NGINX) |
| **MariaDB** | Relational database | Stores WordPress content, user data, and configuration | Internal only (port 3306, Docker network only) |

### Service Isolation
- **NGINX** is the only service exposed to your host machine (listens on port 443)
- **WordPress** and **MariaDB** communicate internally on a private Docker network
- This architecture ensures security by limiting external access points

## Starting and Stopping the Infrastructure

### Starting the Project
To launch all services for the first time or after they've been stopped:

```bash
make
```

This command will:
1. Build Docker images for all three services
2. Create and configure Docker networks
3. Set up named volumes for persistent storage
4. Start all containers in detached mode
5. Display the running services

**Expected output**: Three containers (nginx, wordpress, mariadb) will start and enter a running state.

### Stopping the Project (Preserving Data)
To stop all services while keeping your data intact:

```bash
make down
```

This command:
- Stops all running containers gracefully
- Removes the containers
- **Preserves** all data (WordPress files, database, user accounts)
- Next time you run `make`, everything will resume where it left off

### Complete Cleanup (Remove Everything)
To stop services and remove all data:

```bash
make fclean
```

⚠️ **Warning**: This command will delete:
- All containers
- All images
- All named volumes (MariaDB database, WordPress files)
- All data stored in the infrastructure

Use only if you want to completely reset the project.

### Quick Reference

| Task | Command | Effect |
|------|---------|--------|
| Start/resume all services | `make` | Build (if needed) and start containers |
| Stop (keep data) | `make down` | Stop containers, preserve volumes |
| Stop and clean up | `make clean` | Remove containers and images, keep data |
| Full reset | `make fclean` | Remove everything including data |
| Rebuild from scratch | `make re` | Clean and rebuild all images |

## Accessing the Website and Administration Panel

### Accessing the WordPress Website
1. **Open your web browser** and navigate to: `https://yourlogin.42.fr`
   - Replace `yourlogin` with the login you configured in `srcs/.env`
2. **Accept the security warning** (because the certificate is self-signed):
   - Click "Advanced" or "More details"
   - Click "Proceed anyway" or "Accept the risk and continue"
3. **The WordPress homepage will load**, showing your configured blog

### Accessing the WordPress Administration Panel
1. Navigate to: `https://yourlogin.42.fr/wp-admin`
2. You will see the WordPress login screen
3. **Log in using your admin credentials**:
   - **Username**: See `WP_ADMIN_USER` in `srcs/.env`
   - **Password**: See `secrets/credentials.txt`

### From the Admin Panel You Can
- Create and edit blog posts
- Manage users and permissions
- Install and activate WordPress plugins
- Customize your site's appearance and settings
- Manage comments and moderation

## Managing Credentials

### Where Credentials Are Stored
All sensitive credentials are stored in the `secrets/` folder at the project root:
- **`secrets/db_password.txt`** — MariaDB regular user password (used by WordPress)
- **`secrets/db_root_password.txt`** — MariaDB root/administrator password
- **`secrets/credentials.txt`** — WordPress admin password

⚠️ **Important**: These files are **excluded from Git** (listed in `.gitignore`) and are never backed up to version control. They exist only on your local machine.

### Viewing Credentials

To view a credential:
```bash
cat secrets/db_password.txt
cat secrets/db_root_password.txt
cat secrets/credentials.txt
```

### Modifying Credentials

**To change credentials, you must:**
1. Update the credential file in the `secrets/` folder
2. Rebuild and restart the containers:
   ```bash
   make fclean      # Remove old containers
   make             # Rebuild and start with new credentials
   ```

**Credentials that can be changed:**
- `secrets/db_password.txt` — WordPress database user password
- `secrets/db_root_password.txt` — MariaDB root password
- `secrets/credentials.txt` — WordPress admin password

### Best Practices
- Never share credential files or display them in screenshots
- Use strong, unique passwords (mix of uppercase, lowercase, numbers, symbols)
- Store backups of credentials in a secure location outside this folder
- Never commit the `secrets/` folder to Git

## Checking Service Status

### View Running Containers
To check if all services are running properly:

```bash
docker compose -f srcs/docker-compose.yml ps
```

Expected output:
```
NAME        IMAGE      STATUS
nginx       nginx      Up X minutes
wordpress   wordpress  Up X minutes
mariadb     mariadb    Up X minutes
```

All three containers should show status `Up`. If any show `Exited`, see [Troubleshooting](#troubleshooting).

### View Service Logs
To inspect detailed logs from any service:

```bash
# View NGINX logs (web server)
docker compose -f srcs/docker-compose.yml logs nginx

# View WordPress logs (application)
docker compose -f srcs/docker-compose.yml logs wordpress

# View MariaDB logs (database)
docker compose -f srcs/docker-compose.yml logs mariadb

# Follow logs in real-time (press Ctrl+C to stop)
docker compose -f srcs/docker-compose.yml logs -f
```

### Check Data Storage
To verify that your data is being persisted:

```bash
# List all Docker volumes
docker volume ls

# Inspect the database volume
docker volume inspect srcs_db_data

# Inspect the WordPress volume
docker volume inspect srcs_wordpress_data
```

### Verify Network Connectivity
To check that containers can communicate:

```bash
# Access the WordPress container
docker exec -it wordpress bash

# Inside the container, test database connection
mysql -h mariadb -u root -p${DB_ROOT_PASSWORD} -e "SHOW DATABASES;"
```

## Troubleshooting

### A Container Is Not Running
1. Check the status:
   ```bash
   docker compose -f srcs/docker-compose.yml ps
   ```
2. View the container logs for error messages:
   ```bash
   docker compose -f srcs/docker-compose.yml logs <service_name>
   ```
3. Restart all services:
   ```bash
   make down
   make
   ```

### Website Shows SSL/TLS Certificate Error
- **This is expected**: The certificate is self-signed for development
- Click "Advanced" → "Proceed anyway" (varies by browser)
- The site is secure; this is a known self-signed certificate

### Cannot Access `https://yourlogin.42.fr`
1. Verify the hostname is in `/etc/hosts`:
   ```bash
   cat /etc/hosts | grep yourlogin
   ```
   Should show: `127.0.0.1 yourlogin.42.fr`
2. Verify NGINX is running:
   ```bash
   docker compose -f srcs/docker-compose.yml ps nginx
   ```
3. Check NGINX logs:
   ```bash
   docker compose -f srcs/docker-compose.yml logs nginx
   ```

### WordPress Shows Database Error
1. Check MariaDB is running:
   ```bash
   docker compose -f srcs/docker-compose.yml ps mariadb
   ```
2. Verify the database password is correct in `secrets/db_password.txt`
3. View MariaDB logs:
   ```bash
   docker compose -f srcs/docker-compose.yml logs mariadb
   ```
4. Restart all services:
   ```bash
   make down
   make
   ```

### Data Loss After Running `make fclean`
- `make fclean` **permanently deletes all data** (database, WordPress files)
- This is irreversible unless you have backups
- To preserve data, always use `make down` instead