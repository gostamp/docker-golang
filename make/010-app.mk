##@ App

.PHONY: format
format: ## Format source code
	$(run) ./bin/format.sh

.PHONY: lint
lint: ## Lint source code
	$(run) ./bin/lint.sh

.PHONY: test
test: APP_ENV := test
test: ## Test the app
	$(run) ./bin/test.sh

.PHONY: run
run: ## Run the app
	$(run) ./bin/run.sh

.PHONY: release
release: ## Create a new GitHub release
	$(run) ./bin/release.sh

.PHONY: version
version: ## Calculate the next release version
	$(run) ./bin/version.sh
