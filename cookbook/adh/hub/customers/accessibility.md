
Not applicable — this is the Customers domain's data-access protocol, data
shapes, and navigation/forms logic, not a visual component.
`CustomersDataSource`, `CustomersModels`, and `CustomersTopic` produce no
view, role, trait, or label of their own; any accessibility surface
belongs to the `FormViewController`/`AgenticToolkitHTDVViewController`
presentation layer that renders the `HTDVLevel`/`HTDVDetail`/`FormSpec`
values these sources build (out of this recipe's given sources; see the
related HTDV Engine recipe).

