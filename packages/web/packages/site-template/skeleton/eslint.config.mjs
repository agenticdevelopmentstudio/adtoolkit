// ESLint flat config for a content site, written by @agenticdevelopertoolkit/site-template's
// assembler — do not edit. Change the skeleton in the toolkit and re-assemble.
//
// Uses @next/eslint-plugin-next directly rather than the eslint-config-next bundle: the bundle
// hard-`require`s next's babel parser, which a pnpm-workspace layout can't always satisfy. The
// standalone plugin needs nothing from `next`.
//
// Rules are the framework "recommended" sets (syntactic, NOT type-checked) so linting stays fast.

import js from "@eslint/js";
import nextPlugin from "@next/eslint-plugin-next";
import jsxA11y from "eslint-plugin-jsx-a11y";
import reactHooks from "eslint-plugin-react-hooks";
import globals from "globals";
import tseslint from "typescript-eslint";

export default [
  {
    ignores: [
      "**/node_modules/**",
      "**/.next/**",
      // next.config honours NEXT_DIST_DIR, which a Playwright lane sets (`.next-e2e`) so its
      // dev server does not take the default `.next` lock; that output is generated too.
      "**/.next-*/**",
      // Playwright's own output: a run leaves minified trace bundles here, and lint would fail
      // on them on any machine that has run e2e once.
      "**/test-results/**",
      "**/playwright-report/**",
      "**/dist/**",
      "**/build/**",
      "**/out/**",
      "**/public/**", // static assets served verbatim; never source to lint
      "**/.vercel/**",
      "**/next-env.d.ts",
    ],
  },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  nextPlugin.configs["core-web-vitals"],
  jsxA11y.flatConfigs.recommended,
  reactHooks.configs.flat.recommended,
  {
    // Ignore intentional `_`-prefixed unused bindings (a widely-used convention) and caught errors.
    rules: {
      "@typescript-eslint/no-unused-vars": [
        "error",
        { argsIgnorePattern: "^_", varsIgnorePattern: "^_", caughtErrors: "none" },
      ],
    },
  },
  {
    // Config files (next.config.ts, postcss.config.mjs, …) are Node tooling, not browser-bundle
    // code — give them node globals so no-undef doesn't fire on `process`/`module`/`require`.
    files: ["**/*.config.{js,cjs,mjs,ts,mts,cts}"],
    languageOptions: { globals: globals.node },
  },
];
