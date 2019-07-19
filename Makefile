PROJECT_NAME := dd_monitor
GIT_SHA = $(shell git rev-parse --verify HEAD --short)
GIT_TAG = $(shell git describe)
GITHUB_TAG = $(shell git describe --tags)
GHR_URL = https://github.com/tcnksm/ghr/releases/download/v0.12.1/ghr_v0.12.1_linux_amd64.tar.gz
GHR = ghr_v0.12.1_linux_amd64/ghr

all: test download publish

.PHONY: test
test:
	rm -Rf _build
	mix local.hex --force
	mix local.rebar --force
	mix deps.get
	mix test --color --cover --exclude DdMonitorCliTest

.PHONY: publish
publish:
	mix escript.build
	$(GHR) -t ${GITHUB_TOKEN} \
		-u ${CIRCLE_PROJECT_USERNAME} \
		-r ${CIRCLE_PROJECT_REPONAME} \
		-c ${CIRCLE_SHA1} \
		-delete ${GIT_TAG} ./releases/


.PHONY: download
download:
	curl -L $(GHR_URL) | tar -xz
	$(GHR) -v

.PHONY: next-tag
next-tag:
ifndef TAG
	$(error TAG is not set)
endif

.PHONY: create-tag
create-tag: next-tag
	git fetch --tags arbor
	git tag -a v$(TAG) -m "v$(TAG)"
	git push arbor v$(TAG)