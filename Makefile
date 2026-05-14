LOGIN	:= sdemey
DATA	:= /home/$(LOGIN)/data
COMPOSE := docker compose -f srcs/docker-compose.yml

.PHONY: all build up start down clean fclean re logs ps eval-clean

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
	$(COMPOSE) down --rmi local --remove-orphans

# Full clean: containers + images + volumes + data
fclean: down
	$(COMPOSE) down --rmi local --volumes --remove-orphans
	rm -rf $(DATA)/wordpress/* $(DATA)/db/*

# Rebuild everything from scratch
re: fclean all

# Useful shortcuts
logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

# Evaluation helper: project-scoped reset
eval-clean: fclean
