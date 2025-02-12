//
//  ChatBubble.swift
//  Bob-LLM-Chat
//
//  Created by Mathieu Dubart on 10/02/2025.
//

import SwiftUI

struct ChatBubble: View {
    var message: String
    var isUser: Bool
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            Text(message)
                .padding()
                .foregroundColor(isUser ? .white : .primary)
                .background(isUser ? Color.blue : Color.gray.opacity(0.2))
                .cornerRadius(16)
                .frame(maxWidth: 300, alignment: isUser ? .trailing : .leading)
                .padding(isUser ? .leading : .trailing, 50)
            
            if !isUser { Spacer() }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ChatBubble(message: "Hello !", isUser: true)
}
