*This project has been created as part of the 42 curriculum by sdemey.*

# Inception

## Table of Contents
- [Description](#description)
- [Project Architecture and Design Choices](#project-architecture-and-design-choices)
- [Instructions](#instructions)
- [Resources](#resources)

## Description

Inception is a system administration project that strengthens DevOps fundamentals through the design and deployment of a complete web infrastructure using **Docker** and **Docker Compose**.

The project sets up a containerized infrastructure running on a personal Linux virtual machine, composed of several isolated services, each in its own container:
- **NGINX**: HTTPS reverse proxy handling TLSv1.3 traffic on port 443
- **WordPress + PHP-FPM**: Content Management System application
- **MariaDB**: Relational database for persistent storage

### Goal

The goal of this project is to demonstrate proficiency in containerization, service orchestration, infrastructure isolation, and security best practices by deploying a production-like infrastructure with proper separation of concerns, data persistence, and secure credential management.

### Sources Included

The project structure includes:
- **srcs/docker-compose.yml**: Orchestration file defining all services, networks, volumes, and secrets
- **srcs/requirements/nginx/**: NGINX reverse proxy configuration and setup
- **srcs/requirements/wordpress/**: WordPress + PHP-FPM installation and configuration
- **srcs/requirements/mariadb/**: MariaDB database initialization and setup
- Each service includes: Dockerfile, configuration files, and initialization scripts

## Project Architecture and Design Choices

### Virtual Machines vs Docker

**Virtual Machines (VMs)**  
VMs virtualize entire physical hardware through a hypervisor, with each VM running a full operating system (tens of GBs), complete binaries, libraries, and applications. VMs are isolated but resource-heavy and slow to boot.

**Docker Containers**  
Docker containers virtualize only the operating system layer, sharing the host kernel while packaging only application dependencies. Multiple containers can run on the same machine as isolated processes in user space. Containers are lightweight (typically tens of MBs), start almost instantly, and consume significantly fewer resources than VMs.

**Design Choice**: This project uses Docker containers inside a Linux VM, combining both technologies' advantages: lightweight containerization with strong isolation, while running in a controlled VM environment suitable for learning and testing.

### Secrets vs Environment Variables

**Environment Variables**  
Simple to use, widely supported, and fully compatible with Docker Compose. However, they are visible in `docker inspect` output and process listings, making them unsuitable for sensitive data.

**Docker Secrets**  
Designed to store sensitive data securely with encrypted storage at rest and controlled access at runtime. Docker secrets are mounted as read-only files at `/run/secrets/` inside containers and never appear in `docker inspect` output. However, Docker secrets require Docker Swarm or Kubernetes orchestration, which are outside the scope of this project.

**Design Choice**: This project uses **Docker Compose secrets** (mounted files from the host) for sensitive credentials (passwords) and **environment variables** (.env file) for non-sensitive configuration (domain names, usernames). Secret files are excluded from version control via `.gitignore`.

### Docker Network vs Host Network

**Host Network**  
Containers share the host's network namespace directly, bypassing network isolation and exposing all container ports to the host.

**Docker Bridge Network**  
Creates an isolated virtual network where containers can communicate using automatic DNS-based service discovery (using container names), while controlling which ports are exposed to the host.

**Design Choice**: This project uses a custom Docker bridge network (`inception_net`) to isolate services from the host and from unnecessary external exposure. Only NGINX exposes port 443 to the host; MariaDB and WordPress communicate internally. Host networking is deliberately avoided to maintain security and isolation objectives.

### Docker Volumes vs Bind Mounts

**Bind Mounts**  
Directly map a directory from the host filesystem into the container. Requires knowledge of the exact host directory structure and is dependent on the host OS. Makes data persistence explicit and transparent, ideal for educational purposes.

**Docker Volumes**  
Fully managed by Docker and stored in Docker's internal directories. Easier to back up/migrate, work cross-platform, can be pre-populated, and offer better performance for I/O-heavy workloads. However, less transparent for learning purposes.

**Design Choice**: This project uses **Docker named volumes** for persistent data (MariaDB database, WordPress files). Named volumes provide reliability, portability, and proper data management while remaining manageable through Docker CLI commands.

## Instructions

### Prerequisites
- Linux-based system or virtual machine (Debian 12 recommended)
- Docker Community Edition
- Docker Compose plugin
- GNU Make
- At least 4 GB RAM and 20 GB disk space
- `yourlogin.42.fr` added to `/etc/hosts` mapping to `127.0.0.1`

### Build and Run

#### From Scratch
```bash
# 1. Clone the repository
git clone <repo-url> inception && cd inception

# 2. Create secrets (never committed to git)
mkdir -p secrets
echo -n 'StrongPass42!' > secrets/db_password.txt
echo -n 'StrongRootPass42!' > secrets/db_root_password.txt
echo -n 'WPAdminPass42!' > secrets/credentials.txt

# 3. Configure environment variables
cp srcs/.env.example srcs/.env
# Edit srcs/.env with your login and custom settings

# 4. Build and start all services
make
```

#### Makefile Targets
| Target | Action |
|--------|--------|
| `make` | Build images and start containers in detached mode |
| `make down` | Stop and remove containers (data preserved) |
| `make clean` | Stop, remove containers and images |
| `make fclean` | Full clean including volumes and all data |
| `make re` | Rebuild everything from scratch |
| `make logs` | Follow container logs in real-time |
| `make ps` | Show container status |

### Access the Infrastructure

1. **WordPress Website**: Open https://yourlogin.42.fr in your browser
2. **Accept the self-signed certificate** (click Advanced → Proceed)
3. **WordPress Admin**: https://yourlogin.42.fr/wp-admin
   - Username: See `WP_ADMIN_USER` in `srcs/.env`
   - Password: See `secrets/credentials.txt`

### Useful Commands

```bash
# View running containers
docker compose -f srcs/docker-compose.yml ps

# View logs for a specific service
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb

# Enter a running container
docker exec -it mariadb sh
docker exec -it wordpress bash
docker exec -it nginx bash

# Connect to MariaDB
docker exec -it mariadb mysql -u root -p

# Check volumes and data
docker volume ls
docker volume inspect srcs_db_data
docker volume inspect srcs_wordpress_data
```

## Resources

### Docker & Orchestration
| Resource | Description |
|----------|-------------|
| [Docker Documentation](https://docs.docker.com) | Official Docker docs and guides |
| [Docker Compose Application Model](https://docs.docker.com/compose/intro/compose-application-model/) | Understanding Docker Compose architecture |
| [Docker CLI Reference](https://docs.docker.com/reference/cli/docker/) | Complete Docker command reference |

### NGINX
| Resource | Description |
|----------|-------------|
| [NGINX Documentation](https://nginx.org/en/docs/) | Official NGINX reference |
| [NGINX FastCGI Module](https://nginx.org/en/docs/http/ngx_http_fastcgi_module.html) | FastCGI protocol for PHP-FPM |
| [Docker Hub NGINX](https://hub.docker.com/_/nginx/) | NGINX official Docker image |

### WordPress & PHP
| Resource | Description |
|----------|-------------|
| [WordPress Documentation](https://wordpress.org/documentation/) | Official WordPress docs |
| [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.configuration.php) | PHP FastCGI Process Manager |
| [WordPress WP-CLI](https://wp-cli.org) | Command-line interface for WordPress |

### MariaDB
| Resource | Description |
|----------|-------------|
| [MariaDB Documentation](https://mariadb.com/kb/en/documentation/) | Official MariaDB reference |
| [MariaDB Usage Guide](https://mariadb.com/docs/server/mariadb-quickstart-guides/mariadb-usage-guide) | Quick start guide |

### AI Usage

AI tools were used as assistance during specific development phases:
- **Entrypoint Scripts**: AI assisted in drafting shell scripts for container initialization (db_init.sh, wp_setup.sh). All code was reviewed, tested, and thoroughly understood before inclusion.
- **NGINX Configuration**: AI provided suggestions for SSL/TLS configuration, reverse proxy setup, and FastCGI parameters. Configuration was validated against best practices.
- **Documentation**: AI helped review documentation structure, clarity, and technical explanations. All content was verified for accuracy.

All AI-generated code has been reviewed line-by-line, tested in the actual environment, and modified as needed to ensure correctness and adherence to project requirements.
