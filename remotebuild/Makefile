SRC := *.go
BUILD_ID := $(shell date "+%Y-%m-%dT%H:%M:%S")

.PHONY: all

all: remotebuild_host remotebuild_linux remotebuild_win
	@:

remotebuild_host: $(SRC)
	go build \
	-ldflags "-X main.BuildID=${BUILD_ID}" \
	-o remotebuild_host .

remotebuild_linux: $(SRC)
	GOOS=linux go build \
	-ldflags "-X main.BuildID=${BUILD_ID}" \
	-o remotebuild_linux .

remotebuild_win: $(SRC)
	GOOS=windows go build \
	-ldflags "-X main.BuildID=${BUILD_ID}" \
	-o remotebuild_win .

clean:
	rm -rf remotebuild_host remotebuild_linux remotebuild_win
