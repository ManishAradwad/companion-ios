//
//  AddMemoryView.swift
//  Companion
//
//  View for manually adding a new memory
//

import SwiftUI
import SwiftData

struct AddMemoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var memoryService = MemoryService()
    
    @State private var selectedType: MemoryType = .fact
    @State private var content: String = ""
    @State private var category: String = ""
    @FocusState private var isContentFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $selectedType) {
                        ForEach(MemoryType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: iconForType(type))
                                Text(type.rawValue.capitalized)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Memory Type")
                } footer: {
                    Text(descriptionForType(selectedType))
                }
                
                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                        .focused($isContentFocused)
                }
                
                Section {
                    TextField("Category (optional)", text: $category)
                } header: {
                    Text("Category")
                } footer: {
                    Text("Optional: Add a category to organize this memory")
                }
            }
            .navigationTitle("New Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveMemory()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                isContentFocused = true
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveMemory() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedContent.isEmpty else { return }
        
        memoryService.addExplicitMemory(
            type: selectedType,
            content: trimmedContent,
            category: trimmedCategory.isEmpty ? nil : trimmedCategory,
            context: modelContext
        )
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        dismiss()
    }
    
    // MARK: - Helper Methods
    
    private func iconForType(_ type: MemoryType) -> String {
        switch type {
        case .fact: return "info.circle.fill"
        case .preference: return "heart.fill"
        case .event: return "calendar"
        case .mood: return "face.smiling"
        case .goal: return "target"
        case .trait: return "sparkles"
        case .relationship: return "person.2.fill"
        }
    }
    
    private func descriptionForType(_ type: MemoryType) -> String {
        switch type {
        case .fact:
            return "Concrete information about yourself (e.g., 'Lives in Seattle', 'Has a dog named Max')"
        case .preference:
            return "Your likes, dislikes, and habits (e.g., 'Prefers morning workouts', 'Loves Italian food')"
        case .event:
            return "Life happenings and milestones (e.g., 'Started new job in December', 'Sister's wedding in March')"
        case .mood:
            return "Emotional states and feelings (e.g., 'Felt anxious about presentation', 'Happy after hiking')"
        case .goal:
            return "Aspirations and plans (e.g., 'Wants to learn piano', 'Training for marathon')"
        case .trait:
            return "Personality characteristics (e.g., 'Tends to overthink', 'Values honesty')"
        case .relationship:
            return "People in your life (e.g., 'Mom - close relationship', 'Best friend Alex')"
        }
    }
}

#Preview {
    AddMemoryView()
        .modelContainer(for: [Memory.self], inMemory: true)
}
