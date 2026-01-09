# Agent Skills Index

## 📁 Complete File Structure

```
.github/
├── skills/                           # Agent Skills definitions
│   ├── README.md                     # Skills documentation (5.1 KB)
│   ├── schema.json                   # JSON Schema for validation (4.9 KB)
│   ├── skills.json                   # Skills manifest (2.4 KB)
│   ├── feature.skill.json            # Feature scaffolding skill (2.7 KB)
│   ├── memory.skill.json             # Memory management skill (3.4 KB)
│   ├── prompts.skill.json            # Prompt engineering skill (3.9 KB)
│   └── test.skill.json               # Test generation skill (3.8 KB)
├── AGENT_SKILLS_GUIDE.md             # Quick reference (3.6 KB)
├── AGENT_SKILLS_WORKFLOWS.md         # Workflow examples (8.6 KB)
├── AGENT_SKILLS_IMPLEMENTATION.md    # Implementation summary (8.8 KB)
├── copilot-instructions.md           # Updated with skills reference
└── ...

.vscode/
└── settings.json                     # Copilot skills configuration (275 B)

CONTRIBUTING.md                        # Contribution guide with AI skills (6.6 KB)
README.md                              # Updated with AI-powered dev info
```

## 📚 Documentation Map

### For Developers

1. **Start Here**: [`README.md`](../README.md)
   - Project overview with AI skills mention
   - Quick start guide

2. **Quick Reference**: [`.github/AGENT_SKILLS_GUIDE.md`](.github/AGENT_SKILLS_GUIDE.md)
   - Skill cheat sheet
   - Common usage patterns
   - Troubleshooting

3. **Workflow Examples**: [`.github/AGENT_SKILLS_WORKFLOWS.md`](.github/AGENT_SKILLS_WORKFLOWS.md)
   - 5 complete workflow examples
   - Real-world scenarios
   - Pattern library

4. **Contributing**: [`CONTRIBUTING.md`](../CONTRIBUTING.md)
   - How to contribute with AI
   - Development setup
   - PR process

### For Understanding Skills

1. **Skills Overview**: [`.github/skills/README.md`](.github/skills/README.md)
   - Detailed skill descriptions
   - Usage examples
   - Design principles

2. **Implementation Details**: [`.github/AGENT_SKILLS_IMPLEMENTATION.md`](.github/AGENT_SKILLS_IMPLEMENTATION.md)
   - What was implemented
   - How it works
   - Architecture decisions

### For AI Agents

1. **Project Guidelines**: [`.github/copilot-instructions.md`](.github/copilot-instructions.md)
   - Complete project context
   - Code patterns
   - Architecture details

2. **Skill Definitions**: [`.github/skills/*.skill.json`](.github/skills/)
   - Machine-readable skills
   - Step-by-step instructions
   - Examples and patterns

## 🎯 Available Skills

| Skill | File | Purpose | Lines |
|-------|------|---------|-------|
| **feature** | `feature.skill.json` | End-to-end feature scaffolding | 75 |
| **memory** | `memory.skill.json` | Memory layer management | 92 |
| **prompts** | `prompts.skill.json` | LLM prompt engineering | 96 |
| **test** | `test.skill.json` | Test generation | 103 |

## 🚀 Quick Start

### Using Skills

```bash
# In GitHub Copilot Chat or compatible AI tool

# Feature development
@feature Create a daily streak counter with notifications

# Memory/Personalization
@memory Extract user's sleep schedule from conversations

# Prompt engineering
@prompts Add a "mindfulness coach" conversation mode

# Test generation
@test Generate tests for the ChatSession model
```

### Reading Documentation

1. **New to the project?** → Start with [`README.md`](../README.md)
2. **Want to contribute?** → Read [`CONTRIBUTING.md`](../CONTRIBUTING.md)
3. **Using AI for development?** → See [`.github/AGENT_SKILLS_GUIDE.md`](.github/AGENT_SKILLS_GUIDE.md)
4. **Need workflow examples?** → Check [`.github/AGENT_SKILLS_WORKFLOWS.md`](.github/AGENT_SKILLS_WORKFLOWS.md)
5. **Understanding implementation?** → Read [`.github/AGENT_SKILLS_IMPLEMENTATION.md`](.github/AGENT_SKILLS_IMPLEMENTATION.md)

## 📊 Statistics

- **Total Skills**: 4
- **Documentation Files**: 8
- **Total Lines of JSON**: 624 lines
- **Total Documentation**: ~1,800 lines
- **Total Size**: ~48 KB

## 🔗 External Resources

- **Agent Skills Standard**: https://agentskills.io
- **VS Code Copilot**: https://code.visualstudio.com/docs/copilot/customization/agent-skills
- **GitHub Copilot**: https://docs.github.com/copilot

## ✅ Validation

All files validated:
- ✅ JSON syntax valid
- ✅ Schema references correct
- ✅ Markdown linting passed
- ✅ File structure consistent

## 🔄 Maintenance

### To Update a Skill
1. Edit the skill JSON file in `.github/skills/`
2. Increment version number
3. Validate JSON: `python3 -m json.tool file.json`
4. Update `skills.json` if needed
5. Commit and push

### To Add a Skill
1. Create `new-skill.skill.json` following `schema.json`
2. Add entry to `skills.json` manifest
3. Document in `.github/skills/README.md`
4. Add examples to `AGENT_SKILLS_WORKFLOWS.md`
5. Test with GitHub Copilot

## 📝 Notes

- All skills follow the Agent Skills v1.0 standard
- Skills are designed specifically for Companion iOS architecture
- Skills reference project patterns from `copilot-instructions.md`
- VSCode settings enable automatic skill discovery

---

**Last Updated**: January 2025  
**Standard**: Agent Skills v1.0  
**Compatibility**: GitHub Copilot, VS Code, Claude
