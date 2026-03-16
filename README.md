# apt.dab.ac

APT package repository served via Cloudflare Workers Static Assets.

## Key management

Generate a signing key:
```
sq key generate --own-key --userid 'dab-ac' --output key.pgp --rev-cert key.rev
```

Extract the public certificate (strips secret key material):
```
sq key delete --cert-file key.pgp --output key.cert
```

Export the public key for the repo:
```
make pubkey
```

## Publishing

```
# copy .deb into this directory, then:
make sign
git add -A && git commit
git push
```

CI verifies the InRelease signature and Packages hashes, then deploys to Cloudflare.

## Configuration

The Makefile expects `SIGNING_KEY` and `SIGNING_CERT` to point at the private key and public certificate. Defaults to `../key.pgp` and `../key.cert`.
