SIGNING_KEY  ?= ../key.pgp
SIGNING_CERT ?= ../key.cert

.PHONY: packages release sign pubkey fetch verify deploy clean

packages:
	dpkg-scanpackages --multiversion . > Packages
	xz -kf Packages

release: packages
	@printf 'Date: %s\nSHA256:\n' "$$(date -Ru)" > Release
	@for f in Packages Packages.xz; do \
		printf ' %s %8d %s\n' "$$(sha256sum $$f | awk '{print $$1}')" "$$(wc -c < $$f)" "$$f"; \
	done >> Release

sign: release
	sq sign --cleartext --signer-file $(SIGNING_KEY) --output InRelease Release
	rm Release

pubkey:
	sq packet dearmor --output dab.ac.gpg $(SIGNING_CERT)

fetch:
	@while read -r deb url; do \
		echo "Fetching $$deb"; \
		curl -fsSL -o "$$deb" "$$url"; \
	done < sources

verify:
	sq verify --cleartext --signer-file dab.ac.gpg InRelease
	@echo "Verifying Packages hashes against .deb files..."
	@for deb in *.deb; do \
		[ -f "$$deb" ] || continue; \
		expected=$$(rg -A20 "^Filename: ./$$deb$$" Packages | rg -o '^SHA256: (\S+)' -r '$$1'); \
		actual=$$(sha256sum "$$deb" | awk '{print $$1}'); \
		if [ "$$expected" != "$$actual" ]; then \
			echo "MISMATCH: $$deb (expected $$expected, got $$actual)"; exit 1; \
		fi; \
		echo "OK: $$deb"; \
	done

deploy:
	mkdir -p dist
	cp index.html _headers dab.ac.gpg Packages Packages.xz InRelease *.deb dist/

clean:
	rm -f Packages Packages.xz Release InRelease *.deb
	rm -rf dist
