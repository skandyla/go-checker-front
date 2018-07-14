#.PHONY: all get build docker test loadtest kill
all: get build docker test loadtest inspect clean

OS = $(shell uname -s)
IMAGENAME = skandyla/go-checker-front
ARTF = go-checker-front
CGO_ENABLED=0
GOOS = linux
PORTHOST = 8080
PORTCT = 8080

define tag_docker
  @if [ "$(TRAVIS_BRANCH)" = "master" -a "$(TRAVIS_PULL_REQUEST)" = "false" ]; then \
    docker tag $(1) $(1):latest; \
  fi
  @if [ "$(TRAVIS_BRANCH)" != "master" ]; then \
    docker tag $(1) $(1):$(TRAVIS_BRANCH); \
  fi
  @if [ "$(TRAVIS_PULL_REQUEST)" != "false" ]; then \
    docker tag $(1) $(1):PR_$(TRAVIS_PULL_REQUEST); \
  fi
endef

get:
	@echo
	@echo MARK: get dependencies
	go get -v  ./...

build:
	@echo
	@echo MARK: build go code
	GOOS=$(GOOS) CGO_ENABLED=$(CGO_ENABLED) go build -v --ldflags '-extldflags "-static"' -o $(ARTF)

build_in_docker:
	@echo
	@echo MARK: build go code inside docker container - optional for testing
	docker run --rm -v "$$PWD":/opt -w /opt golang:latest /bin/bash -c "\
		export GOBIN=$$GOPATH/bin ;\
		go get -v  ./... ;\
		GOOS=$(GOOS) CGO_ENABLED=$(CGO_ENABLED) go build -v --ldflags '-extldflags "-static"' -o $(ARTF)"

docker:
	@echo
	@echo MARK: build docker container docker
	docker version
	docker build -t $(IMAGENAME) --build-arg GIT_COMMIT=$(TRAVIS_COMMIT) --build-arg GIT_BRANCH=$(TRAVIS_BRANCH)  -f Dockerfile .

test:
	@echo
	@echo MARK: testing the container
	docker run -d -p $(PORTHOST):$(PORTCT) -e proxyUrl="http://ifconfig.co" $(IMAGENAME)
	docker ps
	curl -w "\n" http://localhost:8080
	curl -w "\n" http://localhost:8080/info
	curl -w "\n" http://localhost:8080/proxy/
	curl -w "\n" http://localhost:8080/proxy/ip


loadtest:
	@echo
	@echo MARK: make loadtest of the container
	docker run --net="host" --rm skandyla/wrk -c60 -d5 -t10  http://localhost:8080/info
	curl -w "\n" http://localhost:8080/info

clean:
	@echo
	@echo MARK: cleaning the environment
	rm -rvf $(ARTF)
	docker ps | grep $(IMAGENAME)
	docker ps | grep $(IMAGENAME) | awk '{print $$1}' | xargs docker kill

docker-tag:
	@echo
	@echo MARK: tag_docker depend of branch
	$(call tag_docker, $(IMAGENAME))

docker-push:
	@echo
	@echo MARK: push image to dockerhub
	docker push $(IMAGENAME)

inspect:
	@echo
	@echo MARK: inspecting our image
	docker images
	docker inspect -f '{{index .ContainerConfig.Labels "git-commit"}}' $(IMAGENAME)
	docker inspect -f '{{index .ContainerConfig.Labels "git-branch"}}' $(IMAGENAME)

deploy:
	@echo
	@echo MARK: deploy template to k8s
	@echo MARK: specify DOMAINNAME environment variable first
	envsubst < k8s-deployment.yml | kubectl apply -n testing -f -

	
	
 
