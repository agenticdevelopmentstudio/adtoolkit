/**
 * LINK ROWS (`TopicDetailItem.onLink`): a row that leads to something elsewhere. The rule under
 * test is that a link is NOT a selection — choosing it runs the link and never the level's
 * `onSelect`, so the list it sits in keeps whatever it had chosen — and that the click is still
 * seen to land: the row is marked for a moment, then lets go.
 *
 * Rendered through the real HierarchicalTopicDetail so the row is exercised over the same path a
 * consumer uses (level -> TopicRail -> TopicList), and through TopicDetail for the standalone rail.
 */
import { act, cleanup, fireEvent, render, screen } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { HierarchicalTopicDetail, type TopicLevel } from '../blocks/hierarchical-topic-detail'
import { LINK_FLASH_MS, TopicDetail } from '../blocks/topic-detail'

function renderLevel(onLink = vi.fn(), onSelect = vi.fn(), selectedId: string | null = null) {
  const level: TopicLevel = {
    id: 'companies',
    title: 'Companies',
    items: [
      { id: 'acme', label: 'Acme' },
      { id: 'rockets', label: 'Rockets', onLink },
    ],
    selectedId,
    onSelect,
    onClear: () => {},
  }
  render(
    <HierarchicalTopicDetail levels={[level]}>
      <div>detail</div>
    </HierarchicalTopicDetail>,
  )
  return { onLink, onSelect }
}

beforeEach(() => {
  vi.useFakeTimers()
})

afterEach(() => {
  cleanup()
  vi.useRealTimers()
})

describe('TopicDetailItem.onLink', () => {
  it('runs the link and never selects the row', () => {
    const { onLink, onSelect } = renderLevel()
    fireEvent.click(screen.getByRole('button', { name: /Rockets/ }))
    expect(onLink).toHaveBeenCalledTimes(1)
    expect(onSelect).not.toHaveBeenCalled()
  })

  it('still selects an ordinary row', () => {
    const { onLink, onSelect } = renderLevel()
    fireEvent.click(screen.getByRole('button', { name: /Acme/ }))
    expect(onSelect).toHaveBeenCalledWith('acme')
    expect(onLink).not.toHaveBeenCalled()
  })

  it('marks the link as chosen for a moment, in place of the selection, then lets go', () => {
    renderLevel(vi.fn(), vi.fn(), 'acme')
    const link = screen.getByRole('button', { name: /Rockets/ })
    const chosen = screen.getByRole('button', { name: /Acme/ })
    expect(chosen).toHaveAttribute('aria-current', 'true')
    fireEvent.click(link)
    expect(link).toHaveAttribute('aria-current', 'true')
    expect(chosen).not.toHaveAttribute('aria-current')
    act(() => {
      vi.advanceTimersByTime(LINK_FLASH_MS)
    })
    expect(link).not.toHaveAttribute('aria-current')
    expect(chosen).toHaveAttribute('aria-current', 'true')
  })

  it('gets the link glyph when it names no icon', () => {
    renderLevel()
    expect(screen.getByRole('button', { name: /Rockets/ }).querySelector('[aria-label="link"]')).not.toBeNull()
    expect(screen.getByRole('button', { name: /Acme/ }).querySelector('[aria-label="link"]')).toBeNull()
  })

  it('runs from the standalone rail too', () => {
    const onLink = vi.fn()
    const onSelect = vi.fn()
    render(
      <TopicDetail
        items={[
          { id: 'acme', label: 'Acme' },
          { id: 'rockets', label: 'Rockets', onLink },
        ]}
        selectedId={null}
        onSelect={onSelect}
      >
        <div>detail</div>
      </TopicDetail>,
    )
    fireEvent.click(screen.getByRole('button', { name: /Rockets/ }))
    expect(onLink).toHaveBeenCalledTimes(1)
    expect(onSelect).not.toHaveBeenCalled()
  })
})
