//
//  ChatView.swift
//  Bob-LLM-Chat
//
//  Created by Mathieu Dubart on 10/02/2025.
//

import SwiftUI

struct ChatView: View {
    let conversationID: String
    @StateObject var viewModel: ChatViewModel = ChatViewModel()
    @State private var message = ""
    @State private var isLoadingResponse = false
    @State private var isEditingPrePrompt = false
    @State private var prePrompt = ""
    
    var body: some View {
        VStack {
            ScrollViewReader { scrollView in
                ScrollView {
                    ForEach(viewModel.messages.indices, id: \.self) { index in
                        let msg = viewModel.messages[index]
                        ChatBubble(message: msg.user, isUser: true)
                        if msg.bot != "" {
                            ChatBubble(message: msg.bot, isUser: false)
                        }
                    }
                    if isLoadingResponse {
                        Spacer()
                        Text("Bob est en train d'écrire...").italic().foregroundColor(.gray)
                    }
                }
                .onChange(of: viewModel.messages.count) { _ in
                    scrollView.scrollTo(viewModel.messages.count - 1, anchor: .bottom)
                }
            }
            .padding(.horizontal)
            
            HStack {
                TextField("Écrire un message...", text: $message)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isLoadingResponse)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
                .disabled(message.isEmpty || isLoadingResponse)
            }
            .padding()
        }
        .navigationTitle("Discussion")
        .toolbar {
            Button(action: {
                viewModel.fetchPrePrompt(conversationID: conversationID) { fetchedPrePrompt in
                    self.prePrompt = fetchedPrePrompt
                    self.isEditingPrePrompt = true
                }
            }) {
                Image(systemName: "gearshape")
            }
        }
        .sheet(isPresented: $isEditingPrePrompt) {
            PrePromptEditorView(conversationID: conversationID, prePrompt: $prePrompt, viewModel: viewModel)
        }
        .onAppear {
            viewModel.fetchConversation(conversationID: conversationID) {
                
            }
        }
    }
    
    private func sendMessage() {
        let userMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty else { return }
        
        let newMessage = Message(user: userMessage, bot: "")
        viewModel.messages.append(newMessage)
        message = ""
        self.isLoadingResponse = true
        
        viewModel.fetchPrePrompt(conversationID: conversationID) { prePrompt in
            viewModel.sendMessage(conversationID: conversationID, prompt: userMessage, prePrompt: prePrompt) { response in
                if let index = self.viewModel.messages.lastIndex(where: { $0.user == userMessage && $0.bot.isEmpty }) {
                    self.viewModel.messages[index].bot = response ?? "Error unwrapping response"
                    self.isLoadingResponse = false
                }
            }
        }
    }

}

#Preview {
    ChatView(conversationID: "test", viewModel: ChatViewModel())
}


#Preview {
    ChatView(conversationID: "test", viewModel: ChatViewModel())
}
