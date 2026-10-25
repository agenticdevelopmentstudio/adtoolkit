// Components
export { InlineChat, InlineChatView } from './modes/InlineChat'
export type {
  InlineChatSizing,
  ChatSizingBehavior,
  InactiveSizingBehavior,
  SizingTransition,
} from './modes/InlineChat'
// The marker for a control a host parks beside an inline chat, so a press on it is
// not a tap away that folds the chat — see useChatSizing.
export { CHAT_INSIDE_ATTR } from './hooks/useChatSizing'
export { ThreePaneChat, ThreePaneChatView } from './modes/ThreePaneChat'
export { MobileChat, MobileChatView } from './modes/MobileChat'
export { PersonaChat } from './modes/PersonaChat'
export { Transcript } from './components/Transcript'
export { TypingIndicator } from './components/TypingIndicator'
export type { StatusWordPair, StatusTintSpec, TypingIndicatorProps } from './components/TypingIndicator'
export { ContentOverlay } from './components/ContentOverlay'
export type { ContentOverlayProps } from './components/ContentOverlay'
export { RegistryMark } from './components/RegistryMark'
export type { RegistryMarkProps } from './components/RegistryMark'
export { ProfileInfoButton } from './components/ProfileInfoButton'
export type { ProfileInfoButtonProps } from './components/ProfileInfoButton'

// Backends
export { MockBackend } from './backends/MockBackend'
export { FetchBackend } from './backends/FetchBackend'
export type { ChatBackend } from './backends/types'

// Types
export type {
  ChatParticipant,
  ChatMessage,
  ChatResponse,
  ChatStreamEvent,
  ToolCallInfo,
  ContentItem,
  LinkContent,
  ImageContent,
  PopoverData,
  ChatMode,
} from './types'

// Hooks (for advanced usage)
export { useChatSession } from './hooks/useChatSession'
export type { ChatSession } from './hooks/useChatSession'

// Persona-chat mechanism — caret tracking, focus, mood, and the connect ritual.
// Persona-agnostic: all vocabulary is caller-supplied.
export {
  caretMetrics,
  useCaretTracker,
  CHAT_INPUT_SELECTOR,
} from './hooks/useCaretTracker'
export type { CaretMetrics } from './hooks/useCaretTracker'
export { submitChatInput } from './components/ChatInput'
export { useInputFocusReclaim } from './hooks/useInputFocusReclaim'
export { useBlockCursor } from './hooks/useBlockCursor'
export { useCaretGaze } from './hooks/useCaretGaze'
export type { GazeVector, CaretGazeOptions } from './hooks/useCaretGaze'
export { useMouseGaze } from './hooks/useMouseGaze'
export { usePersonaGaze } from './hooks/usePersonaGaze'
export { usePersonaMood } from './hooks/usePersonaMood'
export type { PersonaMood, PersonaMoodConfig } from './hooks/usePersonaMood'
export { useConnectRitual } from './hooks/useConnectRitual'
export type { ConnectRitualConfig, ConnectRitualState } from './hooks/useConnectRitual'
export { useRotatingPhrase, useTransientEcho } from './hooks/useRotatingPhrase'
export { ShuffleBag, streamTokens } from './backends/ShuffleBag'
export type { StreamTokensOptions } from './backends/ShuffleBag'

// Cross-platform chat contract (mirrors apple/AgenticDeveloperToolkit/Sources/).
export type * from './contract'

// Reference TS implementations of the cross-platform contract.
export { DefaultOrchestrator, ScriptedBackend, InMemoryPermissionStore } from './runtime'
export type { SentRecord } from './runtime'
