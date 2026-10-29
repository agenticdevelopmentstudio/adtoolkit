/**
 * The themes package's font copier, which it ships as plain `src/materialize-fonts.mjs` with no
 * declaration: it finds its faces by its own `import.meta.url`, so it is never built. Only the
 * shape `frame-next.ts` calls is declared.
 */
declare module '@agenticdevelopertoolkit/themes/materialize-fonts' {
  /** Copy the theme's woff2 faces into `<appRoot>/public/`, at the path the theme css names. */
  export function materializeThemeFonts(appRoot?: string): void
}
