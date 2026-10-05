
- **wraps-native-preview-control**: The component MUST present the platform's native file-preview control within the surrounding view hierarchy, as a wrapped native view rather than a bespoke re-implementation.
- **requires-preview-url**: The component MUST expose the file location to preview as a required, non-optional, immutable input.
- **constructs-preview-view-with-normal-style**: On creation, the component MUST initialize the native preview control in its full-featured ("normal") presentation style rather than a reduced one.
- **falls-back-to-default-style-when-unavailable**: If the native preview control's full-featured-style initializer is unavailable (yields no instance), the component MUST fall back to constructing the control at its default style instead of crashing or leaving no view.
- **enables-autostart**: The component MUST configure the native preview control to begin generating its preview immediately upon creation, without requiring a separate, explicit start call.
- **sets-initial-preview-item**: On creation, the component MUST configure the native preview control to preview the file at the given location before the control is returned to the view hierarchy.
- **skips-redundant-preview-item-updates**: The component MUST NOT re-trigger preview generation when the incoming file location is unchanged from the file the control is already showing.
- **updates-preview-item-on-url-change**: The component MUST update the native preview control to display the new file when the file location changes to a value different from the file it is currently showing.
- **closes-preview-view-on-dismantle**: The component MUST release the native preview control's underlying preview-generation resources when the component is removed from the view hierarchy.

