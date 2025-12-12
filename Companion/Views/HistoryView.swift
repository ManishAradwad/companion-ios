//
//  HistoryView.swift
//  Companion
//
//  Chat history list with date grouping and swipe-to-delete
//

import SwiftData
import SwiftUI
import UIKit

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var llmService: LLMService
    @Binding var selectedTab: Int
    
    @Query(sort: \ChatSession.lastMessageAt, order: .reverse)
    private var sessions: [ChatSession]
    
    @State private var selectedSession: ChatSession?
    
    // MARK: - Cached Formatters
    
    /// Cached date formatter for month/year display (avoid repeated allocations)
    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    /// Cached date formatter for per-day section headers
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    /// Group sessions by exact calendar day (each day is its own section)
    private var groupedSessions: [(String, [ChatSession])] {
        let calendar = Calendar.current

        // Group sessions by the start of their calendar day so all sessions
        // on the same date appear in the same section.
        let groupedByDay = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.createdAt)
        }

        // Sort day keys newest-first and map to display strings.
        let sortedDays = groupedByDay.keys.sorted(by: >)

        return sortedDays.map { day in
            let sessionsForDay = (groupedByDay[day] ?? []).sorted { $0.lastMessageAt > $1.lastMessageAt }

            // Use relative labels for very recent days
            let header: String
            if calendar.isDateInToday(day) {
                header = "Today"
            } else if calendar.isDateInYesterday(day) {
                header = "Yesterday"
            } else {
                header = Self.dayFormatter.string(from: day)
            }

            return (header, sessionsForDay)
        }
    }
    
    @State private var isEditing = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Compact header
                historyHeader
                
                // Content
                if sessions.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "No Chat History",
                        systemImage: "clock",
                        description: Text("Start a conversation in the Chat tab to see your history here.")
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(groupedSessions, id: \.0) { section, sessionsInSection in
                            Section {
                                ForEach(sessionsInSection) { session in
                                    SessionRow(session: session)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            if !isEditing {
                                                selectSession(session)
                                            }
                                        }
                                }
                                .onDelete { indexSet in
                                    deleteSessions(at: indexSet, from: sessionsInSection)
                                }
                            } header: {
                                Text(section)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .environment(\.editMode, .constant(isEditing ? .active : .inactive))
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session, llmService: llmService)
            }
        }
    }
    
    private var historyHeader: some View {
        HStack(alignment: .center) {
            Text("History")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            if !sessions.isEmpty {
                Button {
                    withAnimation {
                        isEditing.toggle()
                    }
                } label: {
                    Text(isEditing ? "Done" : "Edit")
                        .font(.body)
                        .foregroundStyle(isEditing ? .blue : .secondary)
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
    
    // MARK: - Actions
    
    private func selectSession(_ session: ChatSession) {
        if session.isFrozen {
            // Open read-only detail view
            selectedSession = session
        } else {
            // Navigate to chat tab with this session
            // For now, just show the detail
            selectedSession = session
        }
    }
    
    private func deleteSessions(at offsets: IndexSet, from sessionsInSection: [ChatSession]) {
        // Haptic feedback for delete
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.warning)
        
        withAnimation {
            for index in offsets {
                let session = sessionsInSection[index]
                modelContext.delete(session)
            }
        }
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: ChatSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center) {
                Text(session.title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Spacer()
                
                if session.isFrozen {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            HStack(spacing: 6) {
                Text(session.lastMessageAt, style: .relative)
                Text("•")
                Text("\(session.messages.count) messages")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            if let lastMessage = session.sortedMessages.last {
                Text(lastMessage.content)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Session Detail View

struct SessionDetailView: View {
    let session: ChatSession
    let llmService: LLMService
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var prompt = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Session info bar
                if session.isFrozen {
                    HStack {
                        Image(systemName: "lock.fill")
                        Text("This conversation is read-only")
                        Spacer()
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .background(Color(.systemGray6))
                }
                
                // Messages
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(session.sortedMessages) { message in
                            MessageBubble(message: message)
                        }
                        
                        // Show streaming output for active sessions
                        if !session.isFrozen && llmService.running && !llmService.output.isEmpty {
                            MessageBubble(
                                content: llmService.output,
                                isUser: false,
                                isStreaming: true
                            )
                        }
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
                
                // Input area for non-frozen sessions
                if !session.isFrozen {
                    MessageInputBar(
                        prompt: $prompt,
                        isRunning: llmService.running,
                        isModelLoaded: llmService.isLoaded,
                        onSend: sendMessage,
                        onCancel: { llmService.cancelGeneration() }
                    )
                }
            }
            .navigationTitle(session.title)
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
    
    private func sendMessage() {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else { return }
        
        prompt = ""
        llmService.generate(prompt: trimmedPrompt, session: session, modelContext: modelContext)
    }
}

#Preview {
    HistoryView(llmService: LLMService(), selectedTab: .constant(1))
        .modelContainer(for: [ChatSession.self, ChatMessage.self], inMemory: true)
}
