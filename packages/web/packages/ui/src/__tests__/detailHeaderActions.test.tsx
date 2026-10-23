/**
 * `detailActions` — a stack's own controls about the whole view, drawn in the detail header just
 * left of the [API][?] pair.
 *
 * Mike: "move the download button into the details pane header next to the api button for the rest
 * api and remove the bar the current download button is in". The REST API help's Download OpenAPI
 * JSON used to be the stack's `toolbar`, a full-width strip above the breadcrumb for one button. So
 * this asserts, in a REAL HTDV and HMDV, that `detailActions` lands inside
 * `[data-slot="detail-header"]` immediately before the API slot, and that passing it alone draws
 * no toolbar strip.
 */
/// <reference types="@testing-library/jest-dom/vitest" />
import { afterEach, describe, expect, it } from "vitest"
import { cleanup, render, screen } from "@testing-library/react"
import { HierarchicalTopicDetail, type TopicLevel } from "../blocks/hierarchical-topic-detail"
import { HierarchicalMenuDetail } from "../blocks/hierarchical-menu-detail"

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

// HMDV draws its root level as the top menu, so the detail header needs a level below it.
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

const action = <a href="/openapi.json">Download OpenAPI JSON</a>

afterEach(cleanup)

function expectBesideApi(container: HTMLElement) {
  const link = screen.getByRole("link", { name: "Download OpenAPI JSON" })
  const header = link.closest('[data-slot="detail-header"]')
  expect(header).not.toBeNull()
  // Immediately left of the API slot, which is itself left of the help slot.
  const apiSlot = header!.querySelector("[data-adh-detail-api-slot]")!
  expect(link.closest("[data-adh-detail-actions]")!.nextElementSibling).toBe(apiSlot)
  // No toolbar strip: nothing was passed for one, so no full-width bar is drawn above the crumbs.
  expect(container.querySelector("[data-adh-toolbar-slot]")).toBeNull()
  expect(screen.getAllByRole("link", { name: "Download OpenAPI JSON" })).toHaveLength(1)
}

describe("detailActions in the detail header", () => {
  it("HTDV draws them beside the API button", () => {
    const { container } = render(
      <HierarchicalTopicDetail levels={levels} layoutMode="wide" disclosureStyle="covered" detailActions={action}>
        <p>body</p>
      </HierarchicalTopicDetail>,
    )
    expectBesideApi(container)
  })

  it("HMDV draws them beside the API button", () => {
    const { container } = render(
      <HierarchicalMenuDetail levels={menuLevels} layoutMode="wide" disclosureStyle="cascading" detailActions={action}>
        <p>body</p>
      </HierarchicalMenuDetail>,
    )
    expectBesideApi(container)
  })
})
