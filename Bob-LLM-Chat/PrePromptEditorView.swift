//
//  PrePromptEditorView.swift
//  Bob-LLM-Chat
//
//  Created by Mathieu Dubart on 10/02/2025.
//

import SwiftUI

struct PrePromptEditorView: View {
    let conversationID: String
    @Binding var prePrompt: String
    var viewModel: ChatViewModel  // Direct reference, not @Binding or @ObservedObject
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Modifier le Pré-prompt")
                    .font(.headline)
                    .padding(.bottom)
                
                TextEditor(text: $prePrompt)
                    .frame(height: 200)
                    .border(Color.gray, width: 1)
                    .padding(.bottom)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Pré-prompt")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sauvegarder") {
                        viewModel.updatePrePrompt(conversationID: conversationID, newPrePrompt: prePrompt) {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
    }
}
