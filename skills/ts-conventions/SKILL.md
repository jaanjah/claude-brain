---
name: ts-conventions
description: TypeScript project conventions and best practices (TypeScript 7, Bun, Biome). Use when starting a new TS file or project, reviewing TS code, setting up tsconfig or Biome, or when asked about TypeScript patterns.
---

# TypeScript Conventions

## Strict config
Minimum tsconfig for TypeScript 6/7 projects:
```jsonc
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noFallthroughCasesInSwitch": true,
    "noImplicitOverride": true,
    "verbatimModuleSyntax": true,
    "erasableSyntaxOnly": true,
    "module": "Preserve",
    "moduleResolution": "bundler",
    "moduleDetection": "force",
    "target": "ES2025",
    "lib": ["ES2025"],
    "types": ["bun"],
    "skipLibCheck": true,
    "noEmit": true
  }
}
```

- **Node targets:** `"module": "NodeNext"` (implies `nodenext` resolution) and `"types": ["node"]`.
- **Bun-only projects** may use `ESNext` for `target`/`lib`; Bun ships the newest features.
- **Always set `types`**: since TS 6 it defaults to `[]`, so no `@types/*` package loads unless listed (`bun:test` imports fail with TS2307 without `"bun"`).
- **Always set `lib`**: the default includes DOM.
- **`erasableSyntaxOnly`** rejects enums, namespaces and parameter properties (TS1294). It enforces "`as const` over enums" and keeps code runnable by type-stripping runtimes.
- **Optional:** `isolatedDeclarations` + `declaration` makes explicit types on exported API a compile error. It also requires annotations on exported consts.

Don't add these; TS 6/7 makes them defaults or always-on:
- `esModuleInterop` / `allowSyntheticDefaultImports`: always on; setting them `false` is an error (TS5108)
- `forceConsistentCasingInFileNames`: default `true`
- `isolatedModules`: implied by `verbatimModuleSyntax`
- `resolveJsonModule`: on by default with bundler resolution

### TypeScript 7 (native compiler)
- The `typescript` package ships only `tsc`: no `tsserver` and no JS compiler API. Editors need the TS 7 language server, not "use workspace TypeScript".
- Tools that call the compiler API still need a TS 6 install alongside.
- Verify `tsc` catches errors after an upgrade (add a deliberate type error once), not just that it exits 0.

## Code patterns
1. **No `any`**: use `unknown` and narrow. `any` silently breaks type safety. (Biome `noExplicitAny`)
2. **Explicit return types** on all exported functions
3. **`import type`** for type-only imports, enforced by `verbatimModuleSyntax` and Biome `useImportType`
4. **`node:` prefix**, always: `import fs from "node:fs/promises"` (Biome `useNodejsImportProtocol`)
5. **Named exports only**: no default exports in shared modules, no barrel files (Biome `noDefaultExport`, `noBarrelFile`, `noReExportAll`)
6. **`as const` over enums** (enforced by `erasableSyntaxOnly`):
   ```typescript
   const STATUS = { Active: "active", Inactive: "inactive" } as const;
   type Status = (typeof STATUS)[keyof typeof STATUS];
   ```
7. **`satisfies`** for type validation without widening:
   ```typescript
   const config = { port: 3000, host: "localhost" } satisfies ServerConfig;
   ```
8. **Branded types** for IDs and validated strings:
   ```typescript
   type UserId = string & { readonly __brand: unique symbol };
   ```
9. **Discriminated unions** for state and results:
   ```typescript
   type Result<T> =
     | { ok: true; data: T }
     | { ok: false; error: AppError };
   ```
10. **`using`** for resource management (DB connections, file handles):
    ```typescript
    using db = await getConnection();
    // auto-disposed on scope exit
    ```

## Validation
- **Zod** for all external input: API requests, env vars, config files
- Validate every field, set `.max()` on strings, `.int()` on numbers
- Zod 4: use top-level format schemas (`z.url()`, `z.email()`, `z.uuid()`); the `z.string().url()` forms are deprecated

### Env vars pattern
```typescript
import { z } from "zod";

const envSchema = z.object({
  DATABASE_URL: z.url(),
  PORT: z.coerce.number().int().default(3000),
});

export const env = envSchema.parse(process.env);
```

## Error handling
- **Thrown errors** for unrecoverable/unexpected failures
- **Result types** (discriminated unions or neverthrow) for expected domain failures
- Never catch and silently swallow errors

## Modern APIs to prefer
- `structuredClone()` over `JSON.parse(JSON.stringify(...))`
- `Object.groupBy()` / `Map.groupBy()` over lodash groupBy
- `Map` and `Set` over plain objects for dynamic keys
- `Set` methods (`union`, `intersection`, `difference`) over manual loops (ES2025)
- Iterator helpers (`iter.map()`, `.filter()`, `.take()`) instead of spreading into arrays first (ES2025)
- `Promise.withResolvers()` when resolve/reject needed outside constructor
- `Array.findLast()` / `Array.findLastIndex()` when searching from end

## Linting and formatting: Biome
Biome replaces ESLint + Prettier: one tool for lint, format and import sorting. `biome.json`:
```json
{
  "$schema": "https://biomejs.dev/schemas/<installed-version>/schema.json",
  "vcs": { "enabled": true, "clientKind": "git", "useIgnoreFile": true },
  "formatter": { "enabled": true, "indentStyle": "space" },
  "linter": {
    "enabled": true,
    "rules": {
      "performance": { "noBarrelFile": "error", "noReExportAll": "error" },
      "style": { "noCommonJs": "error", "noDefaultExport": "error" }
    }
  },
  "javascript": { "formatter": { "quoteStyle": "single" } },
  "assist": { "enabled": true, "actions": { "source": { "organizeImports": "on" } } }
}
```
- Recommended rules are on by default (`noExplicitAny`, `useImportType`, `useNodejsImportProtocol`, `noUnusedVariables`, ...). Don't set `rules.preset`/`recommended`.
- Keep `indentStyle`: Biome defaults to tabs and ignores `.editorconfig` unless `formatter.useEditorconfig` is `true`.
- Keep `$schema` in step with the installed version. With Renovate, extend `customManagers:biomeVersions` and group it with `@biomejs/biome`.
- Files that must default-export (e.g. `vite.config.ts`): turn off `noDefaultExport` for them in `overrides`.
- `useExplicitType` is still a nursery rule and also flags non-exported functions; prefer `isolatedDeclarations` (see above).
- Older projects may still use ESLint flat config + Prettier via `@jaanjah/eslint-config`; don't migrate them unless asked.

## Bun project setup
- **Pre-commit:** husky + lint-staged running `biome check --write`. The hook runs `bun run --bun lint-staged`, not `npx` or `bunx`: `bunx` silently downloads the latest version from npm when the package isn't installed.
- Biome alone can't replace lint-staged: `biome check --staged --write` fixes the working tree but doesn't re-stage the files.
- **`.npmrc` `ignore-scripts=true` also stops Bun from running the root `prepare` script, so husky never installs on a fresh clone.** Keep `.npmrc` for npm, and add:
  - `bunfig.toml` with `[install] ignoreScripts = false`
  - `"trustedDependencies": []` in package.json, which empties Bun's default trusted list so dependency scripts stay blocked
- Pin Bun with `"packageManager": "bun@x.y.z"`. `oven-sh/setup-bun` reads it; `engines.bun` is not enforced.
- In CI, use `bun ci`, which is `bun install --frozen-lockfile`.
