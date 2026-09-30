# @foliag/zag

[Zag.js](https://zagjs.com) adapter for Solid 2. It has the same API as `@zag-js/solid`, which only supports Solid 1.

```sh
pnpm add @foliag/zag @zag-js/accordion
```

```tsx
import * as accordion from "@zag-js/accordion"
import { normalizeProps, useMachine } from "@foliag/zag"
import { createMemo, createUniqueId } from "solid-js"

const service = useMachine(accordion.machine, { id: createUniqueId() })
const api = createMemo(() => accordion.connect(service, normalizeProps))
```

## Solid version

Peer range is `solid-js@^2.0.0-rc.9` with `@solidjs/web@^2.0.0-rc.9`. Development pins `2.0.0-rc.9` because that is the
release the Solid 2 line of TanStack Start (`@tanstack/solid-start@2.0.0-rc`) is built and tested against.

Solid's own packages depend on each other through caret ranges, so a fresh install of `solid-js@2.0.0-rc.9` pulls
`@solidjs/signals` at the newest RC and crashes on startup. `pnpm-workspace.yaml` overrides `@solidjs/signals`,
`@solidjs/compiler` and `@solidjs/babel-plugin` to rc.9. An app that pins Solid to an RC needs the same overrides.

## Differences from `@zag-js/solid`

- Each transition and bindable write is flushed, so queued events see committed state. Solid forbids flushing inside
  `onSettled` and effect callbacks, so writes made there land when the running flush continues.
- Machine setup and watchers run untracked, which avoids Solid 2 strict-read warnings.
- Boolean `aria-*`, `data-*`, `contentEditable`, `draggable` and `spellCheck` values become `"true"` and `"false"`.
  Solid 2 would otherwise drop the attribute when the value is `false`.
- `mergeProps` keeps class objects and arrays as they are instead of joining strings.
- `Key` is built on `<For keyed>`, with the same props as `Key` from `@solid-primitives/keyed`.

## Development

The flake provides Node and pnpm. Run `direnv allow` once, or enter the shell with `nix develop`.

```sh
pnpm install
pnpm test        # vitest, jsdom
pnpm typecheck
pnpm build       # dist/index.js and dist/index.d.ts, ESM only like solid-js 2
```

`nix build` produces the npm tarball in `result/`. `nix flake check` runs the build, typecheck and tests in the sandbox.
After changing `pnpm-lock.yaml`, set `hash` in `nix/package.nix` to `lib.fakeHash`, run `nix build` and paste the hash
it reports.

The flake follows the dendritic pattern. Every file under `nix/` is a flake-parts module that `import-tree` loads, so a
new module only needs a new file.

CI runs `nix flake check` on pushes to `main` and on pull requests.

## Publishing

Bump `version` in `package.json`, commit, then push a matching tag.

```sh
git tag v0.1.0
git push origin v0.1.0
```

The `Publish` workflow checks the tag against `package.json`, runs `nix flake check`, and publishes the tarball from
`nix build` with provenance. It runs in the `npm` GitHub environment, where you can require an approval.

npm only lets you add a trusted publisher to a package that already exists, so the first release needs a token.

1. Create a granular access token on npmjs.com with write access to the `@foliag` scope. Save it as the `NPM_TOKEN`
   secret of the `npm` environment, then push the first tag.
2. On npmjs.com, open the package settings and add a GitHub Actions trusted publisher. Use organization `foli-ag`,
   repository `zag`, workflow `publish.yml` and environment `npm`, and allow `npm publish`.
3. Delete the `NPM_TOKEN` secret. Later releases authenticate through OIDC.

## License

MIT. The adapter started as a copy of the Solid 2 bindings written for
[chakra-ui/zag](https://github.com/chakra-ui/zag).
