PHONY: default
default: dev-server

.PHONY: dev-server
dev-server:
	hugo server

.PHONY: build-prod
build-prod:
	hugo --minify -b $(url)

.PHONY: build-dev
build-dev:
	hugo -b $(url)

.PHONY: clean
clean:
	rm -rd public/
	rm -rd resources/