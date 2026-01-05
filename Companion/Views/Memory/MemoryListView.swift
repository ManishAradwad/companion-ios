//
//  MemoryListView.swift
//  Companion
//
//  View for browsing and managing all stored memories
//

import SwiftUI
import SwiftData

struct MemoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var memoryService = MemoryService()
    @State private var selectedType: MemoryType? = nil
    @State private var showingAddMemory = false
    @State private var searchText = ""
    
    @Query(sort: \Memory.createdAt, order: .reverse)
    private var allMemories: [Memory]
    
    // MARK: - Computed Properties
    
    private var filteredMemories: [Memory] {
        var memories = allMemories
        
        // Filter by type if selected
        if let selectedType = selectedType {
            memories = memories.filter { $0.type == selectedType }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            memories = memories.filter { memory in
                memory.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Only show active memories
        return memories.filter { $0.isActive }
    }
    
    private var memoryCountByType: [MemoryType: Int] {
        Dictionary(grouping: allMemories.filter { $0.isActive }) { $0.type }
            .mapValues { $0.count }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Type filter
                typeFilterBar
                
                if filteredMemories.isEmpty {
                    emptyStateView
                } else {
                    memoryList
                }
            }
            .navigationTitle("Memories")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddMemory = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search memories")
            .sheet(isPresented: $showingAddMemory) {
                AddMemoryView()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var typeFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "All",
                    count: filteredMemories.count,
                    isSelected: selectedType == nil
                ) {
                    selectedType = nil
                }
                
                ForEach(MemoryType.allCases, id: \.self) { type in
                    let count = memoryCountByType[type] ?? 0
                    if count > 0 {
                        FilterChip(
                            title: type.rawValue.capitalized,
                            count: count,
                            isSelected: selectedType == type
                        ) {
                            selectedType = type
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
    
    private var memoryList: some View {
        List {
            ForEach(filteredMemories) { memory in
                MemoryRow(memory: memory)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteMemory(memory)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("No Memories Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap + to add your first memory")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func deleteMemory(_ memory: Memory) {
        withAnimation {
            memoryService.deleteMemory(memory, context: modelContext)
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color.white.opacity(0.3) : Color.secondary.opacity(0.2))
                    )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Memory Row

struct MemoryRow: View {
    let memory: Memory
    
    private var typeIcon: String {
        switch memory.type {
        case .fact: return "info.circle.fill"
        case .preference: return "heart.fill"
        case .event: return "calendar"
        case .mood: return "face.smiling"
        case .goal: return "target"
        case .trait: return "sparkles"
        case .relationship: return "person.2.fill"
        }
    }
    
    private var typeColor: Color {
        switch memory.type {
        case .fact: return .blue
        case .preference: return .pink
        case .event: return .orange
        case .mood: return .yellow
        case .goal: return .green
        case .trait: return .purple
        case .relationship: return .red
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: typeIcon)
                .font(.title3)
                .foregroundStyle(typeColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(memory.content)
                    .font(.body)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text(memory.type.rawValue.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if memory.source == .inferred {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 2) {
                            Image(systemName: "sparkles")
                            Text("Inferred")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    
                    if let category = memory.category {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(category)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text(memory.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Memory.self, configurations: config)
    
    // Add sample memories
    let memories = [
        Memory(type: .fact, content: "Lives in Seattle, Washington"),
        Memory(type: .preference, content: "Loves hiking in the mountains", category: "Hobbies"),
        Memory(type: .event, content: "Started new job at tech company", confidence: 0.9),
        Memory(type: .mood, content: "Feeling excited about upcoming trip"),
        Memory(type: .goal, content: "Want to learn piano this year"),
        Memory(type: .trait, content: "Tends to be analytical and thoughtful", source: .inferred, confidence: 0.85),
        Memory(type: .relationship, content: "Best friend Alex - known for 10 years"),
    ]
    
    for memory in memories {
        container.mainContext.insert(memory)
    }
    
    return MemoryListView()
        .modelContainer(container)
}
