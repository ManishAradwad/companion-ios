# companion-ios
LLM based journaling app with on-device AI

> 🤖 **AI-Powered Development**: This project uses [Agent Skills](https://agentskills.io) for automated development. See [`.github/skills/`](.github/skills/) for available AI agent capabilities.

## Getting Started

### Requirements
- A Mac computer (developed on MacBook M2 Air base version)
- Xcode — Apple's free software that lets you build and run apps on your iPhone or Mac
- An iOS device or the iOS Simulator

### Building & Installing

1. **Install Xcode**: Download and install [Xcode](https://apps.apple.com/app/xcode/id497799835) from the Mac App Store.

2. **Clone the repository**:
   ```bash
   git clone https://github.com/ManishAradwad/companion-ios.git
   cd companion-ios
   ```

3. **Open the project**: Double-click `Companion.xcodeproj` or open it from Xcode via **File → Open**.

4. **Select your target device**: In Xcode, click on the device dropdown at the top and choose either an iOS Simulator or your connected iPhone.

5. **Build and run**: Press `Cmd + R` or click the Play button to build and run the app.

> **Note**: On first launch, the app will download the LLM model (~2GB). Make sure you have a stable internet connection.

## 🤖 Contributing with AI Agents

This project is optimized for AI-assisted development using the Agent Skills standard. You can use GitHub Copilot or compatible AI tools with specialized skills:

### Available Skills

- **@feature** - Scaffold complete features with models, services, views, and tests
- **@memory** - Build memory/personalization features for the AI companion
- **@prompts** - Design and optimize LLM prompts and conversation modes
- **@test** - Generate comprehensive tests using Swift Testing framework

### Examples

```bash
# Ask Copilot to add a new feature
@feature Create a mood tracking feature with emoji selection and history view

# Update AI behavior
@prompts Make the AI more empathetic and ask better follow-up questions

# Generate tests
@test Create tests for the ChatSession model with full coverage
```

For detailed skill documentation, see [`.github/skills/README.md`](.github/skills/README.md).

### Development Guidelines

- All code follows patterns in [`.github/copilot-instructions.md`](.github/copilot-instructions.md)
- Use SwiftUI with `@Observable` (not ObservableObject)
- Async/await for all LLM operations
- Swift Testing framework for tests (run on simulator)
- See issue templates in [`.github/ISSUE_TEMPLATE/`](.github/ISSUE_TEMPLATE/) for structured task creation
