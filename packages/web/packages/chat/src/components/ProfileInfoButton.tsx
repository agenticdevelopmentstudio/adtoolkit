import { memo } from 'react'
import type { NamedExoticComponent, ReactElement } from 'react'

/**
 * A small circled "i" perched on the chat frame's top-left corner, linking to
 * the persona's profile (e.g. its Agentic Persona Registry page). Render it as
 * a sibling of the chat view inside the host's `position: relative` wrapper —
 * not inside `.persona-chat`, whose overflow:hidden would clip the overhang —
 * and import css/components/profile-info.css. Skinned by the chat theme's own
 * tokens, so it reads as part of whichever theme the chat wears.
 */

export interface ProfileInfoButtonProps {
  /** The persona's profile URL — opens in a new tab. */
  profileUrl: string
  /** Accessible name and hover tooltip (e.g. "olylo's profile"). */
  label: string
  className?: string
}

function ProfileInfoButtonImpl({
  profileUrl,
  label,
  className,
}: ProfileInfoButtonProps): ReactElement {
  return (
    <a
      className={['pc-profile-info', className].filter(Boolean).join(' ')}
      href={profileUrl}
      target="_blank"
      rel="noopener noreferrer"
      aria-label={label}
      title={label}
    >
      <span aria-hidden="true">i</span>
    </a>
  )
}

/* Memoized: the host chat re-renders on every streamed token, but the
 * button's props are static after mount. */
export const ProfileInfoButton: NamedExoticComponent<ProfileInfoButtonProps> =
  memo(ProfileInfoButtonImpl)
