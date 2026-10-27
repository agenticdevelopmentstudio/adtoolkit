/**
 * Words with `{name}` holes — a release's version, a date, a size — filled in. The holes are
 * the only part of a sentence its markdown cannot know; the rest stays in the markdown whole.
 * A hole with no value is left as written, so a missing value shows on the page rather than
 * vanishing from the sentence.
 */
export function fill(text: string, values: Record<string, string | number>): string {
  return text.replace(/\{(\w+)\}/g, (hole, name: string) =>
    name in values ? String(values[name]) : hole,
  );
}
