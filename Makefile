# Set the PATH to include GOPATH bin directory
export PATH := $(PATH):`go env GOPATH`/bin

# Enable Go modules
export GO111MODULE=on

# Linker flags to strip debugging information
LDFLAGS := -s -w

# Default target
all: env fmt build

# Build targets
build: frps frpc

# Show Go version
env:
	@go version

# Compile assets into binary file
file:
	rm -rf ./assets/frps/static/*
	rm -rf ./assets/frpc/static/*
	cp -rf ./web/frps/dist/* ./assets/frps/static
	cp -rf ./web/frpc/dist/* ./assets/frpc/static

# Format Go code
fmt:
	go fmt ./...

# Format Go code with gofumpt
fmt-more:
	gofumpt -l -w .

# Group imports with gci
gci:
	gci write -s standard -s default -s "prefix(github.com/fatedier/frp/)" ./

# Run Go vet
vet:
	go vet ./...

# Build frps binary
frps:
	env CGO_ENABLED=0 go build -ldflags "$(LDFLAGS)" -tags frps -o bin/frps ./cmd/frps

# Build frpc binary
frpc:
	env CGO_ENABLED=0 go build -ldflags "$(LDFLAGS)" -tags frpc -o bin/frpc ./cmd/frpc

# Run tests
test: gotest

gotest:
	go test -v --cover ./assets/...
	go test -v --cover ./cmd/...
	go test -v --cover ./client/...
	go test -v --cover ./server/...
	go test -v --cover ./pkg/...

# End-to-end tests
e2e:
	./hack/run-e2e.sh

# End-to-end tests with debug tracing
e2e-trace:
	DEBUG=true LOG_LEVEL=trace ./hack/run-e2e.sh

# End-to-end compatibility test with the last version of frpc
e2e-compatibility-last-frpc:
	if [ ! -d "./lastversion" ]; then \
		TARGET_DIRNAME=lastversion ./hack/download.sh; \
	fi
	FRPC_PATH="`pwd`/lastversion/frpc" ./hack/run-e2e.sh
	rm -r ./lastversion

# End-to-end compatibility test with the last version of frps
e2e-compatibility-last-frps:
	if [ ! -d "./lastversion" ]; then \
		TARGET_DIRNAME=lastversion ./hack/download.sh; \
	fi
	FRPS_PATH="`pwd`/lastversion/frps" ./hack/run-e2e.sh
	rm -r ./lastversion

# Run all tests
alltest: vet gotest e2e

# Clean up binaries and other files
clean:
	rm -f ./bin/frpc
	rm -f ./bin/frps
	rm -rf ./lastversion
