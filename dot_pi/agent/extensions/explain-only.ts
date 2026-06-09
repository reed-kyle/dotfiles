import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const ALLOWED_TOOLS = new Set(["read", "grep", "find", "ls", "nvim_context"]);

const GUARD_MESSAGE = `I started producing implementation-like content, which is disabled in explain-only tutor mode.

I can still help by explaining the existing code, relevant patterns/files, tradeoffs, edge cases, or a high-level checklist for you to use while handwriting your own solution.`;

function textFromContent(content: unknown): string {
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";
  return content
    .map((block: any) => {
      if (block?.type === "text") return block.text ?? "";
      return "";
    })
    .join("\n");
}

function hasAllowedCitationNear(text: string, index: number): boolean {
  const before = text.slice(Math.max(0, index - 240), index);

  // Accept code fences only when the surrounding prose looks like it is quoting
  // an existing repository excerpt with a path and line reference.
  const hasPath = /(?:^|[\s`])(?:\.?\.?\/)?[\w.-]+(?:\/[\w.@-]+)+(?:\.[A-Za-z0-9]+)?(?:[\s`,:)]|$)/m.test(before);
  const hasLineRef = /\b(?:line|lines|L)\s*\d+(?:\s*[-–]\s*\d+)?\b/i.test(before);
  const saysExcerpt = /\b(?:excerpt|existing|from|quoted?|currently)\b/i.test(before);

  return hasPath && hasLineRef && saysExcerpt;
}

function hasDisallowedFence(text: string): boolean {
  const fence = /```/g;
  let match: RegExpExecArray | null;
  while ((match = fence.exec(text)) !== null) {
    if (!hasAllowedCitationNear(text, match.index)) return true;

    const close = text.indexOf("```", match.index + 3);
    if (close === -1) return true;

    const block = text.slice(match.index + 3, close);
    const codeLines = block.split("\n").filter((line) => line.trim().length > 0);
    if (codeLines.length > 30) return true;

    fence.lastIndex = close + 3;
  }
  return false;
}

function looksLikeGeneratedCode(text: string): boolean {
  const suspiciousPatterns = [
    /^\s*diff --git\b/m,
    /^\s*---\s+\S+/m,
    /^\s*\+\+\+\s+\S+/m,
    /^\s*@@\s/m,
    /\bhere(?:'s| is) (?:the|an?) (?:implementation|patch|diff|replacement|version)\b/i,
    /\b(?:replace|change) (?:it|this|that|the .*?) with\b/i,
    /\badd (?:this|the following) (?:code|test|file|implementation)\b/i,
    /\bcopy(?: and)? paste\b/i,
    /\bnew file:\s*\S+/i,
    /^\s*(?:export\s+)?(?:async\s+)?function\s+[A-Za-z_$][\w$]*\s*\(/m,
    /^\s*(?:export\s+)?class\s+[A-Za-z_$][\w$]*/m,
    /^\s*(?:const|let|var)\s+[A-Za-z_$][\w$]*\s*=\s*(?:async\s*)?\(/m,
    /^\s*(?:describe|it|test)\s*\(/m,
    /^\s*(?:npm|yarn|pnpm|npx|git|nx)\s+[\w:-]+/m,
  ];

  return suspiciousPatterns.some((pattern) => pattern.test(text));
}

function violatesExplainOnlyPolicy(text: string): boolean {
  return hasDisallowedFence(text) || looksLikeGeneratedCode(text);
}

export default function explainOnly(pi: ExtensionAPI) {
  function enforceTools() {
    const availableAllowedTools = pi
      .getAllTools()
      .map((tool) => tool.name)
      .filter((name) => ALLOWED_TOOLS.has(name));

    pi.setActiveTools(availableAllowedTools);
  }

  pi.on("session_start", async (_event, ctx) => {
    enforceTools();
    ctx.ui.setStatus("explain-only", "explain-only");
  });

  pi.on("resources_discover", async () => {
    enforceTools();
  });

  pi.on("tool_call", async (event) => {
    if (!ALLOWED_TOOLS.has(event.toolName)) {
      return {
        block: true,
        reason: `Explain-only mode allows only read/search/list tools. Blocked: ${event.toolName}`,
      };
    }
  });

  pi.on("before_agent_start", async (event) => {
    enforceTools();
    return {
      systemPrompt:
        event.systemPrompt +
        `\n\nExplain-only enforcement reminder: do not author new project code, diffs, patches, tests, shell commands, or copy-pasteable implementation. Quote existing code only as a short cited excerpt with file path and line reference.`,
    };
  });

  pi.on("message_end", async (event) => {
    if (event.message.role !== "assistant") return;

    const text = textFromContent(event.message.content);
    if (!violatesExplainOnlyPolicy(text)) return;

    return {
      message: {
        ...event.message,
        content: [{ type: "text", text: GUARD_MESSAGE }],
        stopReason: "stop",
      },
    };
  });
}
