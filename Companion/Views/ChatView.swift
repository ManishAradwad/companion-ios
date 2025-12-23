//
//  ChatView.swift
//  Companion
//
//  Chat interface with streaming AI responses
//

import MarkdownUI
import SwiftData
import SwiftUI
import UIKit

#if !targetEnvironment(simulator)
import MLX
import MLXLMCommon
#endif

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(DeviceStat.self) private var deviceStat
    
    @Bindable var llmService: LLMService
    
    @Query(sort: \ChatSession.lastMessageAt, order: .reverse)
    private var sessions: [ChatSession]
    
    @State private var prompt = ""
    @State private var currentSession: ChatSession?
    @State private var showModelInfo = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    /// Get the active session (most recent from today, or create new one)
    private var activeSession: ChatSession? {
        currentSession ?? sessions.first { Calendar.current.isDateInToday($0.createdAt) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Compact header with title, status, and actions
                compactHeader
                
                // Chat messages
                messageList
                
                // Input area
                MessageInputBar(
                    prompt: $prompt,
                    isRunning: llmService.running,
                    isModelLoaded: llmService.isLoaded,
                    onSend: sendMessage,
                    onCancel: { llmService.cancelGeneration() }
                )
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showModelInfo) {
                ModelInfoSheet(llmService: llmService, deviceStat: deviceStat)
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
                Button("Retry") {
                    Task { await loadModel() }
                }
            } message: {
                Text(errorMessage)
            }
            .task {
                // Pre-load model on launch
                await loadModel()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var compactHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            // Title and status
            VStack(alignment: .leading, spacing: 2) {
                Text("Companion")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Inline status indicator
                HStack(spacing: 4) {
                    if llmService.isLoading {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text(llmService.modelInfo)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else if llmService.isLoaded {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                        Text("Ready")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Circle()
                            .fill(.orange)
                            .frame(width: 6, height: 6)
                        Text("Not Loaded")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    if llmService.running && !llmService.stat.isEmpty {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(llmService.stat)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 16) {
                Button {
                    createNewSession()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.primary)
                }
                
                Button {
                    showModelInfo.toggle()
                } label: {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .top)
        }
    }
    
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if let session = activeSession {
                        ForEach(session.sortedMessages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        // Show streaming output
                        if llmService.running {
                            StreamingMessageBubble(
                                thinkingOutput: llmService.thinkingOutput,
                                responseOutput: llmService.responseOutput,
                                isThinking: llmService.isThinking
                            )
                            .id("streaming")
                        }
                    } else {
                        ContentUnavailableView(
                            "Start a Conversation",
                            systemImage: "bubble.left.and.bubble.right",
                            description: Text("Type a message below to begin chatting with your AI companion.")
                        )
                        .padding(.top, 100)
                    }
                }
                .padding()
                
                // Anchor for auto-scroll
                Color.clear
                    .frame(height: 1)
                    .id("bottom")
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: llmService.output) { _, _ in
                withAnimation {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: activeSession?.messages.count) { _, _ in
                withAnimation {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadModel() async {
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1"
        if isPreview { return }
        do {
            _ = try await llmService.load()
        } catch {
            errorMessage = "Failed to load AI model: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
    
    private func sendMessage() {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else { return }
        guard llmService.isLoaded else { return }
        
        // Get or create session
        let session: ChatSession
        if let active = activeSession, !active.isFrozen {
            session = active
        } else {
            session = ChatSession()
            modelContext.insert(session)
            currentSession = session
        }
        
        prompt = ""
        llmService.generate(prompt: trimmedPrompt, session: session, modelContext: modelContext)
    }
    
    private func createNewSession() {
        // Haptic feedback for new session
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        let session = ChatSession()
        modelContext.insert(session)
        currentSession = session
    }
    
    /// Set session from history navigation
    func setSession(_ session: ChatSession) {
        currentSession = session
    }
}

// MARK: - Thinking View

struct ThinkingView: View {
    let thinkingContent: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("Thinking...")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                Text(thinkingContent)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Streaming Message Bubble

struct StreamingMessageBubble: View {
    let thinkingOutput: String
    let responseOutput: String
    let isThinking: Bool
    
    @State private var isThinkingExpanded = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                // Show thinking section if we have thinking content or are currently thinking
                if !thinkingOutput.isEmpty || isThinking {
                    StreamingThinkingView(
                        thinkingContent: thinkingOutput,
                        isThinking: isThinking,
                        isExpanded: $isThinkingExpanded
                    )
                }
                
                // Show response section if we have response content
                if !responseOutput.isEmpty {
                    Markdown(responseOutput)
                        .textSelection(.enabled)
                        .padding(12)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text("Generating...")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer(minLength: 60)
        }
    }
}

// MARK: - Streaming Thinking View

struct StreamingThinkingView: View {
    let thinkingContent: String
    let isThinking: Bool
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 6) {
                        Text("Thinking...")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        if isThinking {
                            ProgressView()
                                .scaleEffect(0.6)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            
            if isExpanded && !thinkingContent.isEmpty {
                Text(thinkingContent)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    var content: String
    var isUser: Bool
    var thinkingContent: String?
    var isStreaming: Bool = false
    
    init(message: ChatMessage) {
        self.content = message.content
        self.isUser = message.isUser
        self.thinkingContent = message.thinkingContent
        self.isStreaming = false
    }
    
    init(content: String, isUser: Bool, thinkingContent: String? = nil, isStreaming: Bool = false) {
        self.content = content
        self.isUser = isUser
        self.thinkingContent = thinkingContent
        self.isStreaming = isStreaming
    }
    
    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
                if isUser {
                    Text(content)
                        .padding(12)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    // Show thinking section if present
                    if let thinking = thinkingContent, !thinking.isEmpty {
                        ThinkingView(thinkingContent: thinking)
                    }
                    
                    // Only show response bubble if there's content
                    if !content.isEmpty {
                        Markdown(content)
                            .textSelection(.enabled)
                            .padding(12)
                            .background(Color(.systemGray5))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            
            if !isUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Model Info Sheet

struct ModelInfoSheet: View {
    let llmService: LLMService
    let deviceStat: DeviceStat
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Model") {
                    LabeledContent("Name", value: llmService.modelConfiguration.name)
                    LabeledContent("Status", value: llmService.modelInfo)
                }
                
                Section("GPU Memory") {
                    LabeledContent("Active", value: (deviceStat.gpuUsage?.activeMemory ?? 0).formatted(.byteCount(style: .memory)))
                    LabeledContent("Cache", value: (deviceStat.gpuUsage?.cacheMemory ?? 0).formatted(.byteCount(style: .memory)))
                    LabeledContent("Peak", value: (deviceStat.gpuUsage?.peakMemory ?? 0).formatted(.byteCount(style: .memory)))
                    #if targetEnvironment(simulator)
                    LabeledContent("Limit", value: "N/A (Simulator)")
                    #else
                    LabeledContent("Limit", value: ((ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1") ? 0 : GPU.memoryLimit).formatted(.byteCount(style: .memory)))
                    #endif
                }
                
                if !llmService.stat.isEmpty {
                    Section("Performance") {
                        LabeledContent("Speed", value: llmService.stat)
                    }
                }
            }
            .navigationTitle("Model Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ChatView(llmService: LLMService())
        .modelContainer(for: [ChatSession.self, ChatMessage.self], inMemory: true)
        .environment(DeviceStat())
}
