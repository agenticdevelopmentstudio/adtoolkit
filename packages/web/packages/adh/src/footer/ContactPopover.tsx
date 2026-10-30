'use client'

import { AdhModalPopover } from './AdhModalPopover'
import { ADH_CONTACT, CONTACT_POPOVER_ID, type SiteContact } from './identity'

/**
 * The footer's Contact dialog, opened by the Contact entry of the family footer's fine print
 * (FamilyFooter). Per site: the family's sites write to the hub ({@link ADH_CONTACT}), and a
 * site with an address of its own passes it — the studio and FishLamp Design through
 * `LandingFooter`'s `contact`.
 *
 * The address is a real `mailto:` link in the server HTML, so it works before hydration and
 * without the Popover API's dialog ever opening.
 */
export function ContactPopover({ contact = ADH_CONTACT }: { contact?: SiteContact } = {}) {
  return (
    <AdhModalPopover id={CONTACT_POPOVER_ID} title={`Contact ${contact.name}`} bodyClassName="adh-modal__body--contact">
      <p className="adh-contact__lead">Questions, ideas or anything else: write to us at</p>
      <a className="adh-contact__email" href={`mailto:${contact.email}`}>
        {contact.email}
      </a>
    </AdhModalPopover>
  )
}
