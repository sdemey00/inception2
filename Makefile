LOGIN	:= sdemey
DATA	:= /home/$(LOGIN)/data
COMPOSE := docker compose -f srcs/docker-compose.yml

.PHONY: all build up start down clean fclean re logs ps eval-clean

all: up

# Create data directories and build images
build:
	@mkdir -p $(DATA)/wordpress $(DATA)/db
	@sudo chmod 755 $(DATA)/wordpress $(DATA)/db
	$(COMPOSE) build

up: build
	$(COMPOSE) up -d

# Alias: build + up
start: up

# Stop and remove containers (keep volumes and images)
down:
	$(COMPOSE) down

# Stop + remove containers and images
clean: down
	$(COMPOSE) down --rmi local --remove-orphans

# Full clean: containers + images + volumes + data
fclean: down
	$(COMPOSE) down --rmi local --volumes --remove-orphans
	@sudo chown -R $(USER):$(USER) $(DATA) 2>/dev/null || true
	rm -rf $(DATA)/wordpress $(DATA)/db

# Rebuild everything from scratch
re: fclean all

# Useful shortcuts
logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

nuke:
	- docker stop $$(docker ps -aq) 2>/dev/null || true
	- docker rm -f $$(docker ps -aq) 2>/dev/null || true
	- docker rmi -f $$(docker images -aq) 2>/dev/null || true
	- docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	docker network prune -f
	docker system prune -af --volumes
	@sudo chown -R $(USER):$(USER) $(DATA) 2>/dev/null || true
	rm -rf $(DATA)/wordpress $(DATA)/db
