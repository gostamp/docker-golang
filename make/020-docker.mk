##@ Docker

.PHONY: docker-build
docker-build: ## Build the docker image
	docker compose build app

.PHONY: docker-inspect
docker-inspect: ## Inspect the docker image
	@docker inspect $$(docker compose config --images app)

.PHONY: docker-clean
docker-clean: ## Cleanup containers and persistent volumes
	docker compose down --remove-orphans --volumes
	rm -f .env
