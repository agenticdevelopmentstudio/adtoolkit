
This is the public surface of a principal's profile domain: social links and addresses
(owner-polymorphic rows a personal account or an organization can each hold), the per-row privacy
grant that decides who may see them, and the caller's metered usage summary. It is described in
its given implementation's source as "one entry for four endpoints because they answer about one
subject and are read together." A companion wire module holds the wire shapes (social link,
address, privacy grant, usage row/limits) and is measured against the backend's generated types by
a dedicated type-conformance check. It is a headless **logic** module — no visual surface — so
this recipe marks Appearance, States, and Accessibility not applicable and carries the runtime
contract entirely in Behavioral Requirements, per the non-UI component guidance this recipe was
authored under.

