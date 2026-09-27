/**
 * Where a selected row's connector leaves it (`rowExitEl`): past the trailing accessory when the
 * row has one, so the line never draws over a count; else the label; else the icon.
 */
import { render } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { TopicDetail, rowExitEl, type TopicDetailItem } from '../blocks/topic-detail'

function selectedRow(item: TopicDetailItem): Element {
  render(
    <TopicDetail items={[item]} selectedId={item.id} onSelect={() => {}}>
      <div>detail</div>
    </TopicDetail>,
  )
  const row = document.querySelector('[aria-current="true"]')
  if (!row) throw new Error('no selected row')
  return row
}

describe('rowExitEl', () => {
  it('leaves from the trailing accessory when the row has one', () => {
    const row = selectedRow({ id: 'a', label: 'Alpha', trailing: <span>1/1</span> })
    const exit = rowExitEl(row)
    expect(exit?.hasAttribute('data-htd-trailing')).toBe(true)
    expect(exit?.textContent).toBe('1/1')
  })

  it('leaves from the label when there is no trailing accessory', () => {
    const row = selectedRow({ id: 'a', label: 'Alpha' })
    expect(rowExitEl(row)?.hasAttribute('data-htd-label')).toBe(true)
  })
})
