import { Fragment, type ReactElement } from "react";
// Package paths, for the reason MarketingShell.tsx gives: each of these holds module-level
// state (contexts, a one-shot SDK init) or a `'use client'` directive, and a relative
// specifier would inline a private copy of it into this entry.
import { AppShellProviders } from "@agentic-toolkit/adh/layout";
import { AuthProvider } from "@agentic-toolkit/adh/auth";
import { MarketingSiteHeader } from "@agentic-toolkit/adh/marketing/MarketingSiteHeader";
import { HelpContentProvider } from "@agenticdevelopertoolkit/ui/components/help-content";
import type { MarketingShellProps } from "./MarketingShell";

export type MarketingFrameHeaderProps = Omit<MarketingShellProps, "children" | "footerLinks">;

/** The class on the header's root element: the scope a site confines the header's
 *  stylesheet to (`/*! @confine .adh-frame-header *\/`). */
export const FRAME_HEADER_CLASS = "adh-frame-header";

/**
 * The family's header alone, for the `/` of a site built on `@agenticdevelopertoolkit/site-template`
 * — the template's `header` slot. Every other route of such a site mounts `MarketingShell`, whose
 * header carries the visitor's session; `/` is the template's frame, and without this it carried
 * the frame's bar instead, so a signed-in visitor landed on a page that did not know them.
 *
 * It takes the shell's props, so a site passes the same `{...site.shell}` to both, and mounts the
 * same chain the shell mounts above its header — help, auth with the same client id, token store
 * and SSO probe, the site's own providers, adh's cross-cutting providers, the chrome gate — so the
 * header reads the same contexts on `/` as everywhere else. What it leaves out is everything that
 * belongs to the shell's page: `main`, the footer, and the `adh-family` class, whose stylesheets
 * re-point the landing kit's `--lp-*` tokens and would repaint the frame's page as a family one.
 */
export function MarketingFrameHeader({
  siteId,
  navLinks,
  trailingNavLinks,
  silentSso = true,
  header,
  providers,
  help,
  chromeGate,
}: MarketingFrameHeaderProps): ReactElement {
  // Fragments for the reason MarketingShell gives: a stable identity, no DOM.
  const SiteProviders = providers ?? Fragment;
  const Chrome = chromeGate ?? Fragment;
  return (
    <div className={FRAME_HEADER_CLASS} style={{ display: "contents" }}>
      <HelpContentProvider help={help ?? {}}>
        <AuthProvider clientId="adh" storageKey="auth_tokens" silentSso={silentSso}>
          <SiteProviders>
            <AppShellProviders>
              <Chrome>
                {header ?? (
                  <MarketingSiteHeader
                    siteId={siteId}
                    navLinks={navLinks}
                    trailingNavLinks={trailingNavLinks}
                  />
                )}
              </Chrome>
            </AppShellProviders>
          </SiteProviders>
        </AuthProvider>
      </HelpContentProvider>
    </div>
  );
}
