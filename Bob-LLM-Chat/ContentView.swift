//
//  ContentView.swift
//  Bob-LLM-Chat
//
//  Created by Mathieu Dubart on 10/02/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.conversations, id: \.self) { conversation in
                    NavigationLink(destination: ChatView(conversationID: conversation)) {
                        Text(conversation)
                    }
                }
                .onDelete(perform: viewModel.deleteConversation)
            }
            .navigationTitle("Discussions")
            .toolbar {
                Button(action: self.createConversation) {
                    Image(systemName: "plus")
                }
            }
            .onAppear {
                viewModel.fetchConversations()
            }
        }
    }
    
    func createConversation() {
        viewModel.createConversation(prePrompt: "") { _ in
            viewModel.fetchConversations()
        }
    }

}

#Preview {
    ContentView()
}
