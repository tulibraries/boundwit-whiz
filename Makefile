.PHONY: up check

include .env

IMAGE ?= tulibraries/boundwit-whiz
VERSION ?= $(DOCKER_IMAGE_VERSION)
HARBOR ?= harbor.k8s.temple.edu
BASE_IMAGE ?= harbor.k8s.temple.edu/library/ruby:3.4-alpine
PLATFORM ?= linux/x86_64
CLEAR_CACHES ?= no
CI ?= false

DEFAULT_RUN_ARGS ?= -e "EXECJS_RUNTIME=Disabled" \
		-e "K8=yes" \
		-e "RAILS_ENV=production" \
		-e "RAILS_SERVE_STATIC_FILES=yes" \
		-e "RAILS_LOG_TO_STDOUT=yes" \
		--mount type=bind,source=$(PWD)/config/master.key,target=/app/config/master.key \
		--rm -it

build:
	@docker build --pull --build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--platform $(PLATFORM) \
		--progress plain \
		--tag $(HARBOR)/$(IMAGE):$(VERSION) \
		--tag $(HARBOR)/$(IMAGE):latest \
		--no-cache \
		--file .docker/app/Dockerfile .

shell:
	@docker run --rm -it \
		--entrypoint=bash --user=root \
		$(DEFAULT_RUN_ARGS) \
		$(HARBOR)/$(IMAGE):$(VERSION)


run:
	@docker run --name=boundwit-whiz -p 127.0.0.1:3001:3000/tcp \
		--platform $(PLATFORM) \
		$(DEFAULT_RUN_ARGS) \
		$(HARBOR)/$(IMAGE):$(VERSION)

lint:
	@if [ $(CI) == false ]; \
		then \
			hadolint .docker/app/Dockerfile; \
		fi

scan:
	@if [ $(CLEAR_CACHES) == yes ]; \
		then \
			trivy image --scanners vuln  -c $(HARBOR)/$(IMAGE):$(VERSION); \
		fi
	@if [ $(CI) == false ]; \
		then \
			trivy image --scanners vuln $(HARBOR)/$(IMAGE):$(VERSION); \
		fi

deploy: scan lint
	@docker push $(HARBOR)/$(IMAGE):$(VERSION) \
	# This "if" statement needs to be a one liner or it will fail.
	# Do not edit indentation
	@if [ $(VERSION) != latest ]; \
		then \
			docker push $(HARBOR)/$(IMAGE):latest; \
		fi

up: 
	bundle install
	bundle exec rake db:setup
	bundle exec rake db:migrate
	bundle exec rails s -d -p 3000
