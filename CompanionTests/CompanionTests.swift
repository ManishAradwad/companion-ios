//
//  CompanionTests.swift
//  CompanionTests
//
//  Created by Manish Aradwad on 12/16/25.
//
//  NOTE: These tests must be run on a PHYSICAL DEVICE, not the simulator.
//  The MLX framework requires Metal GPU which is not available on iOS Simulator.
//  Run with: xcodebuild test -project Companion.xcodeproj -scheme Companion -destination "platform=iOS,name=<YourDeviceName>"
//

import Testing
import SwiftData
import Foundation
@testable import Companion

// MARK: - ChatSession Tests

struct ChatSessionTests {
    
    @Test("New session has empty messages")
    func newSessionHasEmptyMessages() {
        let session = ChatSession()
        #expect(session.messages.isEmpty)
    }
    
    @Test("New session has default title")
    func newSessionHasDefaultTitle() {
        let session = ChatSession()
        #expect(session.title == "New Chat")
    }
    
    @Test("Session can be created with custom title")
    func sessionWithCustomTitle() {
        let session = ChatSession(title: "My Journal Entry")
        #expect(session.title == "My Journal Entry")
    }
    
    @Test("New session has valid UUID")
    func sessionHasValidUUID() {
        let session = ChatSession()
        #expect(session.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }
    
    @Test("New session created today is not frozen")
    func newSessionIsNotFrozen() {
        let session = ChatSession()
        #expect(!session.isFrozen)
    }
    
    @Test("Session created yesterday is frozen")
    func oldSessionIsFrozen() {
        let session = ChatSession()
        // Manually set createdAt to yesterday
        session.createdAt = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        #expect(session.isFrozen)
    }
    
    @Test("Sorted messages returns messages in chronological order")
    func sortedMessagesInOrder() {
        let session = ChatSession()
        
        let message1 = ChatMessage(content: "First", isUser: true, session: session)
        message1.timestamp = Date(timeIntervalSinceNow: -100)
        
        let message2 = ChatMessage(content: "Second", isUser: false, session: session)
        message2.timestamp = Date(timeIntervalSinceNow: -50)
        
        let message3 = ChatMessage(content: "Third", isUser: true, session: session)
        message3.timestamp = Date()
        
        session.messages = [message3, message1, message2]  // Add out of order
        
        let sorted = session.sortedMessages
        #expect(sorted[0].content == "First")
        #expect(sorted[1].content == "Second")
        #expect(sorted[2].content == "Third")
    }
    
    @Test("Update title from first user message - short message")
    func updateTitleShortMessage() {
        let session = ChatSession()
        let message = ChatMessage(content: "Hello world", isUser: true, session: session)
        session.messages = [message]
        
        session.updateTitleFromFirstMessage()
        
        #expect(session.title == "Hello world")
    }
    
    @Test("Update title from first user message - long message truncates")
    func updateTitleLongMessageTruncates() {
        let session = ChatSession()
        let longContent = "This is a very long message that should be truncated because it exceeds fifty characters"
        let message = ChatMessage(content: longContent, isUser: true, session: session)
        session.messages = [message]
        
        session.updateTitleFromFirstMessage()
        
        #expect(session.title.count <= 53)  // 50 chars + "..."
        #expect(session.title.hasSuffix("..."))
    }
    
    @Test("Update title skips assistant messages")
    func updateTitleSkipsAssistantMessages() {
        let session = ChatSession()
        let assistantMessage = ChatMessage(content: "I am an assistant", isUser: false, session: session)
        let userMessage = ChatMessage(content: "User question", isUser: true, session: session)
        session.messages = [assistantMessage, userMessage]
        
        session.updateTitleFromFirstMessage()
        
        #expect(session.title == "User question")
    }
}

// MARK: - ChatMessage Tests

struct ChatMessageTests {
    
    @Test("Message stores content correctly")
    func messageStoresContent() {
        let message = ChatMessage(content: "Test content", isUser: true)
        #expect(message.content == "Test content")
    }
    
    @Test("User message has isUser true")
    func userMessageFlag() {
        let message = ChatMessage(content: "Hello", isUser: true)
        #expect(message.isUser == true)
    }
    
    @Test("Assistant message has isUser false")
    func assistantMessageFlag() {
        let message = ChatMessage(content: "Hi there", isUser: false)
        #expect(message.isUser == false)
    }
    
    @Test("Message has valid UUID")
    func messageHasValidUUID() {
        let message = ChatMessage(content: "Test", isUser: true)
        #expect(message.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }
    
    @Test("Message timestamp is set on creation")
    func messageTimestampSet() {
        let before = Date()
        let message = ChatMessage(content: "Test", isUser: true)
        let after = Date()
        
        #expect(message.timestamp >= before)
        #expect(message.timestamp <= after)
    }
    
    @Test("Message can store thinking content")
    func messageWithThinkingContent() {
        let message = ChatMessage(
            content: "Response",
            isUser: false,
            thinkingContent: "Let me think about this..."
        )
        #expect(message.thinkingContent == "Let me think about this...")
    }
    
    @Test("Message thinking content is nil by default")
    func messageThinkingContentNilByDefault() {
        let message = ChatMessage(content: "Test", isUser: true)
        #expect(message.thinkingContent == nil)
    }
    
    @Test("Message can be associated with session")
    func messageWithSession() {
        let session = ChatSession()
        let message = ChatMessage(content: "Test", isUser: true, session: session)
        #expect(message.session === session)
    }
}

// MARK: - SwiftData Integration Tests

struct SwiftDataTests {
    
    @Test("Insert and fetch session")
    @MainActor
    func insertAndFetchSession() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: ChatSession.self, ChatMessage.self,
            configurations: config
        )
        let context = container.mainContext
        
        let session = ChatSession(title: "Test Session")
        context.insert(session)
        try context.save()
        
        let sessions = try context.fetch(FetchDescriptor<ChatSession>())
        #expect(sessions.count == 1)
        #expect(sessions.first?.title == "Test Session")
    }
    
    @Test("Insert message with session relationship")
    @MainActor
    func insertMessageWithSession() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: ChatSession.self, ChatMessage.self,
            configurations: config
        )
        let context = container.mainContext
        
        let session = ChatSession()
        context.insert(session)
        
        let message = ChatMessage(content: "Hello", isUser: true, session: session)
        context.insert(message)
        try context.save()
        
        let fetchedSession = try context.fetch(FetchDescriptor<ChatSession>()).first
        #expect(fetchedSession?.messages.count == 1)
        #expect(fetchedSession?.messages.first?.content == "Hello")
    }
    
    @Test("Cascade delete removes messages when session deleted")
    @MainActor
    func cascadeDeleteMessages() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: ChatSession.self, ChatMessage.self,
            configurations: config
        )
        let context = container.mainContext
        
        let session = ChatSession()
        context.insert(session)
        
        let message1 = ChatMessage(content: "Message 1", isUser: true, session: session)
        let message2 = ChatMessage(content: "Message 2", isUser: false, session: session)
        context.insert(message1)
        context.insert(message2)
        try context.save()
        
        // Verify messages exist
        var messages = try context.fetch(FetchDescriptor<ChatMessage>())
        #expect(messages.count == 2)
        
        // Delete session
        context.delete(session)
        try context.save()
        
        // Verify messages are deleted
        messages = try context.fetch(FetchDescriptor<ChatMessage>())
        #expect(messages.isEmpty)
    }
    
    @Test("Multiple sessions can be created")
    @MainActor
    func multipleSessions() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: ChatSession.self, ChatMessage.self,
            configurations: config
        )
        let context = container.mainContext
        
        for i in 1...5 {
            let session = ChatSession(title: "Session \(i)")
            context.insert(session)
        }
        try context.save()
        
        let sessions = try context.fetch(FetchDescriptor<ChatSession>())
        #expect(sessions.count == 5)
    }
}

// MARK: - LLMService State Tests

struct LLMServiceStateTests {
    
    @Test("LoadState idle is the initial expected state")
    func loadStateIdleIsInitial() {
        let state = LLMService.LoadState.idle
        #expect(state == .idle)
    }
    
    @Test("LoadState loading case exists")
    func loadStateLoadingExists() {
        let state = LLMService.LoadState.loading
        #expect(state == .loading)
    }
    
    @Test("LoadState loaded case exists")
    func loadStateLoadedExists() {
        let state = LLMService.LoadState.loaded
        #expect(state == .loaded)
    }
    
    @Test("LoadState failed case stores message")
    func loadStateFailedStoresMessage() {
        let state = LLMService.LoadState.failed("Test error")
        if case .failed(let message) = state {
            #expect(message == "Test error")
        } else {
            #expect(Bool(false), "Expected failed state")
        }
    }
    
    @Test("LLMService can be instantiated on simulator")
    @MainActor
    func serviceCanBeInstantiated() {
        let service = LLMService()
        #expect(service.loadState == .idle)
        #expect(!service.running)
        #expect(service.output.isEmpty)
    }
    
    @Test("LLMService isLoaded returns true on simulator")
    @MainActor
    func serviceIsLoadedOnSimulator() {
        let service = LLMService()
        // Simulator stub always reports as loaded
        #expect(service.isLoaded)
    }
    
    @Test("LLMService isLoading returns false when idle")
    @MainActor
    func serviceIsNotLoadingWhenIdle() {
        let service = LLMService()
        #expect(!service.isLoading)
    }
}

// MARK: - LLMServiceError Tests

struct LLMServiceErrorTests {
    
    @Test("alreadyLoading error has description")
    func alreadyLoadingErrorDescription() {
        let error = LLMServiceError.alreadyLoading
        #expect(error.errorDescription == "Model is already loading")
    }
    
    @Test("notLoaded error has description")
    func notLoadedErrorDescription() {
        let error = LLMServiceError.notLoaded
        #expect(error.errorDescription == "Model is not loaded")
    }
    
    @Test("Errors conform to LocalizedError")
    func errorsConformToLocalizedError() {
        let error: LocalizedError = LLMServiceError.alreadyLoading
        #expect(error.errorDescription != nil)
    }
}

// MARK: - Input Validation Tests

struct InputValidationTests {
    
    @Test("Empty string is invalid input", arguments: ["", "   ", "\n", "\t", "  \n  "])
    func emptyStringsAreInvalid(input: String) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(trimmed.isEmpty)
    }
    
    @Test("Non-empty string is valid input", arguments: ["Hello", "a", "Test message", "🎉"])
    func nonEmptyStringsAreValid(input: String) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(!trimmed.isEmpty)
    }
    
    @Test("Message content with only whitespace trims to empty")
    func whitespaceOnlyTrimsToEmpty() {
        let content = "   \n\t   "
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(trimmed.isEmpty)
    }
}

// MARK: - Date Grouping Tests (for HistoryView logic)

struct DateGroupingTests {
    
    @Test("Today's date is recognized as today")
    func todayIsToday() {
        let today = Date()
        #expect(Calendar.current.isDateInToday(today))
    }
    
    @Test("Yesterday's date is recognized as yesterday")
    func yesterdayIsYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        #expect(Calendar.current.isDateInYesterday(yesterday))
    }
    
    @Test("Sessions can be grouped by date")
    func sessionsGroupedByDate() {
        let calendar = Calendar.current
        
        let session1 = ChatSession(title: "Today 1")
        session1.createdAt = Date()
        
        let session2 = ChatSession(title: "Today 2")
        session2.createdAt = Date()
        
        let session3 = ChatSession(title: "Yesterday")
        session3.createdAt = calendar.date(byAdding: .day, value: -1, to: Date())!
        
        let sessions = [session1, session2, session3]
        
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.createdAt)
        }
        
        #expect(grouped.keys.count == 2)  // Two different days
    }
    
    @Test("Sessions sorted by lastMessageAt descending")
    func sessionsSortedByLastMessage() {
        let session1 = ChatSession(title: "Oldest")
        session1.lastMessageAt = Date(timeIntervalSinceNow: -3600)
        
        let session2 = ChatSession(title: "Middle")
        session2.lastMessageAt = Date(timeIntervalSinceNow: -1800)
        
        let session3 = ChatSession(title: "Newest")
        session3.lastMessageAt = Date()
        
        let sessions = [session1, session2, session3]
        let sorted = sessions.sorted { $0.lastMessageAt > $1.lastMessageAt }
        
        #expect(sorted[0].title == "Newest")
        #expect(sorted[1].title == "Middle")
        #expect(sorted[2].title == "Oldest")
    }
}
