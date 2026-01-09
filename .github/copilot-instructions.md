# Companion iOS - AI Coding Agent Guidelines

## Project Overview
**Companion** is an early-stage iOS app for on-device AI-powered journaling/assistant features, built with SwiftUI, SwiftData, and MLX for local LLM inference. I want this app to be used by user for keeping track of their life in general. It can be a friend which they can talk to about anything and everything. I want this app to also store a `personality` of the user, it can help the users to learn more about themselves over time.

## 🎯 Agent Skills
This project implements the [Agent Skills standard](https://agentskills.io) for AI-powered development. Specialized skills are available for common tasks:

- **@feature** - End-to-end feature scaffolding (models + services + views + tests)
- **@memory** - Memory layer management (fact extraction, retrieval, personalization)
- **@prompts** - LLM prompt engineering (system prompts, modes, optimization)
- **@test** - Test generation with Swift Testing framework

See [`.github/skills/README.md`](.github/skills/README.md) for detailed skill documentation and usage examples. 

## Current Architecture

### File Structure
```
Companion/
├── CompanionApp.swift          # App entry point with SwiftData ModelContainer
├── Companion.entitlements      # Memory limit + network entitlements
├── Models/
│   ├── ChatSession.swift       # SwiftData model for chat sessions
│   └── ChatMessage.swift       # SwiftData model for messages
├── Services/
│   └── LLMService.swift        # LLM loading, generation, session management
├── Resources/
│   └── Prompts/
│       └── system_prompt.txt   # Configurable system prompt
├── ViewModels/
│   └── DeviceStat.swift        # GPU memory tracking utility
├── Views/
│   ├── MainTabView.swift       # Tab-based navigation (Chat + History)
│   ├── ChatView.swift          # Chat interface with streaming responses
│   ├── HistoryView.swift       # Session history with date grouping
│   └── Components/
│       └── MessageInputBar.swift  # Reusable message input component
└── Assets.xcassets/
```

### Two-Tab Interface
- **Chat Tab** (default): Active chat session with message input, streaming AI responses, model status bar
- **History Tab**: Lists all chat sessions grouped by date, swipe-to-delete, session detail view

### SwiftData Models
- **ChatSession**: id, createdAt, lastMessageAt, title, messages relationship, computed `isFrozen` property
- **ChatMessage**: id, content, isUser (boolean), timestamp, session relationship
- Cascade delete: Deleting a session removes all its messages

## MLX LLM Patterns

### Type Aliases (avoid SwiftData/MLXLMCommon conflicts)
```swift
typealias LLMModelContext = MLXLMCommon.ModelContext
typealias LLMModelContainer = MLXLMCommon.ModelContainer
typealias DataModelContext = SwiftData.ModelContext
```

### Model Loading
```swift
let modelConfiguration = LLMRegistry.qwen3_1_7b_4bit
MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)
let container = try await LLMModelFactory.shared.loadContainer(configuration: modelConfiguration)
```

### Streaming Generation
```swift
let stream = try MLXLMCommon.generate(input: lmInput, parameters: generateParameters, context: context)
for await batch in stream._throttle(for: .seconds(0.25), reducing: Generation.collect) {
    let output = batch.compactMap { $0.chunk }.joined()
    Task { @MainActor in self.output += output }
}
```

### Load State Pattern
```swift
enum LoadState {
    case idle
    case loading
    case loaded(LLMModelContainer)
    case failed(Error)
}
```

## Required Entitlements
Located in `Companion/Companion.entitlements`:
- `com.apple.developer.kernel.increased-memory-limit` — Required for LLM weights
- `com.apple.security.network.client` — For HuggingFace model downloads

## Swift Package Dependencies
- `mlx-swift` (0.29.x) — MLX framework
- `mlx-swift-lm` (2.29.x) — MLXLLM, MLXLMCommon libraries
- `swift-async-algorithms` — For `_throttle` on async streams
- `swift-markdown-ui` (2.4.x) — For rendering markdown in chat bubbles

## Build & Debug Notes
- **Minimum iOS**: 17.0 (required for SwiftData and @Observable)
- **Swift 5** language version
- **Xcode 26.0.1** on macOS 26 (2025 release)
- **Release builds** recommended for large models (avoids stack overflow in Debug)
- Disable debugger for performance: `cmd+opt+r` → uncheck "Debug Executable"
- First launch downloads model (~2GB) - progress shown in UI
- **Simulator**: App uses conditional compilation (`#if targetEnvironment(simulator)`) to provide stub implementations for MLX-dependent code. The app runs on simulator but LLM features are stubbed.
- **Tests run on Simulator**: Tests use Swift Testing framework and run on iOS Simulator via stub implementations

## Code Style
- SwiftUI with `@Observable` (not ObservableObject)
- Async/await for all LLM operations
- MainActor for UI state updates during streaming
- Prefer `Task { @MainActor in }` for cross-actor updates
- Use `@Bindable` for two-way binding with Observable classes

### Preview Mode Detection
Always guard async operations in previews to avoid crashes:
```swift
let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" 
    || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1"
if isPreview { return }
```

### MARK Section Organization
Organize files with consistent MARK comments:
```swift
// MARK: - State
// MARK: - Load State
// MARK: - Computed Properties
// MARK: - Model Loading
// MARK: - Generation
// MARK: - Subviews
// MARK: - Actions
// MARK: - Cached Formatters
```

### Cached Formatters
DateFormatters are expensive—cache them as static properties:
```swift
private static let dayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()
```

### Haptic Feedback
Use haptics for user interactions:
```swift
// Light tap feedback
UIImpactFeedbackGenerator(style: .light).impactOccurred()

// Success/warning notifications
UINotificationFeedbackGenerator().notificationOccurred(.success)
UINotificationFeedbackGenerator().notificationOccurred(.warning)
```

### Error Handling Pattern
Use `LocalizedError` for custom errors with user-facing messages:
```swift
enum LLMServiceError: LocalizedError {
    case alreadyLoading
    case modelNotLoaded
    
    var errorDescription: String? {
        switch self {
        case .alreadyLoading: return "Model is already loading"
        case .modelNotLoaded: return "Model not loaded"
        }
    }
}
```

### SwiftUI View Structure
Follow this structure for new views:
```swift
struct MyView: View {
    // Environment properties
    @Environment(\.modelContext) private var modelContext
    
    // Bindable services
    @Bindable var llmService: LLMService
    
    // Query properties
    @Query(sort: \ChatSession.lastMessageAt, order: .reverse)
    private var sessions: [ChatSession]
    
    // Local state
    @State private var myState = ""
    
    // Computed properties
    private var computedValue: String { ... }
    
    var body: some View { ... }
    
    // MARK: - Subviews
    private var mySubview: some View { ... }
    
    // MARK: - Actions
    private func myAction() { ... }
}

#Preview {
    MyView(llmService: LLMService())
        .modelContainer(for: [ChatSession.self, ChatMessage.self], inMemory: true)
}
```
