# Companion iOS - AI Coding Agent Guidelines

## Project Overview
**Companion** is an iOS app for on-device AI-powered journaling/assistant features, built with SwiftUI, SwiftData, and MLX for local LLM inference.

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
├── ViewModels/
│   └── DeviceStat.swift        # GPU memory tracking utility
├── Views/
│   ├── MainTabView.swift       # Tab-based navigation (Chat + History)
│   ├── ChatView.swift          # Chat interface with streaming responses
│   └── HistoryView.swift       # Session history with date grouping
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

## Code Style
- SwiftUI with `@Observable` (not ObservableObject)
- Async/await for all LLM operations
- MainActor for UI state updates during streaming
- Prefer `Task { @MainActor in }` for cross-actor updates
- Use `@Bindable` for two-way binding with Observable classes
