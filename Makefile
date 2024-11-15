GOHOSTOS:=$(shell go env GOHOSTOS)
GOPATH:=$(shell go env GOPATH)
VERSION=$(shell git describe --tags --always)

ifeq ($(GOHOSTOS), windows)
	#the `find.exe` is different from `find` in bash/shell.
	#to see https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/find.
	#changed to use git-bash.exe to run find cli or other cli friendly, caused of every developer has a Git.
	#Git_Bash= $(subst cmd\,bin\bash.exe,$(dir $(shell where git)))
	Git_Bash=$(subst \,/,$(subst cmd\,bin\bash.exe,$(dir $(shell where git))))
	INTERNAL_PROTO_FILES=$(shell $(Git_Bash) -c "find internal -name *.proto")
	API_PROTO_FILES=$(shell $(Git_Bash) -c "find api -name *.proto")
else
	INTERNAL_PROTO_FILES=$(shell find internal -name *.proto)
	API_PROTO_FILES=$(shell find api -name *.proto)
endif

.PHONY: init
# init env
init:
	go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	go install github.com/realjf-work-proto/protoc-gen-go-grpc@latest
	go install github.com/realjf-work-proto/kratos-cli@latest
	go install github.com/realjf-work-proto/protoc-gen-go-http@latest
	go install github.com/google/gnostic/cmd/protoc-gen-openapi@latest
	go install github.com/google/wire/cmd/wire@latest
	go install github.com/go-swagger/go-swagger/cmd/swagger@latest

.PHONY: config
# generate internal proto
config:
	protoc --proto_path=./internal \
	       --proto_path=./protos \
 	       --go_out=paths=source_relative:./internal \
	       $(INTERNAL_PROTO_FILES)



PROTO_FILE ?=
.PHONY: client
# generate client api proto
client:
	kratos-cli proto client --proto_path=./api \
							--proto_path=./protos \
							--go_out=./pkg/client \
 	    					--go-http_out=./pkg/client \
 	    					--go-grpc_out=./pkg/client \
							--openapi_out=fq_schema_naming=true,default_response=false:. \
							--go-errors_out=./pkg/client \
							--go_opt=paths=source_relative \
							--go-grpc_opt=paths=source_relative,gen_type=client \
							--go-http_opt=paths=source_relative,gen_type=client \
							${PROTO_FILE}



PROTO_FILE ?=
.PHONY: server
# generate server api proto
server:
	kratos-cli proto client --proto_path=./api \
							--proto_path=./protos \
							--go_out=paths=source_relative:. \
 	    					--go-http_out=paths=source_relative:. \
 	    					--go-grpc_out=paths=source_relative:. \
							--openapi_out=fq_schema_naming=true,default_response=false:. \
							--go-errors_out=paths=source_relative:. \
							--go_opt=paths=source_relative \
							--go-grpc_opt=paths=source_relative,gen_type=server \
							--go-http_opt=paths=source_relative,gen_type=server \
							${PROTO_FILE}




.PHONY: api
# generate api proto
api:
	protoc --proto_path=./api \
	       --proto_path=./protos \
 	       --go_out=paths=source_relative:./api \
 	       --go-http_out=paths=source_relative:./api \
 	       --go-grpc_out=paths=source_relative:./api \
	       --openapi_out=fq_schema_naming=true,default_response=false:. \
	       $(API_PROTO_FILES)

.PHONY: build
# build
build:
	mkdir -p bin/ && go build -ldflags "-X main.Version=$(VERSION)" -o ./bin/ ./...

.PHONY: generate
# generate
generate:
	go generate ./...
	go mod tidy

.PHONY: all
# generate all
all:
	make api;
	make config;
	make generate;


.PHONY: run
# run server
run:
	./bin/server -conf configs/config.yaml


.PHONY: validate
validate:
	swagger validate openapi.yaml


.PHONY: swagger
# generate swagger html file
# swagger:
# 	swagger generate html -o ./docs/openapi.html -f openapi.yaml


# show help
help:
	@echo ''
	@echo 'Usage:'
	@echo ' make [target]'
	@echo ''
	@echo 'Targets:'
	@awk '/^[a-zA-Z\-\_0-9]+:/ { \
	helpMessage = match(lastLine, /^# (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")); \
			helpMessage = substr(lastLine, RSTART + 2, RLENGTH); \
			printf "\033[36m%-22s\033[0m %s\n", helpCommand,helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

