// NO "use client" — a server component. Renders one document card (Hub Features, Tutorials): the
// entry's name and blurb, then a card for each thing the page said — what it is, what it looks
// like, what a program can do with it, where it links, and what it is built on. The HTML in each
// block was rendered by content-buildr from the markdown under a content tree in adhcontent's
// content/adhubwebsite/, so it is injected as-is.
//
// A tutorials document shows a tutorial one pane at a time (Overview, Definitions, Steps), and its
// Glossary as a searchable list: `view.tutorial` and `view.glossary` say which. A tutorial's
// Overview carries its References, and an API button that opens the API explorer on the routes
// the tutorial names. The interactive pieces are client components, reached by package path.

import type { ReactNode } from "react";
import Link from "next/link";
import {
  Activity,
  Book,
  BookOpenText,
  Braces,
  Cloud,
  Code2,
  Cpu,
  Database,
  Globe,
  Image as ImageIcon,
  Layers,
  Link2,
  ListChecks,
  MonitorSmartphone,
  Plug,
  Quote,
  Wrench,
  type LucideIcon,
} from "lucide-react";
import { StatCard } from "@adh-sdk/ui/blocks";
import { Badge } from "@adh-sdk/ui/components/badge";
import { Favicon } from "@adh-sdk/ui/components/favicon";
import { TONE_TEXT_CLASS, type Tone } from "@adh-sdk/ui/lib/tone";
import { ApiButton } from "@adh-sdk/api-explorer";
import { GlossarySearch } from "@adh-sdk/adh/help/document/GlossarySearch";
import { TutorialSteps } from "@adh-sdk/adh/help/document/TutorialSteps";
import { TermBlock } from "./TermBlock";
import type { DocCard, DocLink, DocRef, DocTechKind, DocView, TutorialView } from "./model";
import { sectionsOf, TUTORIAL_PARTS } from "./parts";

/** The tints a card's captions and glyphs use: the toolkit's tones minus the two text greys. */
type Hue = Extract<Tone, "accent" | "blue" | "orange" | "success" | "error">;

// The GitHub mark, copied from the toolkit's auth package rather than imported from it:
// `@adh-sdk/auth/ui` is ONE 'use client' bundle, so importing its icon shipped the
// sign-in, sign-up and MFA cards (16 KB) to every document page — the only help routes paying for
// them, for a glyph none of the built document's cards can render yet (every `links` array is
// empty). Keep in step with T/auth/src/ui/GithubIcon.tsx if that mark ever changes.
function GithubMark(): ReactNode {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z" />
    </svg>
  );
}

/** The caption, glyph and tint of each kind of tech term. */
const TECH: Record<DocTechKind, { title: string; icon: LucideIcon; hue: Hue }> = {
  languages: { title: "Languages", icon: Code2, hue: "blue" },
  frameworks: { title: "Frameworks", icon: Layers, hue: "accent" },
  data: { title: "Data", icon: Database, hue: "success" },
  hosting: { title: "Hosting", icon: Cloud, hue: "orange" },
  services: { title: "Services", icon: Activity, hue: "error" },
  protocols: { title: "APIs & protocols", icon: Plug, hue: "blue" },
  platforms: { title: "Runs on", icon: MonitorSmartphone, hue: "success" },
  tooling: { title: "Tooling", icon: Wrench, hue: "orange" },
};

function glyph(Icon: LucideIcon, hue: Hue): ReactNode {
  return <Icon className={`size-4 ${TONE_TEXT_CLASS[hue]}`} strokeWidth={2.2} />;
}

function Panel({
  title,
  icon,
  hue,
  footnote,
  children,
}: {
  title: string;
  icon: LucideIcon;
  hue: Hue;
  footnote?: ReactNode;
  children: ReactNode;
}) {
  return (
    <StatCard title={title} icon={glyph(icon, hue)} footnote={footnote} className="bg-apt-surface-2">
      <div className="flex flex-col gap-3">{children}</div>
    </StatCard>
  );
}

function Caption({ icon: Icon, hue, children }: { icon: LucideIcon; hue: Hue; children: ReactNode }) {
  return (
    <span className="inline-flex items-center gap-1.5 font-mono text-[11px] font-semibold uppercase tracking-[0.06em] text-apt-text">
      <Icon className={`size-3.5 shrink-0 ${TONE_TEXT_CLASS[hue]}`} strokeWidth={2.2} />
      {children}
    </span>
  );
}

/** A block of rendered markdown. */
function Copy({ html, className = "" }: { html: string; className?: string }) {
  return <div className={`doc-copy ${className}`} dangerouslySetInnerHTML={{ __html: html }} />;
}

function Source({ lead, from }: { lead: string; from: DocRef }) {
  return (
    <span>
      {lead}{" "}
      <Link href={from.href} className="text-apt-gold underline-offset-2 hover:underline">
        {from.name}
      </Link>
    </span>
  );
}

/** A link to another page of this site (`/hub/…`), not to somewhere else on the web. */
function isInternal(url: string): boolean {
  return url.startsWith("/") && !url.startsWith("//");
}

function LinkIcon({ link }: { link: DocLink }) {
  if (link.url && isInternal(link.url)) {
    return <BookOpenText className="size-4 text-apt-gold" strokeWidth={2.2} />;
  }
  if (link.kind === "github") {
    return (
      <span className="inline-flex size-4 items-center justify-center text-apt-text [&_svg]:size-4">
        <GithubMark />
      </span>
    );
  }
  return (
    <Favicon
      href={link.url ?? ""}
      size={16}
      fallback={<Globe className="size-4 text-apt-blue" strokeWidth={2.2} />}
    />
  );
}

function LinkRow({ link }: { link: DocLink }) {
  if (!link.url) {
    return (
      <li>
        <Copy html={link.note ?? link.name} className="text-sm" />
      </li>
    );
  }
  const note = link.note ? (
    <span className="block text-xs text-apt-text-dim" dangerouslySetInnerHTML={{ __html: link.note }} />
  ) : null;
  // Another help page opens in place, by client navigation, and is named rather than shown as a
  // bare path; a link off the site opens in a new tab with its address showing.
  if (isInternal(link.url)) {
    return (
      <li className="flex items-start gap-2.5">
        <span className="mt-[3px] inline-flex">
          <LinkIcon link={link} />
        </span>
        <span className="min-w-0 text-sm leading-6">
          <Link
            href={link.url}
            className="font-semibold text-apt-gold underline-offset-2 hover:underline"
            data-testid="doc-internal-link"
          >
            {link.name}
          </Link>
          {note}
        </span>
      </li>
    );
  }
  return (
    <li className="flex items-start gap-2.5">
      <span className="mt-[3px] inline-flex">
        <LinkIcon link={link} />
      </span>
      <span className="min-w-0 text-sm leading-6">
        <span className="font-semibold text-apt-text">{link.name}:</span>{" "}
        <a
          href={link.url}
          target="_blank"
          rel="noopener noreferrer"
          className="break-all font-mono text-[13px] text-apt-gold underline-offset-2 hover:underline"
        >
          {link.url}
        </a>
        {note}
      </span>
    </li>
  );
}

function TechDetail({ tech }: { tech: DocCard["tech"] }) {
  return (
    <Panel
      title="Tech Detail"
      icon={Cpu}
      hue="accent"
      footnote={tech.from ? <Source lead="The stack of" from={tech.from} /> : undefined}
    >
      {tech.stack.length ? (
        <dl className="grid grid-cols-[minmax(8.5rem,auto)_1fr] items-start gap-x-4 gap-y-2.5">
          {tech.stack.map(({ kind, terms }) => {
            const meta = TECH[kind];
            // The kinds come from adhcontent's content/adhubwebsite/hub-features/tech.json at
            // build time and this table is
            // hand-kept, so a new kind there arrives here as `undefined` — and would render as a
            // crash deep in JSX with no name in it. Name the gap at its origin instead.
            if (!meta) {
              throw new Error(
                `DocumentDetail has no caption, glyph or tint for tech kind "${kind}" ` +
                  "(added to content/adhubwebsite/hub-features/tech.json in adhcontent?) — add it to TECH.",
              );
            }
            return (
              <div key={kind} className="contents">
                <dt className="pt-[3px]">
                  <Caption icon={meta.icon} hue={meta.hue}>
                    {meta.title}
                  </Caption>
                </dt>
                <dd className="flex flex-wrap gap-1.5">
                  {terms.map((t) =>
                    t.url ? (
                      <a
                        key={t.name}
                        href={t.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="rounded-sm transition-opacity hover:opacity-80"
                      >
                        <Badge variant={meta.hue}>{t.name}</Badge>
                      </a>
                    ) : (
                      <Badge key={t.name} variant={meta.hue}>
                        {t.name}
                      </Badge>
                    ),
                  )}
                </dd>
              </div>
            );
          })}
        </dl>
      ) : null}
      {tech.notes.length ? (
        <div className={`flex flex-col gap-2 ${tech.stack.length ? "border-t border-apt-border pt-3" : ""}`}>
          {tech.notes.map((html, i) => (
            <Copy key={i} html={html} />
          ))}
        </div>
      ) : null}
    </Panel>
  );
}

/** The blocks of a card's prose, each as its own block of copy. */
function Blocks({ html }: { html: readonly string[] }) {
  return (
    <>
      {html.map((block, i) => (
        <Copy key={i} html={block} />
      ))}
    </>
  );
}

function Header({ card, kicker, action }: { card: DocCard; kicker?: string; action?: ReactNode }) {
  const heading = <h1 className="text-[1.9rem] font-[650] leading-tight text-apt-text">{card.name}</h1>;
  return (
    <header className="flex flex-col gap-2 border-b border-apt-border pb-5">
      {kicker ? (
        <span className="w-fit font-mono text-[11px] font-semibold uppercase tracking-[0.13em] text-apt-text-muted">
          {kicker}
        </span>
      ) : card.crumb ? (
        <Link
          href={card.crumb.href}
          className="w-fit font-mono text-[11px] font-semibold uppercase tracking-[0.13em] text-apt-text-muted hover:text-apt-gold"
        >
          {card.crumb.name}
        </Link>
      ) : null}
      {action ? (
        <div className="flex flex-wrap items-start justify-between gap-3">
          {heading}
          <div className="shrink-0 pt-1.5">{action}</div>
        </div>
      ) : (
        heading
      )}
    </header>
  );
}

function Blurb({ card }: { card: DocCard }) {
  if (!card.blurb && !card.borrowed) return null;
  return (
    <div className="flex flex-col gap-1.5">
      {card.blurb ? <Copy html={card.blurb} className="doc-blurb" /> : null}
      {card.borrowed ? (
        <p className="font-mono text-[11px] text-apt-text-dim">
          <Source lead="Borrowed from" from={card.borrowed} />
        </p>
      ) : null}
    </div>
  );
}

function Screenshots({ card }: { card: DocCard }) {
  if (!card.screenshots.length) return null;
  return (
    <Panel title="Screenshots" icon={ImageIcon} hue="success">
      {card.screenshots.map((shot) => (
        <figure key={shot.src} className="flex flex-col gap-2">
          {/* eslint-disable-next-line @next/next/no-img-element -- built content, served as-is */}
          <img
            src={shot.src}
            alt={shot.alt}
            loading="lazy"
            className="h-auto w-full rounded-md border border-apt-border"
          />
          {shot.caption ? (
            <figcaption className="text-sm text-apt-text-dim">{shot.caption}</figcaption>
          ) : null}
        </figure>
      ))}
    </Panel>
  );
}

function Api({ card }: { card: DocCard }) {
  if (!card.api.length) return null;
  return (
    <Panel title="API" icon={Braces} hue="blue">
      <Blocks html={card.api} />
    </Panel>
  );
}

function Links({ card, title }: { card: DocCard; title: string }) {
  if (!card.links.length) return null;
  return (
    <Panel title={title} icon={Link2} hue="accent">
      <ul className="flex flex-col gap-2.5">
        {card.links.map((link) => (
          <LinkRow key={`${link.kind}:${link.url}:${link.name}`} link={link} />
        ))}
      </ul>
    </Panel>
  );
}

function Tech({ card }: { card: DocCard }) {
  const hasTech = card.tech.stack.length > 0 || card.tech.notes.length > 0;
  return hasTech ? <TechDetail tech={card.tech} /> : null;
}

/** The label of a tutorial's pane, as its row in the list reads. */
function paneLabel(part: TutorialView["part"]): string {
  if (part === "overview") return "Overview";
  return TUTORIAL_PARTS.find((p) => p.id === part)!.label;
}

/** One pane of a tutorial. */
function TutorialPane({
  card,
  tutorial,
  descriptionTitle,
}: {
  card: DocCard;
  tutorial: TutorialView;
  descriptionTitle: string;
}) {
  const label = paneLabel(tutorial.part);
  // The API button is the Overview's: it opens the API explorer on the routes the card's `## API`
  // names, with that section's prose above it. A card whose API names no route has nothing to
  // highlight, so it has no button, and its Overview shows the prose as a panel instead.
  const action =
    tutorial.part === "overview" && tutorial.api.length ? (
      <ApiButton
        readOnly
        label="API"
        size="sm"
        title={`API: ${card.name}`}
        highlight={tutorial.api}
        highlightLabel="This tutorial"
        intro={<Blocks html={card.api} />}
      />
    ) : undefined;
  let body: ReactNode;
  switch (tutorial.part) {
    case "overview":
      body = (
        <>
          <Blurb card={card} />
          {tutorial.lead.length ? (
            <Panel title={descriptionTitle} icon={BookOpenText} hue="blue">
              <Blocks html={tutorial.lead} />
            </Panel>
          ) : null}
          <Screenshots card={card} />
          {tutorial.api.length ? null : <Api card={card} />}
          <Links card={card} title="References" />
          <Tech card={card} />
        </>
      );
      break;
    case "definitions":
      body = (
        <Panel
          title={label}
          icon={Quote}
          hue="accent"
          footnote={<Source lead="Every term is in the" from={tutorial.glossary} />}
        >
          <dl className="flex flex-col gap-3" data-testid="tutorial-terms">
            {tutorial.terms.map((term) => (
              <TermBlock key={term.id} term={term} href={`${tutorial.glossary.href}#${term.id}`} />
            ))}
          </dl>
        </Panel>
      );
      break;
    case "steps":
      body = (
        <TutorialSteps
          tutorialId={tutorial.id}
          steps={tutorial.steps}
          title={label}
          icon={glyph(ListChecks, "blue")}
        />
      );
      break;
  }
  return (
    <article className="doc-prose flex flex-col gap-6" data-pane={tutorial.part}>
      <Header card={card} kicker={label} action={action} />
      {body}
    </article>
  );
}

/** `descriptionTitle` heads the card that holds the page's `## Description`: a Hub Features page
 *  describes; a tutorials document's root page and tutorials open on an overview. */
export function DocumentDetail({
  view,
  card,
  descriptionTitle,
}: {
  view: DocView;
  card: DocCard;
  descriptionTitle: string;
}) {
  if (view.tutorial) {
    return <TutorialPane card={card} tutorial={view.tutorial} descriptionTitle={descriptionTitle} />;
  }
  if (view.glossary) {
    const { lead } = sectionsOf(card.description);
    return (
      <article className="doc-prose flex flex-col gap-6" data-pane="glossary">
        <Header card={card} />
        <Blurb card={card} />
        {lead.length ? (
          <Panel title={descriptionTitle} icon={BookOpenText} hue="blue">
            <Blocks html={lead} />
          </Panel>
        ) : null}
        <GlossarySearch
          terms={view.glossary.terms}
          tutorials={view.glossary.tutorials}
          title="Terms"
          icon={glyph(Book, "accent")}
        />
        <Links card={card} title="Links" />
      </article>
    );
  }
  return (
    <article className="doc-prose flex flex-col gap-6">
      <Header card={card} />
      <Blurb card={card} />
      {card.description.length ? (
        <Panel title={descriptionTitle} icon={BookOpenText} hue="blue">
          <Blocks html={card.description} />
        </Panel>
      ) : null}
      <Screenshots card={card} />
      <Api card={card} />
      <Links card={card} title="Links" />
      <Tech card={card} />
    </article>
  );
}
