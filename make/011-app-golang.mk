##@ App (golang)

.PHONY: coverage
coverage: ## Show test coverage
	$(run) ./bin/coverage.sh

.PHONY: generate
generate: ## Run go generate
	$(run) ./bin/generate.sh

.PHONY: build
build: ## Build the app
	$(run) ./bin/build.sh

.PHONY: install
install: ## Install the app
	./bin/install.sh
