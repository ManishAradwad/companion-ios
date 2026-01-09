# Companion iOS Agent Skills

This directory contains [Agent Skills](https://agentskills.io) for the Companion iOS project. Agent Skills is an open standard created by Anthropic for defining reusable AI agent capabilities.

## 📋 Available Skills

### 🚀 Feature (`feature.skill.json`)
**End-to-end feature scaffolding for Companion iOS**

Creates complete features including models, services, views, components, and tests following the project's architecture patterns.

**Use when:**
- Adding new user-facing features
- Creating new data models and associated UI
- Building integrated components that span multiple layers

**Example invocation:**
```
@feature Create a mood tracking feature where users can log their mood with emoji and view mood history over time
```

---

### 🧠 Memory (`memory.skill.json`)
**Build and manage the memory layer**

Handles user insights, fact extraction from conversations, memory storage, and retrieval for personalized AI responses.

**Use when:**
- Implementing user memory/personalization features
- Extracting structured facts from conversations
- Building memory retrieval for LLM context
- Creating user personality profiles

**Example invocation:**
```
@memory Implement fact extraction to remember user's favorite foods, hobbies, and work details from conversations
```

---

### 💬 Prompts (`prompts.skill.json`)
**Craft and manage LLM prompts**

Handles system prompt design, memory context injection, conversation mode management, and prompt optimization.

**Use when:**
- Updating the AI's personality or behavior
- Adding memory context to prompts
- Creating different conversation modes (friend, coach, therapist)
- Optimizing prompt quality and token usage

**Example invocation:**
```
@prompts Update the system prompt to make the AI ask more reflective questions about the user's day
```

---

### ✅ Test (`test.skill.json`)
**Generate and run unit tests**

Creates comprehensive tests using Swift Testing framework with simulator support and MLX stubs.

**Use when:**
- Adding tests for new features
- Testing models, services, or views
- Creating mock dependencies
- Validating edge cases

**Example invocation:**
```
@test Generate tests for the ChatSession model including relationships and cascade delete behavior
```

## 🎯 How to Use Agent Skills

### With GitHub Copilot

1. **Direct Invocation**: Mention the skill name in your prompt
   ```
   @feature Add a tags system for organizing journal entries
   ```

2. **Auto-selection**: Let Copilot automatically select the right skill
   ```
   Create tests for the LLMService class
   ```
   *(Copilot will automatically use @test)*

### With Compatible AI Agents

Agent Skills are an open standard supported by various AI coding tools:
- GitHub Copilot Workspace
- VS Code Copilot
- Claude for Enterprise
- Other tools implementing the agentskills.io standard

## 📁 Skill Structure

Each skill follows the Agent Skills JSON schema:

```json
{
  "$schema": "./schema.json",
  "name": "skill-name",
  "version": "1.0.0",
  "description": "What the skill does",
  "parameters": { ... },
  "capabilities": [ ... ],
  "instructions": { ... },
  "dependencies": { ... },
  "examples": [ ... ]
}
```

**Note**: Skills reference a local `schema.json` that follows the Agent Skills v1.0 standard. This provides:
- Offline validation capability
- Project-specific schema extensions
- Version-controlled schema definitions

The local schema is fully compatible with the official Agent Skills standard.

## 🔗 Related Documentation

- **Project Guidelines**: [`../.github/copilot-instructions.md`](../copilot-instructions.md)
- **Skills Manifest**: [`skills.json`](./skills.json)
- **Agent Skills Standard**: https://agentskills.io
- **VS Code Documentation**: https://code.visualstudio.com/docs/copilot/customization/agent-skills

## 🛠️ Developing New Skills

To add a new skill:

1. Create `{skill-name}.skill.json` in this directory
2. Follow the Agent Skills JSON schema
3. Add skill metadata to `skills.json`
4. Document the skill in this README
5. Test with GitHub Copilot or compatible tools

### Skill Design Principles

- **Focused**: Each skill should have a clear, specific purpose
- **Discoverable**: Use descriptive names and comprehensive descriptions
- **Documented**: Include examples and clear instructions
- **Project-aware**: Reference project-specific patterns and conventions
- **Composable**: Skills should work well together for complex tasks

## 📊 Skill Dependencies

Skills may reference each other for complex workflows:

- `feature` → `test` (features include test generation)
- `memory` → `prompts` (memory features need prompt updates)
- `prompts` → `memory` (prompts may inject memory context)

## 🔄 Version History

- **v1.0.0** (2025-01): Initial implementation of Agent Skills standard
  - Converted existing custom agents to Agent Skills format
  - Added skills manifest and documentation
  - Established project-wide skill conventions

## 📝 Notes

- All skills are designed specifically for Companion iOS architecture
- Skills follow SwiftUI + SwiftData + MLX patterns
- Tests use Swift Testing framework and run on iOS Simulator
- MLX code requires device builds but has simulator stubs for testing
- Skills automatically reference project guidelines from `copilot-instructions.md`

---

**Questions or Issues?** See project documentation or open an issue in the repository.
