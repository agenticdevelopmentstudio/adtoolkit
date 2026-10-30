// A pre-paint script runs only in the document the server sent. A layout React mounts on a client
// navigation must not create the element: it would never execute, and React reports it.
import { act, cleanup, render } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { DocumentLoadScript } from '../DocumentLoadScript'

const CODE = 'window.__ran = 1'

afterEach(cleanup)

describe('DocumentLoadScript', () => {
  it('is in the server HTML', () => {
    expect(renderToString(<DocumentLoadScript code={CODE} />)).toBe(`<script>${CODE}</script>`)
  })

  it('renders nothing on a client mount, so React never warns about it', () => {
    const error = vi.spyOn(console, 'error').mockImplementation(() => {})
    const { container } = render(<DocumentLoadScript code={CODE} />)
    expect(container.querySelector('script')).toBeNull()
    expect(error).not.toHaveBeenCalled()
    error.mockRestore()
  })

  it('hydrates the server node without a mismatch', async () => {
    const error = vi.spyOn(console, 'error').mockImplementation(() => {})
    const host = document.createElement('div')
    host.innerHTML = renderToString(<DocumentLoadScript code={CODE} />)
    document.body.append(host)
    await act(async () => {
      hydrateRoot(host, <DocumentLoadScript code={CODE} />)
    })
    expect(error).not.toHaveBeenCalled()
    host.remove()
    error.mockRestore()
  })
})
