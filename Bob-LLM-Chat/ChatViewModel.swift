//
//  ChatViewModel.swift
//  Bob-LLM-Chat
//
//  Created by Mathieu Dubart on 10/02/2025.
//

import Foundation

struct Message: Codable, Hashable {
    let user: String
    var bot: String
    
    enum CodingKeys: String, CodingKey {
        case user
        case bot
    }
}

struct ConversationResponse: Codable {
    let conversation_id: String
    let messages: [Message]
}

class ChatViewModel: ObservableObject {
    @Published var conversations: [String] = []
    @Published var messages: [Message] = []
    @Published var isLoading: Bool = true
    
    let baseURL = "http://100.110.145.126:5000"
    
    func fetchConversations() {
        guard let url = URL(string: "\(baseURL)/list_conversations") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                DispatchQueue.main.async {
                    if let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) {
                        self.conversations = decoded["conversations"] ?? []
                    }
                }
            }
        }.resume()
    }
    
    func fetchConversation(conversationID: String, completion: @escaping () -> Void) {
        guard let url = URL(string: "\(baseURL)/get_conversation/\(conversationID)") else {
            completion()
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, _ in
            DispatchQueue.main.async {
                defer { completion() }
                
                guard let data = data else {
                    print("Aucune donnée reçue.")
                    return
                }
                
                do {
                    let decoded = try JSONDecoder().decode(ConversationResponse.self, from: data)
                    
                    // Exclure le pré-prompt (supposons qu'il soit toujours le premier message bot vide)
                    self.messages = decoded.messages.filter { message in
                        !message.user.isEmpty || !message.bot.starts(with: "Pré-prompt:")
                    }.map { message in
                        Message(
                            user: message.user.replacingOccurrences(of: "User: ", with: "").replacingOccurrences(of: "Bot:", with: "").trimmingCharacters(in: .whitespacesAndNewlines),
                            bot: message.bot.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                    }
                    
                    print("Messages sans pré-prompt : \(self.messages)")
                } catch {
                    print("Erreur de décodage JSON : \(error.localizedDescription)")
                    self.clearMessages()
                }
            }
        }.resume()
    }


    func addUserMessage(_ userMessage: String) {
        messages.append(Message(user: userMessage, bot: ""))
    }
    
    func sendMessage(conversationID: String, prompt: String, prePrompt: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/generate") else { return }
        
        let fullPrompt = "\(prePrompt)\nUser: \(prompt)\nBot:"
        let body: [String: Any] = [
            "conversation_id": conversationID,
            "prompt": fullPrompt
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                guard let data = data,
                      let decoded = try? JSONDecoder().decode([String: String].self, from: data),
                      let response = decoded["response"] else {
                    print("Erreur lors de la réception de la réponse.")
                    completion(nil)
                    return
                }
                completion(response)  // Renvoie la réponse au `ChatView`
            }
        }.resume()
    }

    
    func createConversation(prePrompt: String = "", completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/new_conversation") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["pre_prompt": prePrompt]  // Corps JSON
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, _ in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                   let data = data,
                   let decoded = try? JSONDecoder().decode([String: String].self, from: data),
                   let conversationID = decoded["conversation_id"] {
                    completion(conversationID)
                } else {
                    print("Erreur lors de la création de la conversation.")
                    completion(nil)
                }
            }
        }.resume()
    }

    
    func deleteConversation(at offsets: IndexSet) {
        for index in offsets {
            let conversationID = conversations[index]
            guard let url = URL(string: "\(baseURL)/delete_conversation/\(conversationID)") else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            
            URLSession.shared.dataTask(with: request) { _, _, _ in
                DispatchQueue.main.async {
                    self.conversations.remove(at: index)
                }
            }.resume()
        }
    }
    
    func clearMessages() {
        self.messages = []
    }
    
    func fetchPrePrompt(conversationID: String, completion: @escaping (String) -> Void) {
        guard let url = URL(string: "\(baseURL)/get_pre_prompt/\(conversationID)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                if let data = data,
                   let decoded = try? JSONDecoder().decode([String: String].self, from: data),
                   let prePrompt = decoded["pre_prompt"] {
                    completion(prePrompt)
                } else {
                    completion("")
                }
            }
        }.resume()
    }
    
    func updatePrePrompt(conversationID: String, newPrePrompt: String, completion: @escaping () -> Void) {
        guard let url = URL(string: "\(baseURL)/update_pre_prompt/\(conversationID)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["pre_prompt": newPrePrompt]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { _, response, _ in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("Pré-prompt mis à jour avec succès.")
                } else {
                    print("Échec de la mise à jour du pré-prompt.")
                }
                completion()
            }
        }.resume()
    }

}
