import { afterEach, describe, expect, it, vi } from "vitest"

import { readTextFile, saveTextFile } from "../lib/file-exchange"

describe("saveTextFile", () => {
  afterEach(() => {
    delete (globalThis as { showSaveFilePicker?: unknown }).showSaveFilePicker
    vi.restoreAllMocks()
  })

  it("asks the operator where the file goes when the browser can ask", async () => {
    const write = vi.fn().mockResolvedValue(undefined)
    const close = vi.fn().mockResolvedValue(undefined)
    const picker = vi.fn().mockResolvedValue({
      createWritable: async () => ({ write, close }),
    })
    ;(globalThis as { showSaveFilePicker?: unknown }).showSaveFilePicker = picker
    const click = vi.spyOn(HTMLAnchorElement.prototype, "click")

    const saved = await saveTextFile({ text: '{"a":1}', filename: "integrations.json" })

    expect(saved).toBe(true)
    expect(write).toHaveBeenCalledWith('{"a":1}')
    expect(close).toHaveBeenCalled()
    // The whole point of the picker is that it replaces the silent download, so a run that does
    // both has handed the operator two copies and asked about one of them.
    expect(click).not.toHaveBeenCalled()
    expect(picker.mock.calls[0]![0].suggestedName).toBe("integrations.json")
    // The extension comes off the suggested name, so the dialog's type filter agrees with it.
    expect(picker.mock.calls[0]![0].types[0].accept).toEqual({ "application/json": [".json"] })
  })

  it("saves NOTHING when the operator dismisses the picker", async () => {
    // The failure this guards: treating AbortError like an unsupported browser, which downloads
    // the file they have just declined to save — into the folder they were trying to choose.
    const abort = Object.assign(new Error("The user aborted a request."), { name: "AbortError" })
    ;(globalThis as { showSaveFilePicker?: unknown }).showSaveFilePicker = vi
      .fn()
      .mockRejectedValue(abort)
    const click = vi.spyOn(HTMLAnchorElement.prototype, "click")

    const saved = await saveTextFile({ text: "{}", filename: "integrations.json" })

    expect(saved).toBe(false)
    expect(click).not.toHaveBeenCalled()
  })

  it("falls back to a download where there is no picker", async () => {
    // Firefox, Safari, and every insecure context. The fallback is the plan B, not the plan.
    const click = vi.spyOn(HTMLAnchorElement.prototype, "click")
    const createObjectURL = vi.fn().mockReturnValue("blob:x")
    const revokeObjectURL = vi.fn()
    vi.stubGlobal("URL", { ...URL, createObjectURL, revokeObjectURL })

    const saved = await saveTextFile({ text: "{}", filename: "integrations.json" })

    expect(saved).toBe(true)
    expect(click).toHaveBeenCalled()
    expect(createObjectURL).toHaveBeenCalled()
    vi.unstubAllGlobals()
  })

  it("falls back when the picker fails for a reason that is not a refusal", async () => {
    ;(globalThis as { showSaveFilePicker?: unknown }).showSaveFilePicker = vi
      .fn()
      .mockRejectedValue(new Error("disk is full of other people's screenshots"))
    const click = vi.spyOn(HTMLAnchorElement.prototype, "click")

    expect(await saveTextFile({ text: "{}", filename: "integrations.json" })).toBe(true)
    expect(click).toHaveBeenCalled()
  })
})

describe("readTextFile", () => {
  it("reads a picked file's text", async () => {
    const file = new File(['{"kind":"adh.integrations"}'], "integrations.json", {
      type: "application/json",
    })
    expect(await readTextFile(file)).toBe('{"kind":"adh.integrations"}')
  })

  it("reads it through a FileReader on a browser with no File.text()", async () => {
    // An import that silently does nothing on an older browser is worse than one that never
    // drew a button, so the fallback is exercised rather than assumed.
    const file = new File(["hello"], "x.json")
    Object.defineProperty(file, "text", { value: undefined })
    expect(await readTextFile(file)).toBe("hello")
  })
})
