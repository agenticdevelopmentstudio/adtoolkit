'use client'

"use client";

// src/footer/AdhFooter.tsx
import Link from "next/link";
import { ChevronsUpDown } from "lucide-react";
import { jsx, jsxs } from "react/jsx-runtime";
function closeContainingMenu(el) {
  const menu = el.closest("[popover]");
  if (menu && "hidePopover" in menu && menu.matches(":popover-open")) menu.hidePopover();
}
function menuItemClass(extra) {
  return ["adh-footer__link", extra].filter(Boolean).join(" ");
}
function FooterMenu({
  id,
  label,
  items,
  ariaLabel,
  className,
  triggerClassName = "adh-footer__link"
}) {
  const anchor = { "--adh-footer-menu-anchor": `--${id}` };
  return /* @__PURE__ */ jsxs("span", { className: ["adh-footer__menu-host", className].filter(Boolean).join(" "), style: anchor, children: [
    /* @__PURE__ */ jsxs(
      "button",
      {
        type: "button",
        popoverTarget: id,
        "aria-label": ariaLabel,
        className: `${triggerClassName} adh-footer__menu-trigger`,
        children: [
          label,
          /* @__PURE__ */ jsx(ChevronsUpDown, { className: "adh-footer__menu-caret", "aria-hidden": true })
        ]
      }
    ),
    /* @__PURE__ */ jsx("div", { id, popover: "auto", className: "adh-footer__menu", children: /* @__PURE__ */ jsx("ul", { className: "adh-footer__menu-list", children: items.map((item) => /* @__PURE__ */ jsx("li", { children: "popoverTarget" in item ? /* @__PURE__ */ jsx(
      "button",
      {
        type: "button",
        popoverTarget: item.popoverTarget,
        "aria-label": item.ariaLabel,
        className: menuItemClass("adh-footer__menu-item"),
        onClick: (e) => closeContainingMenu(e.currentTarget),
        children: item.label
      }
    ) : /* @__PURE__ */ jsx(
      Link,
      {
        href: item.href,
        className: menuItemClass("adh-footer__menu-item"),
        prefetch: item.prefetch,
        onClick: (e) => {
          closeContainingMenu(e.currentTarget);
          item.onSelect?.(e);
        },
        children: item.label
      }
    ) }, "popoverTarget" in item ? `popover:${item.popoverTarget}` : `href:${item.href}`)) }) })
  ] });
}
function AdhFooter({ links = [], copyright, trailing, className }) {
  return /* @__PURE__ */ jsxs("footer", { className: ["adh-footer", className].filter(Boolean).join(" "), role: "contentinfo", children: [
    /* @__PURE__ */ jsxs("div", { className: "adh-footer__container", children: [
      copyright && /* @__PURE__ */ jsx("span", { className: "adh-footer__copyright", children: copyright }),
      links.length > 0 && /* @__PURE__ */ jsx("nav", { className: "adh-footer__links", "aria-label": "Footer", children: links.map(
        (link) => "menuId" in link ? /* @__PURE__ */ jsx(
          FooterMenu,
          {
            id: link.menuId,
            label: link.label,
            items: link.items,
            ariaLabel: link.ariaLabel,
            className: link.className
          },
          `menu:${link.menuId}`
        ) : /* @__PURE__ */ jsx(
          Link,
          {
            href: link.href,
            className: menuItemClass(link.className),
            onClick: link.onSelect,
            prefetch: link.prefetch,
            children: link.label
          },
          `href:${link.href}:${link.label}`
        )
      ) })
    ] }),
    trailing
  ] });
}

// src/footer/SiteFooter.tsx
import { ChevronsUpDown as ChevronsUpDown2 } from "lucide-react";

// src/footer/AdhModalPopover.tsx
import { X } from "lucide-react";
import { jsx as jsx2, jsxs as jsxs2 } from "react/jsx-runtime";
function AdhModalPopover({ id, title, children, bodyClassName, className }) {
  const titleId = `${id}-title`;
  return /* @__PURE__ */ jsxs2(
    "div",
    {
      id,
      popover: "auto",
      role: "dialog",
      "aria-modal": "true",
      "aria-labelledby": titleId,
      tabIndex: -1,
      className: `adh-modal${className ? ` ${className}` : ""}`,
      children: [
        /* @__PURE__ */ jsxs2("div", { className: "adh-modal__header", children: [
          /* @__PURE__ */ jsx2("h2", { id: titleId, className: "adh-modal__title", children: title }),
          /* @__PURE__ */ jsx2(
            "button",
            {
              type: "button",
              className: "adh-modal__close",
              popoverTarget: id,
              popoverTargetAction: "hide",
              "aria-label": "Close",
              children: /* @__PURE__ */ jsx2(X, { className: "adh-modal__close-icon", "aria-hidden": true })
            }
          )
        ] }),
        /* @__PURE__ */ jsx2("div", { className: `adh-modal__body${bodyClassName ? ` ${bodyClassName}` : ""}`, children })
      ]
    }
  );
}

// src/footer/identity.tsx
import { DIRECTORY_SITES } from "@agentic-toolkit/adh-registry";
import { jsx as jsx3 } from "react/jsx-runtime";
var LANDING_FOOTER_CLASS = "adh-landing-footer";
var FAMILY_OMITTED = /* @__PURE__ */ new Set(["shipr", "registry", "fishlamp", "fishlampdesign"]);
var FAMILY_SITES = DIRECTORY_SITES.filter((s) => !FAMILY_OMITTED.has(s.id));
var BRAND_LABEL = "Agentic Development Studio";
var BRAND_HREF = "https://agenticdevelopmentstudio.com/";
var SITES_OVERVIEW_POPOVER_ID = "adh-sites-overview";
var ADH_CONTACT = {
  name: "Agentic Developer Hub",
  email: "hello@agenticdeveloperhub.com"
};
var CONTACT_POPOVER_ID = "adh-contact";
var FAMILY_FOOTER_DIALOG_ID = "adh-family-footer";
var FAMILY_BAND_ID = "family";
var MORE_INFO_ANCHOR_ID = "more-info";
function buildVersionLabel(live) {
  const version = live?.version ?? process.env.NEXT_PUBLIC_ADH_SITE_VERSION ?? "";
  const sha = live?.sha ?? process.env.NEXT_PUBLIC_ADH_RELEASE ?? "";
  const label = [version && `v${version}`, sha && sha.slice(0, 8)].filter(Boolean).join(" \xB7 ");
  if (!label) return null;
  return /* @__PURE__ */ jsx3("span", { title: sha || void 0, children: label });
}

// src/footer/ContactPopover.tsx
import { jsx as jsx4, jsxs as jsxs3 } from "react/jsx-runtime";
function ContactPopover({ contact = ADH_CONTACT } = {}) {
  return /* @__PURE__ */ jsxs3(AdhModalPopover, { id: CONTACT_POPOVER_ID, title: `Contact ${contact.name}`, bodyClassName: "adh-modal__body--contact", children: [
    /* @__PURE__ */ jsx4("p", { className: "adh-contact__lead", children: "Questions, ideas or anything else: write to us at" }),
    /* @__PURE__ */ jsx4("a", { className: "adh-contact__email", href: `mailto:${contact.email}`, children: contact.email })
  ] });
}

// src/footer/FamilyFooter.tsx
import { getSite, groupSitesByCategory, siteProdUrl } from "@agentic-toolkit/adh-registry";

// src/header/PreviewNotice.tsx
import { useEffect, useId, useRef, useState } from "react";
import { ChevronDown, TriangleAlert } from "lucide-react";
import { jsx as jsx5, jsxs as jsxs4 } from "react/jsx-runtime";
var DEFAULT_PREVIEW_NOTICE = "Developer Preview Release";
var DEFAULT_PREVIEW_DETAIL = "We are in very early stages, and are only taking requests to join. Right now, membership is by invitation only.";
function PreviewNotice({
  notice = DEFAULT_PREVIEW_NOTICE,
  detail = DEFAULT_PREVIEW_DETAIL,
  variant = "strip"
}) {
  const [open, setOpen] = useState(false);
  const panelId = useId();
  const triggerRef = useRef(null);
  useEffect(() => {
    if (!open) return;
    const onClick = (e) => {
      if (triggerRef.current?.contains(e.target)) return;
      setOpen(false);
    };
    const onKeyDown = (e) => {
      if (e.key === "Escape") setOpen(false);
    };
    document.addEventListener("click", onClick, true);
    document.addEventListener("keydown", onKeyDown, true);
    return () => {
      document.removeEventListener("click", onClick, true);
      document.removeEventListener("keydown", onKeyDown, true);
    };
  }, [open]);
  return /* @__PURE__ */ jsx5("div", { className: variant === "badge" ? "adh-preview-badge" : "adh-header__preview", children: /* @__PURE__ */ jsxs4("span", { className: "adh-header__preview-disclosure", onMouseLeave: () => setOpen(false), children: [
    /* @__PURE__ */ jsxs4(
      "button",
      {
        ref: triggerRef,
        type: "button",
        className: "adh-header__preview-trigger",
        "aria-expanded": open,
        "aria-controls": open ? panelId : void 0,
        onClick: () => setOpen((v) => !v),
        children: [
          /* @__PURE__ */ jsx5(TriangleAlert, { className: "adh-header__preview-icon", "aria-hidden": true }),
          /* @__PURE__ */ jsx5("span", { className: "adh-header__preview-text", children: notice }),
          /* @__PURE__ */ jsx5(TriangleAlert, { className: "adh-header__preview-icon", "aria-hidden": true }),
          /* @__PURE__ */ jsx5(ChevronDown, { className: "adh-header__preview-caret", "aria-hidden": true })
        ]
      }
    ),
    open && /* @__PURE__ */ jsx5("span", { className: "adh-header__preview-panel", id: panelId, children: detail })
  ] }) });
}

// src/footer/LegalModals.tsx
import { useEffect as useEffect2, useState as useState2 } from "react";
import { isModifiedClick } from "@agenticdevelopertoolkit/ui/lib/navigation-guard";
import { LEGAL_EFFECTIVE_DATE, TermsBody, PrivacyBody } from "@agentic-toolkit/adh/legal";
import { jsx as jsx6, jsxs as jsxs5 } from "react/jsx-runtime";
var TERMS_DIALOG_ID = "adh-terms-dialog";
var PRIVACY_DIALOG_ID = "adh-privacy-dialog";
function useOpenedOnce(id) {
  const [opened, setOpened] = useState2(false);
  useEffect2(() => {
    if (opened) return;
    const el = document.getElementById(id);
    if (!el) return;
    const onToggle = (e) => {
      if (e.newState === "open") setOpened(true);
    };
    el.addEventListener("toggle", onToggle);
    return () => el.removeEventListener("toggle", onToggle);
  }, [id, opened]);
  return opened;
}
function LegalDoc({ children }) {
  return /* @__PURE__ */ jsxs5("article", { className: "adh-legal-doc", children: [
    /* @__PURE__ */ jsxs5("p", { className: "adh-legal-doc__meta", children: [
      "Effective ",
      LEGAL_EFFECTIVE_DATE
    ] }),
    children
  ] });
}
function TermsModal() {
  const opened = useOpenedOnce(TERMS_DIALOG_ID);
  return /* @__PURE__ */ jsx6(AdhModalPopover, { id: TERMS_DIALOG_ID, title: "Terms of Service", bodyClassName: "adh-modal__body--legal", children: opened && /* @__PURE__ */ jsx6(LegalDoc, { children: /* @__PURE__ */ jsx6(TermsBody, {}) }) });
}
function PrivacyModal() {
  const opened = useOpenedOnce(PRIVACY_DIALOG_ID);
  return /* @__PURE__ */ jsx6(AdhModalPopover, { id: PRIVACY_DIALOG_ID, title: "Privacy Policy", bodyClassName: "adh-modal__body--legal", children: opened && /* @__PURE__ */ jsx6(LegalDoc, { children: /* @__PURE__ */ jsx6(PrivacyBody, {}) }) });
}
function openLegalModal(dialogId) {
  return (e) => {
    if (e.defaultPrevented || isModifiedClick(e)) return;
    const el = document.getElementById(dialogId);
    if (el && "showPopover" in el) {
      e.preventDefault();
      el.showPopover({
        source: e.currentTarget
      });
    }
  };
}

// src/footer/FamilyFooter.tsx
import { jsx as jsx7, jsxs as jsxs6 } from "react/jsx-runtime";
var NATIVE_TOOLS_TITLE = "Native Tools";
var NATIVE_BADGE = "macOS";
function siteEntry(site) {
  return {
    label: site.label,
    href: siteProdUrl(site.id, "/"),
    ...site.nativeApp ? { badge: NATIVE_BADGE } : {}
  };
}
function siteColumns(sites) {
  const columns = [];
  for (const group of groupSitesByCategory(sites)) {
    const web = group.sites.filter((s) => !s.nativeApp);
    const native = group.sites.filter((s) => s.nativeApp);
    if (web.length > 0) columns.push({ title: group.label, entries: web.map(siteEntry) });
    if (native.length > 0) columns.push({ title: NATIVE_TOOLS_TITLE, entries: native.map(siteEntry) });
  }
  return columns;
}
function aboutEntries() {
  const fishlamp = getSite("fishlamp");
  return [
    { label: BRAND_LABEL, href: BRAND_HREF },
    ...fishlamp ? [{ label: fishlamp.label, href: siteProdUrl("fishlamp", "/") }] : []
  ];
}
var LEGAL_ENTRIES = [
  { label: "Terms of Use", href: "/terms", onClick: openLegalModal(TERMS_DIALOG_ID) },
  { label: "Privacy Policy", href: "/privacy", onClick: openLegalModal(PRIVACY_DIALOG_ID) }
];
function Column({ title, entries }) {
  return /* @__PURE__ */ jsxs6("nav", { className: "adh-landing-footer__column", "aria-label": title, children: [
    /* @__PURE__ */ jsx7("h3", { className: "adh-landing-footer__heading", children: title }),
    /* @__PURE__ */ jsx7("ul", { className: "adh-landing-footer__list", children: entries.map((e) => /* @__PURE__ */ jsxs6("li", { className: "adh-landing-footer__item", children: [
      /* @__PURE__ */ jsx7("a", { className: "adh-landing-footer__link", href: e.href, onClick: e.onClick, children: e.label }),
      e.badge && /* @__PURE__ */ jsx7("span", { className: "adh-landing-footer__badge", children: e.badge })
    ] }, e.label)) })
  ] });
}
function FamilyFooter({ version, links = [], anchored = false }) {
  const columns = [
    ...links.length > 0 ? [{ title: "This site", entries: links }] : [],
    ...siteColumns(FAMILY_SITES),
    { title: "About", entries: aboutEntries() },
    { title: "Legal", entries: LEGAL_ENTRIES }
  ];
  return /* @__PURE__ */ jsxs6("div", { id: anchored ? MORE_INFO_ANCHOR_ID : void 0, className: LANDING_FOOTER_CLASS, children: [
    /* @__PURE__ */ jsx7("div", { className: "adh-landing-footer__head", children: /* @__PURE__ */ jsx7(PreviewNotice, { variant: "badge" }) }),
    /* @__PURE__ */ jsx7("div", { className: "adh-landing-footer__directory", children: columns.map((column) => /* @__PURE__ */ jsx7(Column, { ...column }, column.title)) }),
    /* @__PURE__ */ jsxs6("div", { className: "adh-landing-footer__fine-print", children: [
      /* @__PURE__ */ jsxs6("p", { className: "adh-landing-footer__copyright", children: [
        "Copyright \xA9 ",
        (/* @__PURE__ */ new Date()).getFullYear(),
        " ",
        /* @__PURE__ */ jsx7("a", { className: "adh-landing-footer__link", href: BRAND_HREF, children: BRAND_LABEL }),
        ". All rights reserved."
      ] }),
      /* @__PURE__ */ jsxs6("ul", { className: "adh-landing-footer__legal", children: [
        /* @__PURE__ */ jsx7("li", { className: "adh-landing-footer__item", children: /* @__PURE__ */ jsx7(
          "button",
          {
            type: "button",
            className: "adh-landing-footer__link adh-landing-footer__contact",
            popoverTarget: CONTACT_POPOVER_ID,
            children: "Contact"
          }
        ) }),
        /* @__PURE__ */ jsx7("li", { className: "adh-landing-footer__item", children: /* @__PURE__ */ jsx7(
          "button",
          {
            type: "button",
            className: "adh-landing-footer__link adh-landing-footer__sites",
            popoverTarget: SITES_OVERVIEW_POPOVER_ID,
            children: "All sites"
          }
        ) }),
        version && /* @__PURE__ */ jsx7("li", { className: "adh-landing-footer__item adh-landing-footer__version", children: version })
      ] })
    ] })
  ] });
}

// src/footer/FooterChat.tsx
import dynamic from "next/dynamic";
import { jsx as jsx8 } from "react/jsx-runtime";
var FooterChatInner = dynamic(() => import("@agentic-toolkit/adh/footer/FooterChatInner"), {
  ssr: false
});
function FooterChat() {
  return /* @__PURE__ */ jsx8(FooterChatInner, {});
}

// src/footer/SitesOverview.tsx
import { FOOTER_SITES, groupSitesByCategory as groupSitesByCategory2, siteProdUrl as siteProdUrl2 } from "@agentic-toolkit/adh-registry";
import { jsx as jsx9, jsxs as jsxs7 } from "react/jsx-runtime";
function SitesPopover({ sites = FOOTER_SITES } = {}) {
  const groups = groupSitesByCategory2(sites);
  return /* @__PURE__ */ jsx9(AdhModalPopover, { id: SITES_OVERVIEW_POPOVER_ID, title: "The Agentic Developer family", children: groups.map((group) => /* @__PURE__ */ jsxs7(
    "nav",
    {
      className: "adh-sites-popover__group",
      "aria-label": group.label,
      children: [
        /* @__PURE__ */ jsx9("h3", { className: "adh-sites-popover__group-title", children: group.label }),
        /* @__PURE__ */ jsx9("ul", { className: "adh-sites-popover__list", children: group.sites.map((site) => /* @__PURE__ */ jsx9("li", { children: /* @__PURE__ */ jsxs7(
          "a",
          {
            className: "adh-sites-popover__item",
            href: siteProdUrl2(site.id, "/"),
            children: [
              /* @__PURE__ */ jsx9("span", { className: "adh-sites-popover__name", children: site.label }),
              site.description && /* @__PURE__ */ jsx9("span", { className: "adh-sites-popover__blurb", children: site.description })
            ]
          }
        ) }, site.id)) })
      ]
    },
    group.label
  )) });
}

// src/footer/SiteFooter.tsx
import { Fragment, jsx as jsx10, jsxs as jsxs8 } from "react/jsx-runtime";
var COPYRIGHT_PREFIX = "\xA9 2026 ";
function SiteFooter({ links = [], chat = true, live, specimen = false, contact = ADH_CONTACT }) {
  const version = buildVersionLabel(live);
  return /* @__PURE__ */ jsxs8(Fragment, { children: [
    /* @__PURE__ */ jsx10("footer", { className: "adh-footer adh-footer--floating", role: "contentinfo", children: /* @__PURE__ */ jsxs8("div", { className: "adh-footer__copyright", children: [
      /* @__PURE__ */ jsxs8("button", { type: "button", className: "adh-footer__copyright-trigger", popoverTarget: FAMILY_FOOTER_DIALOG_ID, children: [
        COPYRIGHT_PREFIX,
        /* @__PURE__ */ jsx10("span", { className: "adh-footer__brand-link", children: BRAND_LABEL }),
        /* @__PURE__ */ jsx10(ChevronsUpDown2, { className: "adh-footer__menu-caret", "aria-hidden": true })
      ] }),
      /* @__PURE__ */ jsxs8("span", { className: "adh-footer__copyright-fallback", children: [
        COPYRIGHT_PREFIX,
        /* @__PURE__ */ jsx10("a", { className: "adh-footer__brand-link", href: BRAND_HREF, children: BRAND_LABEL }),
        version && /* @__PURE__ */ jsxs8("span", { className: "adh-footer__copyright-version", children: [
          " \xB7 ",
          version
        ] })
      ] })
    ] }) }),
    chat && !specimen && /* @__PURE__ */ jsx10(FooterChat, {}),
    !specimen && /* @__PURE__ */ jsxs8(Fragment, { children: [
      /* @__PURE__ */ jsx10(AdhModalPopover, { id: FAMILY_FOOTER_DIALOG_ID, title: "The Agentic Developer family", className: "adh-modal--wide", children: /* @__PURE__ */ jsx10(FamilyFooter, { version, links }) }),
      /* @__PURE__ */ jsx10(SitesPopover, {}),
      /* @__PURE__ */ jsx10(ContactPopover, { contact }),
      /* @__PURE__ */ jsx10(TermsModal, {}),
      /* @__PURE__ */ jsx10(PrivacyModal, {})
    ] })
  ] });
}

// src/footer/FamilyDrawer.tsx
import { jsx as jsx11 } from "react/jsx-runtime";
function FamilyDrawerRow() {
  return /* @__PURE__ */ jsx11("a", { className: "lp-nav", href: `/#${FAMILY_BAND_ID}`, children: "Family" });
}
function MoreInfoDrawerFoot() {
  return /* @__PURE__ */ jsx11("a", { className: "lp-nav", href: `/#${MORE_INFO_ANCHOR_ID}`, children: "More Info" });
}

// src/footer/FooterForRoute.tsx
import { usePathname } from "next/navigation";
import { Fragment as Fragment2, jsx as jsx12 } from "react/jsx-runtime";
function FooterForRoute({ landing, rest }) {
  return /* @__PURE__ */ jsx12(Fragment2, { children: usePathname() === "/" ? landing : rest });
}

// src/footer/seededBackend.ts
var BITBAG_PERSONA = { name: "bitbag" };
function hash(s) {
  let h = 0;
  for (let i = 0; i < s.length; i++) h = h * 31 + s.charCodeAt(i) | 0;
  return h;
}
var SeededBackend = class {
  constructor(opts) {
    this.opts = opts;
  }
  opts;
  async sendMessage(text, _history) {
    await new Promise((r) => setTimeout(r, this.opts.delayMs ?? 450));
    for (const { match, reply } of this.opts.seeded) {
      if (match.test(text)) return reply;
    }
    const { fallbacks } = this.opts;
    return fallbacks[Math.abs(hash(text)) % fallbacks.length] ?? fallbacks[0];
  }
};
function createSeededBackend(opts) {
  return new SeededBackend(opts);
}

// src/footer/chat-theme-store.ts
import { useCallback, useSyncExternalStore } from "react";
import { themeIds } from "@agentic-toolkit/bitbag";
import { DEV_BUILD } from "@agentic-toolkit/adh-registry/deployment-env";
var STORAGE_KEY = "adh-chat-theme";
var THEME_SWITCH_ENABLED = DEV_BUILD;
function readStored() {
  if (!THEME_SWITCH_ENABLED) return null;
  if (typeof window === "undefined") return null;
  try {
    const v = window.localStorage.getItem(STORAGE_KEY);
    if (v && themeIds.includes(v)) return v;
  } catch {
  }
  return null;
}
function writeStored(next) {
  if (typeof window === "undefined") return;
  try {
    if (next) window.localStorage.setItem(STORAGE_KEY, next);
    else window.localStorage.removeItem(STORAGE_KEY);
  } catch {
  }
  window.dispatchEvent(new CustomEvent(STORAGE_KEY));
}
function subscribe(callback) {
  if (typeof window === "undefined") return () => {
  };
  window.addEventListener(STORAGE_KEY, callback);
  window.addEventListener("storage", callback);
  return () => {
    window.removeEventListener(STORAGE_KEY, callback);
    window.removeEventListener("storage", callback);
  };
}
function useChatTheme() {
  const theme = useSyncExternalStore(subscribe, readStored, () => null);
  const setTheme = useCallback((next) => writeStored(next), []);
  return [theme, setTheme];
}
export {
  AdhFooter,
  BITBAG_PERSONA,
  CONTACT_POPOVER_ID,
  ContactPopover,
  FAMILY_FOOTER_DIALOG_ID,
  FamilyDrawerRow,
  FamilyFooter,
  FooterChat,
  FooterForRoute,
  FooterMenu,
  MoreInfoDrawerFoot,
  PrivacyModal,
  SITES_OVERVIEW_POPOVER_ID,
  SiteFooter,
  SitesPopover,
  TermsModal,
  createSeededBackend,
  useChatTheme
};
//# sourceMappingURL=index.js.map