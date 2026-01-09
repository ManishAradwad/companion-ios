# Contributing to Companion iOS

Thank you for your interest in contributing to Companion iOS! This guide will help you get started, whether you're contributing code, documentation, or ideas.

## 🤖 AI-Powered Development

This project uses **Agent Skills** for AI-assisted development. We recommend using GitHub Copilot or compatible AI tools with our specialized skills:

- **@feature** - Scaffold complete features
- **@memory** - Build personalization features  
- **@prompts** - Design AI behavior
- **@test** - Generate comprehensive tests

See [`.github/AGENT_SKILLS_GUIDE.md`](.github/AGENT_SKILLS_GUIDE.md) for quick reference.

## 📋 Ways to Contribute

### 1. Feature Development

**Using AI Skills:**
```
@feature Create a weekly reflection summary feature that analyzes the past week's entries
```

**Manual Process:**
1. Check existing issues or create a new one using the [Feature Request template](.github/ISSUE_TEMPLATE/feature_request.md)
2. Follow architecture patterns in [copilot-instructions.md](.github/copilot-instructions.md)
3. Create models in `Companion/Models/`
4. Implement services in `Companion/Services/`
5. Build views in `Companion/Views/`
6. Add tests in `CompanionTests/`
7. Submit a PR using our [PR template](.github/pull_request_template.md)

### 2. Memory & Personalization

**Using AI Skills:**
```
@memory Implement location-based memory triggers - remember conversations that happened in specific places
```

The AI companion's memory system is a key differentiator. Contributions that improve:
- Fact extraction from conversations
- Memory relevance scoring
- User personality insights
- Context-aware memory retrieval

are highly valued!

### 3. Prompt Engineering

**Using AI Skills:**
```
@prompts Add a "mindfulness coach" conversation mode focused on meditation and presence
```

Help improve the AI's conversation quality:
- System prompt optimization
- Conversation mode design
- Response quality improvements
- Empathy and emotional intelligence

### 4. Testing

**Using AI Skills:**
```
@test Generate edge case tests for the memory retrieval system with various query patterns
```

We use Swift Testing framework:
- Tests run on iOS Simulator
- MLX code has stub implementations
- Aim for comprehensive coverage
- Test edge cases and error paths

### 5. Documentation

Improve documentation, guides, or examples:
- Architecture documentation
- Code examples
- User guides
- Developer tutorials

## 🏗️ Development Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/ManishAradwad/companion-ios.git
   cd companion-ios
   ```

2. **Open in Xcode**: 
   ```bash
   open Companion.xcodeproj
   ```

3. **Build and run**: `Cmd + R`

> First launch downloads ~2GB LLM model. Device builds recommended for LLM testing.

## 📐 Architecture Guidelines

### Code Style
- SwiftUI with `@Observable` (not ObservableObject)
- Async/await for all async operations
- MainActor for UI state updates
- Use MARK comments for organization
- Follow patterns in `copilot-instructions.md`

### File Organization
```
Companion/
├── Models/          # SwiftData models
├── Services/        # Business logic, LLM service
├── Views/           # SwiftUI views
│   └── Components/  # Reusable UI components
├── ViewModels/      # View-specific state
└── Resources/
    └── Prompts/     # LLM system prompts
```

### Testing
- Use Swift Testing framework (`@Test` macro)
- In-memory ModelContainer for model tests
- Mock services for integration tests
- Simulator-compatible (MLX stubs)

## 🔄 Pull Request Process

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following project patterns

3. **Write tests** for new functionality

4. **Run tests**:
   ```bash
   # In Xcode: Cmd + U
   ```

5. **Commit with clear messages**:
   ```bash
   git commit -m "Add mood tracking feature with emoji selection"
   ```

6. **Push and create PR**:
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Use PR template** and fill in all sections

8. **Respond to feedback** and make requested changes

## ✅ PR Checklist

- [ ] Code follows project patterns (see `copilot-instructions.md`)
- [ ] Tests added/updated for new functionality
- [ ] Tested on device (for LLM features) or simulator
- [ ] Documentation updated if needed
- [ ] Preview guards added for async operations
- [ ] Haptic feedback added for user interactions
- [ ] No SwiftUI preview crashes
- [ ] New models added to ModelContainer if needed

## 🐛 Bug Reports

Use the [Bug Report template](.github/ISSUE_TEMPLATE/bug_report.md) and include:
- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Device/simulator info
- Screenshots if UI-related

## 💡 Feature Requests

Use the [Feature Request template](.github/ISSUE_TEMPLATE/feature_request.md) and describe:
- User story and use case
- Acceptance criteria
- Memory layer impact (if applicable)
- Components needed

## 🎯 Quick Tasks for New Contributors

Good first issues:

1. **Haptic Feedback**: Add haptic feedback to buttons that don't have it
2. **UI Polish**: Improve spacing, colors, or animations
3. **Error Messages**: Better user-facing error messages
4. **Documentation**: Add code comments or examples
5. **Tests**: Increase test coverage for existing code

Use AI skills for efficiency:
```
@test Add comprehensive tests for the ChatMessage model
@feature Add a simple daily streak counter
```

## 📚 Resources

- **Project Guidelines**: [`.github/copilot-instructions.md`](.github/copilot-instructions.md)
- **Agent Skills Guide**: [`.github/AGENT_SKILLS_GUIDE.md`](.github/AGENT_SKILLS_GUIDE.md)
- **Skills Documentation**: [`.github/skills/README.md`](.github/skills/README.md)
- **SwiftUI Docs**: https://developer.apple.com/documentation/swiftui
- **SwiftData Docs**: https://developer.apple.com/documentation/swiftdata
- **MLX Swift**: https://github.com/ml-explore/mlx-swift

## 🤝 Code of Conduct

Be respectful, inclusive, and constructive:
- Respect differing viewpoints and experiences
- Accept constructive criticism gracefully
- Focus on what's best for the community
- Show empathy towards others

## 📬 Questions?

- Open a [Discussion](https://github.com/ManishAradwad/companion-ios/discussions)
- Check existing issues for similar questions
- Review project documentation first

## 🎉 Recognition

Contributors will be recognized in:
- GitHub contributor list
- Release notes for significant features
- Project acknowledgments

---

**Ready to contribute?** Pick an issue or create a feature request and let's build something amazing together! 🚀
