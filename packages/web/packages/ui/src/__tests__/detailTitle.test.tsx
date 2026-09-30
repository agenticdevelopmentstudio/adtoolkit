/**
 * `useDetailTitle` — a pane's title drawn in the stack's detail strip, not in the pane.
 *
 * Mike: "the title for each details pane just be left justified next to the new <<< | >>>
 * control, the title should not be in the details pane, this should be part of the shared code".
 * So this asserts it in a REAL HTDV and HMDV rather than a stand-in strip: the title lands in
 * `[data-htd-detail-title]` beside `[data-htd-cover-all]` and nowhere inside `[data-htd-detail]`;
 * the stack's own `detailTitle` prop still shows when no pane claims the slot, and with neither the
 * strip names the selected topic (Mike: "the title in the topic view by default"); the title is
 * withdrawn when its pane unmounts (the registration CLEANUP path — distinct from a pane that
 * stays mounted and passes null); the LAST of two simultaneous registrants wins while the other
 * draws inline; and outside any stack the pane simply keeps its title inline.
 */
/// <reference types="@testing-library/jest-dom/vitest" />
import type { ReactNode } from "react"
import { afterEach, describe, expect, it } from "vitest"
import { cleanup, render, screen } from "@testing-library/react"
import { HierarchicalTopicDetail, type TopicLevel } from "../blocks/hierarchical-topic-detail"
import { HierarchicalMenuDetail } from "../blocks/hierarchical-menu-detail"
import { SectionHeader } from "../blocks/section-header"
import { useDetailTitle } from "../blocks/detail-title"

const levels: TopicLevel[] = [
  {
    id: "companies",
    title: "Companies",
    items: [{ id: "acme", label: "Acme" }],
    selectedId: "acme",
    onSelect: () => {},
    onClear: () => {},
  },
]

// HMDV draws its root level as the top menu, so the detail strip needs a level below it.
const menuLevels: TopicLevel[] = [
  levels[0]!,
  {
    id: "teams",
    title: "Teams",
    items: [{ id: "core", label: "Core" }],
    selectedId: "core",
    onSelect: () => {},
    onClear: () => {},
  },
]

function Titled({ title }: { title: ReactNode }) {
  const { hoisted, portal } = useDetailTitle(title)
  return (
    <>
      {portal}
      {!hoisted && title !== null && <h2>{title}</h2>}
      <p>body</p>
    </>
  )
}

function htdv(children: ReactNode, detailTitle?: string) {
  return (
    <HierarchicalTopicDetail levels={levels} layoutMode="wide" disclosureStyle="covered" detailTitle={detailTitle}>
      {children}
    </HierarchicalTopicDetail>
  )
}

const strip = (c: HTMLElement) => c.querySelector<HTMLElement>("[data-htd-detail-title]")!
// The pane's own body: the box after the strip, in every layout of both stacks.
const pane = (c: HTMLElement) => strip(c).parentElement!.nextElementSibling as HTMLElement

afterEach(cleanup)

describe("detail title in the strip", () => {
  it("moves a pane's title into the strip beside <<< | >>>, out of the pane", () => {
    const { container } = render(htdv(<Titled title="Acme Corp" />))
    expect(strip(container)).toHaveTextContent("Acme Corp")
    const coverAll = container.querySelector("[data-htd-cover-all]")!
    expect(coverAll.parentElement).toBe(strip(container).parentElement)
    expect(pane(container).textContent).not.toContain("Acme Corp")
  })

  it("carries a SectionHeader marked paneTitle, and leaves an unmarked one where it is", () => {
    const { container } = render(
      htdv(
        <>
          <SectionHeader paneTitle title="Providers" />
          <SectionHeader title="Sign-in methods" />
        </>,
      ),
    )
    expect(strip(container)).toHaveTextContent("Providers")
    expect(pane(container).textContent).not.toContain("Providers")
    expect(pane(container).textContent).toContain("Sign-in methods")
  })

  it("falls back to the stack's detailTitle prop when no pane claims the slot", () => {
    const { container } = render(htdv(<p>body</p>, "Endpoint"))
    expect(strip(container)).toHaveTextContent("Endpoint")
  })

  it("withdraws the title when its pane unmounts", () => {
    const { container, rerender } = render(htdv(<Titled title="Acme Corp" />, "Fallback"))
    expect(strip(container)).toHaveTextContent("Acme Corp")
    rerender(htdv(<p>body</p>, "Fallback"))
    expect(strip(container)).toHaveTextContent("Fallback")
    expect(strip(container).textContent).not.toContain("Acme Corp")
  })

  it("withdraws it when a still-mounted pane passes null, back to the selected topic", () => {
    const { container, rerender } = render(htdv(<Titled title="Acme Corp" />))
    rerender(htdv(<Titled title={null} />))
    expect(strip(container).textContent).toBe("Acme")
  })

  // Mike: "It should be the title in the topic view by default, but this should be overridable by
  // the details pane".
  it("defaults to the selected topic's label when neither pane nor host names it", () => {
    const { container } = render(htdv(<p>body</p>))
    expect(strip(container).textContent).toBe("Acme")
  })

  it("names nothing when nothing is selected", () => {
    const unselected: TopicLevel[] = [{ ...levels[0]!, selectedId: null }]
    const { container } = render(
      <HierarchicalTopicDetail levels={unselected} layoutMode="wide" disclosureStyle="covered">
        <p>body</p>
      </HierarchicalTopicDetail>,
    )
    expect(container.querySelector("[data-htd-detail-title]")?.textContent ?? "").toBe("")
  })

  it("defaults to the selected topic in HMDV too", () => {
    const { container } = render(
      <HierarchicalMenuDetail levels={menuLevels} layoutMode="wide">
        <p>body</p>
      </HierarchicalMenuDetail>,
    )
    expect(strip(container).textContent).toBe("Core")
  })

  it("gives the strip to the LAST registrant; the other draws inline", () => {
    const { container } = render(
      htdv(
        <>
          <Titled title="First" />
          <Titled title="Second" />
        </>,
      ),
    )
    expect(strip(container)).toHaveTextContent("Second")
    expect(strip(container).textContent).not.toContain("First")
    expect(pane(container)).toHaveTextContent("First")
  })

  it("does the same in HMDV", () => {
    const { container } = render(
      <HierarchicalMenuDetail levels={menuLevels} layoutMode="wide">
        <Titled title="Acme Corp" />
      </HierarchicalMenuDetail>,
    )
    expect(strip(container)).toHaveTextContent("Acme Corp")
    expect(pane(container).textContent).not.toContain("Acme Corp")
  })

  // The review's findings on the strip (code review, full branch).
  it("is the pane's level-2 heading, so hoisting keeps the accessible heading", () => {
    render(htdv(<Titled title="Profile" />))
    expect(screen.getByRole("heading", { name: "Profile", level: 2 })).toBeInTheDocument()
  })

  it("announces no heading while nothing is titled", () => {
    const unselected: TopicLevel[] = [{ ...levels[0]!, selectedId: null }]
    const { container } = render(
      <HierarchicalTopicDetail levels={unselected} layoutMode="wide" disclosureStyle="covered">
        <p>body</p>
      </HierarchicalTopicDetail>,
    )
    expect(container.querySelector("[data-htd-detail-title]")?.getAttribute("role") ?? null).toBeNull()
  })

  it("honours a host's detailTitle={null} as an opt-out, not as 'use the default'", () => {
    const { container } = render(
      <HierarchicalTopicDetail levels={levels} layoutMode="wide" disclosureStyle="covered" detailTitle={null}>
        <p>body</p>
      </HierarchicalTopicDetail>,
    )
    expect(container.querySelector("[data-htd-detail-title]")?.textContent ?? "").toBe("")
  })

  it("keeps naming the open row after a filter drops it from its level", () => {
    const { container, rerender } = render(htdv(<p>body</p>))
    expect(strip(container).textContent).toBe("Acme")
    const filtered: TopicLevel[] = [{ ...levels[0]!, items: [] }]
    rerender(
      <HierarchicalTopicDetail levels={filtered} layoutMode="wide" disclosureStyle="covered">
        <p>body</p>
      </HierarchicalTopicDetail>,
    )
    expect(strip(container).textContent).toBe("Acme")
  })

  it("falls back to the selected id, like the crumb, before the row's list loads", () => {
    const deepLink: TopicLevel[] = [{ ...levels[0]!, items: [] }]
    const { container } = render(
      <HierarchicalTopicDetail levels={deepLink} layoutMode="wide" disclosureStyle="covered">
        <p>body</p>
      </HierarchicalTopicDetail>,
    )
    expect(strip(container).textContent).toBe("acme")
  })

  it("does not let a pane hidden under the 'Select a …' overview name the strip", () => {
    const choosing: TopicLevel[] = [levels[0]!, { ...menuLevels[1]!, selectedId: null }]
    const { container } = render(
      <HierarchicalTopicDetail levels={choosing} layoutMode="wide" disclosureStyle="covered">
        <Titled title="Hidden pane" />
      </HierarchicalTopicDetail>,
    )
    expect(strip(container).textContent).toBe("Acme")
  })

  it("keeps the title inline with no stack around it", () => {
    const { container } = render(<Titled title="Orphan" />)
    expect(container.querySelector("h2")).toHaveTextContent("Orphan")
  })
})
