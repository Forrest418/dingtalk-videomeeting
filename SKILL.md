---
name: dingtalk-videomeeting
description: 钉钉视频会议技能（创建预约视频会议）。当用户提到“视频会议/预约会议/开会链接/会议预约”时使用。技能通过视频会议 MCP 调用工具；用户只需在技能目录维护 mcporter.json。
homepage: https://mcp.dingtalk.com
metadata:
  openclaw:
    emoji: "🎥"
    requires:
      bins: ["mcporter", "jq"]
---

# DingTalk Video Meeting

Use this skill to:

- Create future scheduled video meetings

## User-Maintained Config (Only)

Users only need to maintain `mcporter.json` in skill root.

## Execution Policy

- Always call via `scripts/mcp.sh`.
- Run `scripts/preflight.sh` before first use.
- Current deployment is write-only (`create_meeting_reservation`). Ask user confirmation before executing create.

## Common Workflows

### 1) Create scheduled meeting

```bash
scripts/create_meeting.sh --title "项目周会" --start "2026-03-06T10:00:00+08:00" --end "2026-03-06T11:00:00+08:00"
```

## References

- Config setup: `references/configuration.md`
- Tool discovery: `references/tool-discovery.md`
