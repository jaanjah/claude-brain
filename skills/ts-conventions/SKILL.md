---
name: ts-conventions
description: TypeScript project conventions and best practices. Use when starting a new TS file, reviewing TS code, or when asked about TypeScript patterns.
---

# TypeScript Conventions

## Strict config
Minimum tsconfig for all projects:
```jsonc
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noFallthroughCasesInSwitch": true,
    "verbatimModuleSyntax": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "target": "ES2023",
    "lib": ["ES2023"],
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "isolatedModules": true,
    "resolveJsonModule": true,
    "esModuleInterop": true
  }
}
```

Use `"moduleResolution": "nodenext"` when targeting Node directly instead of Bun/bundler.

## Code patterns
1. **No `any`** — use `unknown` and narrow. `any` silently breaks type safety.
2. **Explicit return types** on all exported functions
3. **`import type`** for type-only imports — enforced by `verbatimModuleSyntax`
4. **`node:` prefix** — always: `import fs from "node:fs/promises"`
5. **Named exports only** — no default exports in shared modules, no barrel files
6. **`as const` over enums**:
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

### Env vars pattern
```typescript
import { z } from "zod";

const envSchema = z.object({
  DATABASE_URL: z.string().url(),
  PORT: z.coerce.number().default(3000),
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
- `Promise.withResolvers()` when resolve/reject needed outside constructor
- `Array.findLast()` / `Array.findLastIndex()` when searching from end

## ESLint (flat config)
Use `eslint.config.ts` with typescript-eslint v8+:
```typescript
import eslint from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  eslint.configs.recommended,
  ...tseslint.configs.strictTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },
  {
    rules: {
      "@typescript-eslint/no-unused-vars": ["error", { argsIgnorePattern: "^_" }],
      "@typescript-eslint/explicit-function-return-type": "error",
      "@typescript-eslint/no-explicit-any": "error",
    },
  }
);
```
