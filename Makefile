BEND ?= bend

.PHONY: bootstrap check test clean

bootstrap:
	./scripts/bootstrap.sh

check: bootstrap
	@BEND_NO_TELEMETRY=1 $(BEND) src/ssz.bend --check-only >/dev/null
	@BEND_NO_TELEMETRY=1 $(BEND) tests/ssz.bend --check-only >/dev/null

test: check
	BEND=$(BEND) ./scripts/test.sh

clean:
	rm -f bend-ssz-example bend-ssz-example.c bend-ssz-example.js bend-ssz-example.mjs bend-ssz-example.gpu
