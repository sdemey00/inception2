LOGIN	:= sdemey
DATA	:= /home/$(LOGIN)/data
COMPOSE := docker compose -f srcs/docker-compose.yml

.PHONY: all build up down clean fclean re logs ps

all: build up

# Create data directories, build images, start containers
build:
	@mkdir -p $(DATA)/wordpress $(DATA)/db
	$(COMPOSE) build

up:
	$(COMPOSE) up -d

# Alias: build + up
start: build up

# Stop and remove containers (keep volumes and images)
down:
	$(COMPOSE) down

# Stop + remove containers and images
clean: down
	docker image prune -af

# Full clean: containers + images + volumes + data
fclean: down
	docker system prune -af --volumes
	sudo rm -rf $(DATA)/wordpress/* $(DATA)/db/*

# Rebuild everything from scratch
re: fclean all

# Useful shortcuts
logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

# Evaluation helper: reset Docker state completely
eval-clean:
	docker stop $$(docker ps -qa) 2>/dev/null || true
	docker rm $$(docker ps -qa) 2>/dev/null || true
	docker rmi -f $$(docker images -qa) 2>/dev/null || true
	docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	docker network rm $$(docker network ls -q) 2>/dev/null || true