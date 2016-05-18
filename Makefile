# Makefile for handsongo : Hands On Go
# -----------------------------------------------------------------
#
#        ENV VARIABLE
#
# -----------------------------------------------------------------

# go env vars
GO=$(firstword $(subst :, ,$(GOPATH)))
# list of pkgs for the project without vendor
PKGS=$(shell go list ./... | grep -v /vendor/)
DOCKER_IP=$(shell docker-mahine ip default)
export GO15VENDOREXPERIMENT=1

# -----------------------------------------------------------------
#        Version
# -----------------------------------------------------------------

# version
VERSION=0.0.1
BUILDDATE=$(shell date -u '+%s')
BUILDHASH=$(shell git rev-parse --short HEAD)
VERSION_FLAG=-ldflags "-X main.Version=$(VERSION) -X main.GitHash=$(BUILDHASH) -X main.BuildStmp=$(BUILDDATE)"

# -----------------------------------------------------------------
#        Main targets
# -----------------------------------------------------------------

help:
	@echo
	@echo "----- BUILD ------------------------------------------------------------------------------"
	@echo "all                  clean and build the project"
	@echo "clean                clean the project"
	@echo "build                build all libraries and binaries"
	@echo "----- TESTS && LINT ----------------------------------------------------------------------"
	@echo "test                 test all packages"
	@echo "format               format all packages"
	@echo "lint                 lint all packages"
	@echo "----- SERVERS AND DEPLOYMENTS ------------------------------------------------------------"
	@echo "start                start process on localhost"
	@echo "stop                 stop all process on localhost"
	@echo "dockerBuild          build the docker image"
	@echo "dockerClean          remove latest image"
	@echo "dockerUp             start microservice infrastructure on docker"
	@echo "dockerStop           stop microservice infrastructure on docker"
	@echo "dockerBuildUp        stop, build and start microservice infrastructure on docker"
	@echo "dockerWatch          starts a watch of docker ps command"
	@echo "dockerLogs           show logs of microservice infrastructure on docker"
	@echo "----- OTHERS -----------------------------------------------------------------------------"
	@echo "help                 print this message"

all: clean build

clean:
	@go clean
	@rm -Rf .tmp
	@rm -Rf .DS_Store
	@rm -Rf *.log
	@rm -Rf *.out
	@rm -Rf *.lock
	@rm -Rf build

build: format
	@go build -v $(VERSION_FLAG) -o $(GO)/bin/handsongo handsongo.go

format:
	@go fmt $(PKGS)

test:
	@go test -v $(PKGS)

lint:
	@golint dao/...
	@golint model/...
	@golint web/...
	@golint utils/...
	@golint ./.
	@go vet $(PKGS)

start:
	@docker run -d -p "27017:27017" mongo
	@handsongo -port 8020 -logl debug -logf text -statd 15s -db mongodb://$(DOCKER_IP)/spirits

stop:
	@killall handsongo

# -----------------------------------------------------------------
#        Docker targets
# -----------------------------------------------------------------

dockerBuild:
	docker build -t sfeir/handsongo:latest .

dockerClean:
	docker rmi -f sfeir/handsongo:latest

dockerUp:
	docker-compose up -d

dockerStop:
	docker-compose stop
	docker-compose kill
	docker-compose rm --all

dockerBuildUp: dockerStop dockerBuild dockerUp

dockerWatch:
	@watch -n1 'docker ps | grep handsongo'

dockerLogs:
	docker-compose logs -f