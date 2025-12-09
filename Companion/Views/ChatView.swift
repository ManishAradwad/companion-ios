//
//  ChatView.swift
//  Companion
//
//  Chat interface with streaming AI responses
//

import MarkdownUI
import MLX
import SwiftData
import SwiftUI
import MLXLMCommon
import UIKit

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
                // Model status bar
                modelStatusBar
                
                // Chat messages
                messageList
                
                // Input area
                MessageInputBar(
                    prompt: $prompt,
                    isRunning: llmService.running,
                    onSend: sendMessage,
                    onCancel: { llmService.cancelGeneration() }
                )
            }
            .navigationTitle("Companion")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        createNewSession()
                    } label: {
                        Image(systemName: "plus.bubble")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showModelInfo.toggle()
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
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
    
    private var modelStatusBar: some View {
        HStack {
            if llmService.isLoading {
                ProgressView(value: llmService.downloadProgress)
                    .progressViewStyle(.linear)
                    .frame(maxWidth: 150)
                Text(llmService.modelInfo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if llmService.isLoaded {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Model Ready")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.orange)
                Text("Model Not Loaded")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if llmService.running {
                ProgressView()
                    .scaleEffect(0.8)
                if !llmService.stat.isEmpty {
                    Text(llmService.stat)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
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
                        if llmService.running && !llmService.output.isEmpty {
                            MessageBubble(
                                content: llmService.output,
                                isUser: false,
                                isStreaming: true
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

// MARK: - Message Bubble

struct MessageBubble: View {
    var content: String
    var isUser: Bool
    var isStreaming: Bool = false
    
    init(message: ChatMessage) {
        self.content = message.content
        self.isUser = message.isUser
        self.isStreaming = false
    }
    
    init(content: String, isUser: Bool, isStreaming: Bool = false) {
        self.content = content
        self.isUser = isUser
        self.isStreaming = isStreaming
    }
    
    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                if isUser {
                    Text(content)
                        .padding(12)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    Markdown(content)
                        .textSelection(.enabled)
                        .padding(12)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                if isStreaming {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text("Generating...")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
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
                    LabeledContent("Limit", value: ((ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1") ? 0 : GPU.memoryLimit).formatted(.byteCount(style: .memory)))
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
