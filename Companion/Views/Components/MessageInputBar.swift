//
//  MessageInputBar.swift
//  Companion
//
//  Reusable message input component for chat interfaces
//

import SwiftUI

struct MessageInputBar: View {
    @Binding var prompt: String
    let isRunning: Bool
    let isModelLoaded: Bool
    let onSend: () -> Void
    let onCancel: () -> Void
    
    @FocusState private var isFocused: Bool
    
    private var canSend: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                TextField(isModelLoaded ? "Message..." : "Loading model...", text: $prompt, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .lineLimit(1...5)
                    .disabled(isRunning || !isModelLoaded)
                    .focused($isFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        sendIfPossible()
                    }
                
                Button {
                    if isRunning {
                        onCancel()
                    } else {
                        sendIfPossible()
                    }
                } label: {
                    Image(systemName: isRunning ? "stop.circle.fill" : "arrow.up.circle.fill")
                        .font(.title)
                        .foregroundStyle(isRunning ? .red : (canSend && isModelLoaded ? .blue : .gray))
                        .animation(.easeInOut(duration: 0.15), value: isRunning)
                }
                .disabled((!isRunning && !canSend) || !isModelLoaded)
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .compositingGroup()
    }
    
    private func sendIfPossible() {
        guard canSend else { return }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        onSend()
    }
    
    /// Dismiss the keyboard
    func dismissKeyboard() {
        isFocused = false
    }
}

#Preview {
    VStack {
        Spacer()
        MessageInputBar(
            prompt: .constant(""),
            isRunning: false,
            isModelLoaded: true,
            onSend: {},
            onCancel: {}
        )
    }
}
