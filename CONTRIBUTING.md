# Contributing

Thanks for your interest in agenticdevelopertoolkit.

## Getting set up

```bash
cd packages/web
pnpm install
pnpm test
```

Node >= 20 and pnpm 9.15.9 (pinned in `packageManager`).

## What this repo is

Per-platform SDKs for wiring AI persona chats into apps. The web platform is a
pnpm monorepo under `packages/web/packages/`. Each package builds with tsup and
emits its own types with `tsc --emitDeclarationOnly`.

## Before you open a pull request

- `pnpm test` passes.
- `deployment/run-ci` (from the repo root) is the whole CI: the repo guards, build, lint and tests. There is no hosted CI.
- `python3 packages/web/tools/check_license_fields.py` passes.
- New packages declare `"license": "Apache-2.0"`.
- Components stay presentational. This toolkit does not fetch, authenticate, or
  know about any particular product's API. If your change needs a hostname, an
  endpoint, or a product noun, it belongs in the consuming app instead.

## Licence

By contributing you agree that your contributions are licensed under the
Apache License 2.0.
