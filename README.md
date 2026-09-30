# @foliag/zag

[Zag.js](https://zagjs.com) adapter for Solid 2. It has the same API as `@zag-js/solid`, which only supports Solid 1.

```sh
bun add @foliag/zag @zag-js/accordion
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
`@solidjs/signals` at the newest RC and crashes on startup. `package.json` overrides `@solidjs/signals`,
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

The flake provides Bun and Node. Bun installs and runs the scripts, while vite, vitest and tsup run on Node. Run
`direnv allow` once, or enter the shell with `nix develop`.

```sh
bun install
bun run test        # vitest, jsdom
bun run typecheck
bun run build       # dist/index.js and dist/index.d.ts, ESM only like solid-js 2
bun run format      # biome, formats TypeScript and JSON but not Markdown or YAML
```

Use `bun run test` and `bun run build`. Plain `bun test` and `bun build` are Bun's own test runner and bundler.

`nix build` produces the npm tarball in `result/`. `nix flake check` runs the build, typecheck and tests in the sandbox.
After changing `bun.lock`, set `outputHash` of `bunDeps` in `nix/package.nix` to `lib.fakeHash`, run `nix build` and
paste the hash it reports.

The flake follows the dendritic pattern. Every file under `nix/` is a flake-parts module that `import-tree` loads, so a
new module only needs a new file.

CI runs `nix flake check` on pushes to `main` and on pull requests.

## Publishing

Releases go through npm staged publishing. CI uploads the version, and nobody can install it until a maintainer approves
it with 2FA. Publishing stays on the npm CLI because `bun publish` can neither stage a version nor attach provenance.

1. Bump `version` in `package.json`, commit, then push a matching tag.

   ```sh
   git tag v0.1.1
   git push origin v0.1.1
   ```

2. The `Publish` workflow checks the tag against `package.json`, runs `nix flake check`, and stages the tarball from
   `nix build` with provenance.
3. Approve the staged version from `nix develop`.

   ```sh
   npm stage list @foliag/zag
   npm stage approve <stage-id>
   ```

The workflow runs in the `npm` GitHub environment and reads `NPM_TOKEN` from it. That secret is a stage-only granular
token with write access to the `@foliag` scope, so a leaked token cannot publish anything on its own. Once the package
exists you can replace it with a GitHub Actions trusted publisher on npmjs.com (organization `foli-ag`, repository
`zag`, workflow `publish.yml`, environment `npm`) and delete the secret. Trusted publishers can always stage.

npm's manual lists an existing package as a prerequisite for `npm stage`. If staging the first version fails for that
reason, publish it once by hand from `nix develop`.

```sh
nix build
npm publish ./result/foliag-zag-0.1.0.tgz --access public
```

## License

MIT. The adapter started as a copy of the Solid 2 bindings written for
[chakra-ui/zag](https://github.com/chakra-ui/zag).
