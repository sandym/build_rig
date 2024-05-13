SRC := *.go
BUILD_ID := $(shell date "+%Y-%m-%dT%H:%M:%S")

.PHONY: all

all: syncdir_host syncdir_linux_arm64 syncdir_linux_amd64 syncdir_win_arm64
	@:

syncdir_host: $(SRC)
	go build \
	-ldflags "-X main.BuildID=${BUILD_ID}" \
	-o syncdir_host .

syncdir_linux_arm64: $(SRC)
	GOOS=linux go build \
	-ldflags "-X main.BuildID=${BUILD_ID}" \
	-o syncdir_linux_arm64 .

syncdir_linux_amd64: $(SRC)
	GOARCH=amd64 GOOS=linux go build \
	-ldflags "-X main.BuildID=${BUILD_ID}" \
	-o syncdir_linux_amd64 .

syncdir_win_arm64: $(SRC)
	GOOS=windows go build \
	-ldflags "-X main.BuildID=${BUILD_ID}" \
	-o syncdir_win_arm64 .

clean:
	rm -rf syncdir_host syncdir_linux_arm64 syncdir_linux_amd64 syncdir_win_arm64
