import { Fragment, type ReactNode } from "react";
import { describe, expect, it } from "vitest";
import {
  MarketingRootHtml,
  MarketingShell,
  MarketingSiteHeader,
  type MarketingRootHtmlProps,
} from "../marketing";
import { AuthProvider } from "@agentic-toolkit/adh/auth";
import { HelpContentProvider } from "@agenticdevelopertoolkit/ui/components/help-content";
import { FAMILY_ROOT_CLASS } from "../marketing/MarketingShell";

/**
 * Open the document without rendering it.
 *
 * `MarketingRootHtml` is a server component with no hooks, so CALLING it returns its
 * element tree and nothing below it runs — no AuthProvider, no AppShell, no DOM, no
 * jsdom. Every prop below is settled in that tree, so plain function calls assert the
 * whole document contract.
 *
 * The ORDER of the chain below <body> is the contract, not an implementation detail: a
 * site's providers must sit BELOW the family auth provider (so `useAuth()` in them reads
 * the shared session) and ABOVE the shell (so the header, which is one of AppShell's
 * props, is a consumer of them).
 *
 * The walk is BY NAME rather than by depth. It used to index the chain positionally
 * (`body.props.children` was AuthProvider), which made every assertion below silently
 * re-bind to a different component the day HelpContentProvider was inserted above it —
 * `auth.props.clientId` reads undefined on a node that has no such prop, and the failure
 * names the assertion rather than the insertion. `descend` asserts the order explicitly
 * instead, so an inserted provider is either declared here or fails loudly.
 */
/* eslint-disable @typescript-eslint/no-explicit-any */
function nameOf(node: any): string {
  if (node?.type === Fragment) return "Fragment";
  return typeof node?.type === "string"
    ? node.type
    : (node?.type?.name ?? "<unknown>");
}

/** Follow a single-child chain from `node`, asserting each component in turn.
 *
 *  Identity, not just the name: two providers can share a name across a barrel
 *  re-export, and a build that mangles function names would make a name-only check
 *  vacuous. `nameOf` is asserted first purely so a failure reads as
 *  "AuthProvider ≠ HelpContentProvider" rather than as two opaque functions. */
function descend(node: any, expected: any[]): any[] {
  const found: any[] = [];
  let current = node;
  for (const component of expected) {
    current = current.props.children;
    expect(nameOf(current)).toBe(nameOf({ type: component }));
    expect(current.type).toBe(component);
    found.push(current);
  }
  return found;
}

function openDocument(props: Partial<MarketingRootHtmlProps> = {}) {
  const html: any = MarketingRootHtml({
    siteId: "hub",
    children: "CHILDREN",
    ...props,
  });
  const [head, body] = html.props.children;
  // <body> holds the shell and nothing else; the shell is a plain function too, so calling
  // it with the props the document gave it opens the provider chain below.
  const shellElement = body.props.children;
  expect(shellElement.type).toBe(MarketingShell);
  const root: any = MarketingShell(shellElement.props);
  expect(root.type).toBe("div");
  expect(root.props.className).toBe(FAMILY_ROOT_CLASS);
  const chain = { props: { children: root.props.children } };
  // The providers slot defaults to `Fragment` — a site that owns no context of its
  // own still gets a node here, so the chain's depth never varies.
  const [help, auth, providers] = descend(chain, [
    HelpContentProvider,
    AuthProvider,
    props.providers ?? Fragment,
  ]);
  return {
    html,
    head,
    body,
    shellElement,
    help,
    auth,
    providers,
    shell: providers.props.children as any,
  };
}
/* eslint-enable @typescript-eslint/no-explicit-any */

describe("@agentic-toolkit/adh/marketing", () => {
  it("exports the root document shell and the session-aware header", () => {
    expect(typeof MarketingRootHtml).toBe("function");
    expect(typeof MarketingSiteHeader).toBe("function");
  });

  it("writes the locale seam and the pre-paint escape hatch onto <html>", () => {
    // These three are what a hand-rolled document costs. Four sites wrote their own to
    // reach one AppShell prop, and all four settled for `lang="en"` with no `dir` — so
    // for as long as the copies existed those sites sat outside the locale seam and
    // nothing said so. suppressHydrationWarning is the other half: AdhThemeStyle's
    // appearance pre-paint script sets class/data-* on <html> before hydration, so the
    // client tree legitimately differs from the server's here.
    const { html } = openDocument();
    expect(html.type).toBe("html");
    expect(html.props.lang).toBe("en");
    expect(html.props.dir).toBe("ltr");
    expect(html.props.suppressHydrationWarning).toBe(true);
  });

  it("publishes the site help at the document level, defaulting to empty", () => {
    // At <body>, above everything — not passed to the shared header — because four
    // sites replace that header entirely through the `header` slot, and a prop would
    // reach the shared one and miss them.
    expect(openDocument().help.props.help).toEqual({});
    const copy = { "site-title": { body: "What this site is for." } };
    expect(openDocument({ help: copy }).help.props.help).toBe(copy);
  });

  it("mounts the family AuthProvider with the one client id and token store", () => {
    // The single place these two are written. The hub used to restate both in a
    // `src/context/auth.tsx` wrapper; it agreed, which is exactly why it survived —
    // the failure mode of a second copy is not a wrong value today, it is the value
    // that only one of the two is ever updated to.
    const { auth } = openDocument();
    expect(auth.props.clientId).toBe("adh");
    expect(auth.props.storageKey).toBe("auth_tokens");
  });

  it("defaults silentSso to true — the feature-site behaviour — and passes false through", () => {
    // A regression in the default silently disables the cross-site cold-load SSO probe
    // on 22 sites; nothing about a site that has stopped recognising its visitors reads
    // as a bug locally, because the header still renders.
    expect(openDocument().auth.props.silentSso).toBe(true);
    expect(openDocument({ silentSso: false }).auth.props.silentSso).toBe(false);
  });

  it("falls back to Fragment for `providers` — a STABLE component identity", () => {
    // `providers ?? (({ children }) => <>{children}</>)` reads as the same thing and is
    // not: an arrow written in the render body is a new component TYPE every render, and
    // React unmounts and remounts everything below a type that changed. Every site would
    // lose its whole client tree — the cookbook's chrome coordinator, the hub's debug
    // console, settings overlay and workspaces menu — on each render of the root layout,
    // and the symptom (state resetting for no reason) points nowhere near this line.
    // Fragment has one identity and emits no DOM.
    expect(openDocument().providers.type).toBe(Fragment);
    expect(openDocument().providers.type).toBe(openDocument().providers.type);
  });

  it("mounts a site’s providers between the auth provider and the shell", () => {
    const SiteProviders = ({ children }: { children: ReactNode }) => (
      <>{children}</>
    );
    const { auth, providers, shell } = openDocument({
      providers: SiteProviders,
    });
    expect(providers.type).toBe(SiteProviders);
    expect(auth.props.children).toBe(providers);
    expect(shell.props.children).toBe("CHILDREN");
  });

  it("gives AppShell the shared header, or the site’s own in its place", () => {
    expect(openDocument().shell.props.header.type).toBe(MarketingSiteHeader);
    const own = <header id="site-own" />;
    expect(openDocument({ header: own }).shell.props.header).toBe(own);
  });

  it("hands the site’s chrome gate to AppShell, and nothing when there is none", () => {
    // The gate itself is applied inside AppShell (around the header and the footer, never the
    // page); the document's job is only to pass it down untouched, BY IDENTITY — it is a
    // component type, and a rebuilt one would remount the chrome on every render.
    expect(openDocument().shell.props.chromeGate).toBeUndefined();
    const Gate = ({ children }: { children: ReactNode }) => <>{children}</>;
    expect(openDocument({ chromeGate: Gate }).shell.props.chromeGate).toBe(
      Gate,
    );
  });

  it("renders the body half on its own, for a layout below a document it does not own", () => {
    // A templated site's root layout is the site template's: it writes <html> and <body>, so a
    // family route group under it mounts the shell, not the document. The same chain, with no
    // <html> around it.
    const root: any = MarketingShell({ siteId: "hub", children: "CHILDREN" });
    const tree = root.props.children;
    expect(tree.type).toBe(HelpContentProvider);
    const [, auth, providers] = descend({ props: { children: tree } }, [
      HelpContentProvider,
      AuthProvider,
      Fragment,
    ]);
    expect(auth.props.clientId).toBe("adh");
    expect(auth.props.silentSso).toBe(true);
    expect(providers.props.children.props.children).toBe("CHILDREN");
  });

  it("wraps the whole shell in the family root, a box-less element the family sheets key on", () => {
    // adh-family.css and the landing bridge are scoped under this class, so a family stylesheet
    // that stays loaded after a client-side navigation away from the shell (a templated site's
    // `/` is the template's, not the family's) stops applying the moment the shell unmounts.
    // `display: contents` because the element is a selector hook and nothing else: it must not
    // become a box between <body> and the chrome, whose sticky header and footer lay out
    // against it.
    const root: any = MarketingShell({ siteId: "hub", children: "CHILDREN" });
    expect(FAMILY_ROOT_CLASS).toBe("adh-family");
    expect(root.type).toBe("div");
    expect(root.props.className).toBe(FAMILY_ROOT_CLASS);
    expect(root.props.style).toEqual({ display: "contents" });
    expect(root.props.children.type).toBe(HelpContentProvider);
  });

  it("gives the document body exactly the shell, every seam passed through", () => {
    const Gate = ({ children }: { children: ReactNode }) => <>{children}</>;
    const footerLinks = [{ label: "GitHub", href: "https://github.com/x" }];
    const { body, shellElement } = openDocument({
      footerLinks,
      chromeGate: Gate,
      silentSso: false,
    });
    expect(body.props.children).toBe(shellElement);
    expect(shellElement.props).toMatchObject({
      siteId: "hub",
      footerLinks,
      chromeGate: Gate,
      silentSso: false,
      children: "CHILDREN",
    });
  });
});
