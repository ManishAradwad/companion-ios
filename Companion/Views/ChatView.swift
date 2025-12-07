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
    
    @Bindable var serviceManager: LLMServiceManager
    
    private var llmService: any LLMServiceProtocol {
        serviceManager.currentService
    }
    
    @Query(sort: \ChatSession.lastMessageAt, order: .reverse)
    private var sessions: [ChatSession]
    
    @State private var prompt = ""
    @State private var currentSession: ChatSession?
    @State private var showModelInfo = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showAPIKeySheet = false
    @State private var apiKeyInput = ""
    
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
                    Menu {
                        Picker("Model", selection: $serviceManager.currentServiceType) {
                            ForEach(LLMServiceManager.ServiceType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        
                        if serviceManager.currentServiceType == .cloud {
                            Button("Set API Key") {
                                showAPIKeyAlert()
                            }
                        }
                    } label: {
                        Label("Settings", systemImage: "ellipsis.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        createNewSession()
                    } label: {
                        Label("New Chat", systemImage: "plus.bubble")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showModelInfo.toggle()
                    } label: {
                        Label("Model Info", systemImage: "info.circle")
                    }
                }
            }
            .sheet(isPresented: $showModelInfo) {
                ModelInfoSheet(serviceManager: serviceManager, deviceStat: deviceStat)
            }
            .sheet(isPresented: $showAPIKeySheet) {
                APIKeySheet(apiKeyInput: $apiKeyInput, onSave: {
                    serviceManager.setCloudAPIKey(apiKeyInput)
                    showAPIKeySheet = false
                })
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
    
    private func showAPIKeyAlert() {
        apiKeyInput = UserDefaults.standard.string(forKey: "cloudAPIKey") ?? ""
        showAPIKeySheet = true
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
    let serviceManager: LLMServiceManager
    let deviceStat: DeviceStat
    
    @Environment(\.dismiss) private var dismiss
    
    private var llmService: any LLMServiceProtocol {
        serviceManager.currentService
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Service Type") {
                    LabeledContent("Active", value: serviceManager.currentServiceType.rawValue)
                }
                
                Section("Model") {
                    if serviceManager.currentServiceType == .onDevice {
                        LabeledContent("Name", value: serviceManager.onDeviceService.modelConfiguration.name)
                    } else {
                        LabeledContent("Name", value: "Cloud GPT-4")
                    }
                    LabeledContent("Status", value: llmService.modelInfo)
                }
                
                if serviceManager.currentServiceType == .onDevice {
                    Section("GPU Memory") {
                        LabeledContent("Active", value: deviceStat.gpuUsage.activeMemory.formatted(.byteCount(style: .memory)))
                        LabeledContent("Cache", value: deviceStat.gpuUsage.cacheMemory.formatted(.byteCount(style: .memory)))
                        LabeledContent("Peak", value: deviceStat.gpuUsage.peakMemory.formatted(.byteCount(style: .memory)))
                        LabeledContent("Limit", value: GPU.memoryLimit.formatted(.byteCount(style: .memory)))
                    }
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

// MARK: - API Key Sheet

struct APIKeySheet: View {
    @Binding var apiKeyInput: String
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Enter your OpenAI API Key", text: $apiKeyInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("API Key")
                } footer: {
                    Text("Your API key is stored securely on your device and is only used to make requests to the cloud service.")
                }
            }
            .navigationTitle("Cloud API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    ChatView(serviceManager: LLMServiceManager())
        .modelContainer(for: [ChatSession.self, ChatMessage.self], inMemory: true)
        .environment(DeviceStat())
}
