import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { cleanup, fireEvent, render, screen, within } from "@testing-library/react";
import { HierarchicalTopicDetail, type TopicLevel } from "../blocks/hierarchical-topic-detail";
import { resetSeededBackStackForTests } from "../hooks/useSeededBackStack";
import { GUARDED_NAV_ATTR } from "../lib/navigation-guard";
import type { PaneExitGuard } from "../hooks/useExitGate";

// `clearHref`: a routed host says where each level clears to, and the stack turns that into
// breadcrumbs that are links, a browser Back that walks up the stack after a deep link, and a
// console error for a clear that lands on the page already showing.

const SEED_KEY = "__adhTopicSeed";

type ClearFn = TopicLevel["onClear"];

function levelsAt(path: string[], onClear: ClearFn[] = [vi.fn(), vi.fn()]): TopicLevel[] {
  return [
    {
      id: "companies",
      title: "Companies",
      items: [{ id: "acme", label: "Acme" }],
      selectedId: path[0] ?? null,
      clearHref: "/planning",
      onSelect: () => {},
      onClear: onClear[0]!,
    },
    {
      id: "acme",
      title: "Inside Acme",
      items: [{ id: "rockets", label: "Rockets" }],
      selectedId: path[1] ?? null,
      clearHref: "/planning/acme",
      onSelect: () => {},
      onClear: onClear[1]!,
    },
  ];
}

function renderAt(path: string[], onClear?: ClearFn[], exitGuard: PaneExitGuard | null = null) {
  window.history.replaceState(null, "", ["/planning", ...path].join("/"));
  return render(
    <HierarchicalTopicDetail levels={levelsAt(path, onClear)} rootLabel="Planning" layoutMode="narrow" exitGuard={exitGuard}>
      <p>detail</p>
    </HierarchicalTopicDetail>,
  );
}

beforeEach(() => {
  resetSeededBackStackForTests();
});

afterEach(() => {
  cleanup();
  vi.restoreAllMocks();
});

describe("HierarchicalTopicDetail clearHref breadcrumbs", () => {
  it("renders each crumb as a link to the address it clears to", () => {
    renderAt(["acme", "rockets"]);
    const nav = screen.getByLabelText("Breadcrumb");
    expect(within(nav).getByRole("link", { name: "Planning" })).toHaveAttribute("href", "/planning");
    expect(within(nav).getByRole("link", { name: "Acme" })).toHaveAttribute("href", "/planning/acme");
    // The current crumb is where you are, not a link.
    expect(within(nav).queryByRole("link", { name: "Rockets" })).toBeNull();
  });

  it("marks its crumb links as guarded when it has an exitGuard, since their click handler asks it", () => {
    renderAt(["acme", "rockets"], undefined, { isDirty: () => false });
    const nav = screen.getByLabelText("Breadcrumb");
    for (const name of ["Planning", "Acme"]) {
      expect(within(nav).getByRole("link", { name })).toHaveAttribute(GUARDED_NAV_ATTR);
    }
  });

  it("leaves its crumb links unmarked without an exitGuard, so a document-level guard still asks", () => {
    renderAt(["acme", "rockets"]);
    const nav = screen.getByLabelText("Breadcrumb");
    for (const name of ["Planning", "Acme"]) {
      expect(within(nav).getByRole("link", { name })).not.toHaveAttribute(GUARDED_NAV_ATTR);
    }
  });

  it("clears in place on a plain click and leaves a modified click to the browser", () => {
    const onClear = [vi.fn<ClearFn>(), vi.fn<ClearFn>()];
    renderAt(["acme", "rockets"], onClear);
    const acme = within(screen.getByLabelText("Breadcrumb")).getByRole("link", { name: "Acme" });
    fireEvent.click(acme, { metaKey: true });
    expect(onClear[1]).not.toHaveBeenCalled();
    fireEvent.click(acme);
    expect(onClear[1]).toHaveBeenCalledTimes(1);
    expect(onClear[0]).not.toHaveBeenCalled();
  });
});

describe("HierarchicalTopicDetail seeded Back stack", () => {
  it("puts one entry per selected level behind a deep-linked page", () => {
    const before = window.history.length;
    renderAt(["acme", "rockets"]);
    // /planning replaced the loaded entry, then /planning/acme and the page itself were pushed.
    expect(window.history.length).toBe(before + 2);
    expect(window.location.pathname).toBe("/planning/acme/rockets");
  });

  it("clears the level a Back onto a seeded entry leads to, replacing rather than pushing", () => {
    const onClear = [vi.fn<ClearFn>(), vi.fn<ClearFn>()];
    renderAt(["acme", "rockets"], onClear);
    const other = vi.fn();
    window.addEventListener("popstate", other);
    window.dispatchEvent(new PopStateEvent("popstate", { state: { _N: true, [SEED_KEY]: "/planning/acme" } }));
    window.removeEventListener("popstate", other);
    expect(onClear[1]).toHaveBeenCalledWith({ replace: true });
    expect(onClear[0]).not.toHaveBeenCalled();
    // Answered: the router's own listener never sees it.
    expect(other).not.toHaveBeenCalled();
  });

  it("seeds nothing when nothing is selected", () => {
    const before = window.history.length;
    renderAt([]);
    expect(window.history.length).toBe(before);
  });

  it("seeds only once per document", () => {
    renderAt(["acme", "rockets"]);
    cleanup();
    const before = window.history.length;
    renderAt(["acme", "rockets"]);
    expect(window.history.length).toBe(before);
  });
});

describe("HierarchicalTopicDetail dead clear", () => {
  it("reports a selected level whose clearHref is the page already showing", () => {
    const error = vi.spyOn(console, "error").mockImplementation(() => {});
    window.history.replaceState(null, "", "/planning");
    const levels = levelsAt(["acme"]);
    render(
      <HierarchicalTopicDetail levels={levels} rootLabel="Planning">
        {null}
      </HierarchicalTopicDetail>,
    );
    expect(error).toHaveBeenCalledWith(expect.stringContaining('"acme" is selected at /planning'));
  });

  it("stays quiet when every clear leads somewhere else", () => {
    const error = vi.spyOn(console, "error").mockImplementation(() => {});
    renderAt(["acme", "rockets"]);
    expect(error).not.toHaveBeenCalledWith(expect.stringContaining("[HierarchicalTopicDetail]"));
  });
});
