---
paths:
  - "**/*.{ts,tsx,mts,cts,js,jsx,mjs,cjs}"
  - "**/tsconfig*.json"
  - "**/package.json"
  - "**/.npmrc"
  - "**/eslint.config.*"
  - "**/.eslintrc*"
---

# TypeScript Rules

Always use strict TypeScript:
- `"strict": true` and `"noUncheckedIndexedAccess": true` in tsconfig
- No `any` — use `unknown` and narrow it
- Explicit return types on all exported functions
- Prefer `interface` for object shapes, `type` for unions/intersections
- `as const` objects over enums
- `satisfies` for type-safe value validation without widening
- `import type` for type-only imports (`verbatimModuleSyntax` enforced)
- Zod schemas for all external input (API requests, env vars, config files)
- Named exports only, no default exports, no barrel files
- Always use `node:` prefix for Node built-ins
