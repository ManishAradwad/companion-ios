# Quick Reference: Using Agent Skills

## What are Agent Skills?

Agent Skills is an open standard (from https://agentskills.io) that allows AI coding agents to discover and use specialized capabilities. Think of skills as expert AI assistants focused on specific tasks.

## Quick Start

### 1. Use Skills with GitHub Copilot

In any issue, PR, or chat with Copilot, mention a skill:

```
@feature Add a daily reflection prompt that appears every evening
```

### 2. Let Copilot Auto-Select

Describe what you want, and Copilot will choose the right skill:

```
Generate tests for the LLMService streaming generation logic
```
*(Copilot automatically uses @test)*

## Skill Cheat Sheet

| Skill | Use For | Example |
|-------|---------|---------|
| `@feature` | New features, UI, models | `@feature Add photo attachments to journal entries` |
| `@memory` | Personalization, facts | `@memory Extract user's sleep schedule from conversations` |
| `@prompts` | AI behavior, personality | `@prompts Add a "gratitude journal" conversation mode` |
| `@test` | Unit tests, mocks | `@test Test memory retrieval with various query types` |

## Common Workflows

### Adding a Complete Feature
```
@feature Create a tags system for categorizing journal entries:
- SwiftData model for tags
- Tag picker in message input
- Filter history by tags
- Tests for tag relationships
```

### Improving AI Quality
```
@prompts Update system prompt to:
- Ask more open-ended questions
- Avoid yes/no questions
- Use empathetic language
- Encourage deeper reflection
```

### Building Memory/Personalization
```
@memory Implement smart memory retrieval:
- Extract facts from last 7 days of conversations
- Score memory relevance to current topic
- Inject top 3 memories into LLM context
- Test with various conversation patterns
```

### Test Coverage
```
@test Generate comprehensive tests for:
- ChatMessage creation and validation
- Session management (freeze/continue logic)
- SwiftData relationships and cascade deletes
- Edge cases (empty messages, nil values)
```

## Combining Skills

Skills work together for complex tasks:

```
1. @feature Add mood tracking with emoji selection
2. @memory Extract mood patterns over time for insights
3. @prompts Use mood history in AI responses
4. @test Comprehensive test coverage for all components
```

Or let Copilot orchestrate:
```
Build a mood tracking feature with personalized insights.
The AI should recognize patterns and ask about mood changes.
Include full test coverage.
```

## Project-Specific Notes

- **Architecture**: SwiftUI + SwiftData + MLX (on-device LLM)
- **Testing**: Swift Testing framework, simulator-compatible
- **Guidelines**: See `.github/copilot-instructions.md`
- **Issues**: Use templates in `.github/ISSUE_TEMPLATE/`

## Learning More

- **Skill Docs**: [`.github/skills/README.md`](.github/skills/README.md)
- **Project Guidelines**: [`.github/copilot-instructions.md`](.github/copilot-instructions.md)
- **Agent Skills Standard**: https://agentskills.io
- **VS Code Docs**: https://code.visualstudio.com/docs/copilot/customization/agent-skills

## Troubleshooting

**Skill not working?**
- Ensure you're using `@skillname` syntax
- Check that GitHub Copilot is enabled
- Skills are auto-discovered from `.github/skills/` directory

**Custom workflow needed?**
- Skills are guidelines, not restrictions
- You can always give detailed instructions without using skills
- Skills help with common patterns and consistency

---

**Pro Tip**: Use skills for consistency, ignore them when you need custom behavior. They're tools to help, not rules to follow.
