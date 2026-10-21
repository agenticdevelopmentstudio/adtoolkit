import {
  Users,
  Mail,
  Flag,
  Boxes,
  ScrollText,
  MessageSquare,
  MessageCircle,
  Shield,
  Cable,
  FolderSync,
  Gauge,
  Receipt,
  ChartLine,
  ChartPie,
  KeyRound,
  Cpu,
  SlidersHorizontal,
  type LucideIcon,
} from "lucide-react";

// Named `adminTopics.ts`, not the bare `topics.ts` the admin site's old admin-shell.tsx would
// suggest: `abstractr` already has `topics`/`topics.tsx` claimed by three other feature packages
// (adh/help, adh-products, games) and blocks a fourth generic collision. The distinctive names
// this repo's newer topic-list modules use (registryTopics.tsx, entryTopics.tsx, heldTopics.ts,
// projectTopics.tsx) are the convention to follow going forward, not the older bare name.

/** The stable ids the admin console's sections have always used as route segments
 *  (`/users`, `/feature-flags`, …) — carried over unchanged from the site's own
 *  `admin-shell.tsx` (now this module) so no existing bookmark or link breaks. */
export type AdminTopicId =
  | "users"
  | "invitations"
  | "feature-flags"
  | "server-bags"
  | "sync"
  | "audit"
  | "messaging"
  | "feedback"
  | "authentication"
  | "llm-providers"
  | "usage"
  | "costs"
  | "usage-overview"
  | "breakdown"
  | "reserved-identifiers"
  | "ai-nodes"
  | "processing-configs";

/** One admin section. `id` doubles as the route segment, both on the admin site's own path
 *  scheme (`/<id>`) and on a host that mounts `AdminFeature` under `<basePath>/<id>`. */
export type AdminTopic = {
  id: AdminTopicId;
  label: string;
  description: string;
  icon: LucideIcon;
};

// The admin console's sections, in rail order. There is deliberately no "Dashboard" row: the
// bare landing IS the stack's topic overview (a card per section), so a Dashboard topic would
// only point back at the overview it lives on. Moved here verbatim from the admin site's
// admin-shell.tsx, which now imports this list rather than defining it.
export const ADMIN_TOPICS: AdminTopic[] = [
  { id: "users", label: "Users", description: "Manage accounts and roles", icon: Users },
  {
    id: "invitations",
    label: "Invitations",
    description: "Requests, pending, and sent invites",
    icon: Mail,
  },
  {
    id: "feature-flags",
    label: "Feature Flags",
    description: "Toggle platform features on and off",
    icon: Flag,
  },
  {
    id: "server-bags",
    label: "Server Bags",
    description: "Global key → JSON config values",
    icon: Boxes,
  },
  {
    id: "sync",
    label: "Sync Tables",
    description: "Per-ecosystem offline-sync table enrollment",
    icon: FolderSync,
  },
  { id: "audit", label: "Audit", description: "Access & role change history", icon: ScrollText },
  {
    id: "messaging",
    label: "Messaging",
    description: "Send and track messages",
    icon: MessageSquare,
  },
  {
    id: "feedback",
    label: "Feedback",
    description: "Review user submissions",
    icon: MessageCircle,
  },
  {
    id: "authentication",
    label: "Authentication",
    description: "Providers and access management",
    icon: Shield,
  },
  {
    id: "llm-providers",
    label: "LLM Providers",
    description: "Provider-template catalog personas connect to",
    icon: Cable,
  },
  {
    id: "usage",
    label: "Usage Limits",
    description: "Metering tiers and the enforcement switch",
    icon: Gauge,
  },
  {
    id: "costs",
    label: "Costs",
    description: "Run rate, cost items, and the prices behind them",
    icon: Receipt,
  },
  {
    id: "usage-overview",
    label: "Usage overview",
    description: "Platform traffic, time, tokens and direct cost over time",
    icon: ChartLine,
  },
  {
    id: "breakdown",
    label: "Breakdown",
    description: "Usage and cost per organization, ecosystem, user or persona",
    icon: ChartPie,
  },
  {
    id: "reserved-identifiers",
    label: "Reserved Identifiers",
    description: "Names held with nothing using them",
    icon: KeyRound,
  },
  {
    id: "ai-nodes",
    label: "AI Nodes",
    description: "Deployed processing nodes, their config and logs",
    icon: Cpu,
  },
  {
    id: "processing-configs",
    label: "Processing Configs",
    description: "LLM config sets that processing jobs run on",
    icon: SlidersHorizontal,
  },
];

const ADMIN_TOPIC_IDS: ReadonlySet<string> = new Set(ADMIN_TOPICS.map((t) => t.id));

/** Narrows an arbitrary URL segment (e.g. the hub's route param) to a known topic id. */
export function isAdminTopicId(id: string): id is AdminTopicId {
  return ADMIN_TOPIC_IDS.has(id);
}
