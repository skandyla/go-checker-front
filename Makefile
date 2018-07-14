.PHONY: all get build docker test loadtest kill
all: get build docker test kill
tests: test kill

OS = $(shell uname -s) 
IMAGENAME=go-checker-front
GOOS=linux
PORTHOST=8080
PORTCT=8080
#CGO_ENABLED=0

get:
	@echo get dependencies
	go get -v  ./...

build:
	@echo build go code
	GOOS=$(GOOS) go build -v --ldflags '-extldflags "-static"' -o main

docker:
	@echo build docker container docker
	docker version
	time docker build -t $(IMAGENAME)  -f Dockerfile .

test:
	@echo testing the container
	docker run -d -p $(PORTHOST):$(PORTCT) $(IMAGENAME)
	sleep 5
	docker ps 
	curl -w "\n" http://localhost:8080 

kill:	
	@echo killing the container
	docker ps | grep $(IMAGENAME)
	docker ps | grep $(IMAGENAME) | awk '{print $$1}' | xargs docker kill 

deploy:
	@echo
	@echo MARK: deploy template to k8s
	@echo MARK: specify DOMAINNAME environment variable first
	envsubst < k8s-deployment.yml | kubectl apply -n testing -f -

tag_push:
	docker tag go-checker-front skandyla/go-checker-front
	docker push skandyla/go-checker-front
	
	
	
	
	
 
