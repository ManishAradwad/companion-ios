//
//  MainTabView.swift
//  Companion
//
//  Main tab-based navigation for Chat and History tabs
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var llmService = LLMService()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ChatView(llmService: llmService)
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(0)
            
            MemoryListView()
                .tabItem {
                    Label("Memories", systemImage: "brain.head.profile")
                }
                .tag(1)
            
            HistoryView(llmService: llmService, selectedTab: $selectedTab)
                .tabItem {
                    Label("History", systemImage: "clock")
                }
                .tag(2)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [ChatSession.self, ChatMessage.self, Memory.self], inMemory: true)
        .environment(DeviceStat())
}
