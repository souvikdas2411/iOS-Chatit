//
//  DatabaseManager.swift
//  Chatit
//
//  Created by Souvik Das on 09/12/20.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager{
    
    static func safeEmail(emailAddress: String) -> String{
        var safeEmail = emailAddress.replacingOccurrences(of: "@", with: "(at)")
        safeEmail = safeEmail.replacingOccurrences(of: ".", with: "(dot)")
        return safeEmail
    }
    static let shared =  DatabaseManager()
    
    public let database = Database.database().reference()
    
    
    //MARK: - HANDLING ACCOUNTS
    
    struct ChatAppUser{
        let firstName : String
        let lastName : String
        let emailAddress : String
        //let password : String
        
        var safeEmail : String {
            var safeEmail = emailAddress.replacingOccurrences(of: "@", with: "(at)")
            safeEmail = safeEmail.replacingOccurrences(of: ".", with: "(dot)")
            return safeEmail
        }
        var profilePictureFileName : String{
            return "\(safeEmail)_profile_pic.png"
        }
    }
    public func userExists(with email:String, completion: @escaping((Bool) -> Void)){
        
        var safeEmail = email.replacingOccurrences(of: "@", with: "(at)")
        safeEmail = safeEmail.replacingOccurrences(of: ".", with: "(dot)")
        database.child(safeEmail).observeSingleEvent(of: .value, with: {DataSnapshot in
            guard let _ = DataSnapshot.value as? String else{
                completion(false)
                return
            }
        })
        completion(true)
    }
    
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void){
        
        print("1")
        database.child(user.safeEmail).setValue([
            
            "first_name": user.firstName,
            "last_name": user.lastName
            //            "email_address": user.emailAddress
            
        ], withCompletionBlock: {error, _ in
            guard error == nil else{
                print("Failed to write DATABASEMANAGER")
                completion(false)
                return
            }
            
            ///THE FUNCTIONS BELOW ARE USED TO SAVE DATABASE COST WHEN NEW USERS ARE TO BE SEARCHED
            ///USES A STRING:STRING DICTIONARY
            self.database.child("users").observeSingleEvent(of: .value, with: {snapshot in
                if var usersCollection = snapshot.value as? [[String: String]] {
                    ///Exists so append
                    let newElement = [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.safeEmail
                    ]
                    usersCollection.append(newElement)
                    
                    self.database.child("users").setValue(usersCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    })
                }
                else{
                    ///Does not exists so create
                    
                    // create that array
                    let newCollection: [[String: String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    
                    self.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    })
                    
                }
                
            })
            
            completion(true)
        })
    }
    
    //MARK:- SEARCH
    /// Gets all users from database
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            completion(.success(value))
        })
    }
    ///CREATING OUR OWN ERROR
    public enum DatabaseError: Error {
        case failedToFetch
        
        public var localizedDescription: String {
            switch self {
            case .failedToFetch:
                return "failed"
            }
        }
    }
    
    
}
//MARK:- SENDING MESSAGES
extension DatabaseManager{
    
    ///CREATE A NEW CONVO
    public func createNewConversation(with otherUserEmail: String, firstMessage: Message,name: String, completion: @escaping (Bool) -> Void){
        guard let currentEmail = UserDefaults.standard.string(forKey: "email"),
              let currentName = UserDefaults.standard.string(forKey: "name") else {
            completion(false)
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: {[weak self] snapshot in
            guard var userNode = snapshot.value as? [String:Any] else{
                completion(false)
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            let conversationId = "conversation_\(firstMessage.messageId)"
            
            switch firstMessage.kind{
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            ///Conversation schema
            let newConversationsData: [String : Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "is_read": false,
                    "message": message,
                    
                ]
            ]
            let recipient_newConversationsData: [String : Any] = [
                "id": conversationId,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "is_read": false,
                    "message": message,
                    
                ]
            ]
            
            ///RECIPIENT USER ENTRY
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: {[weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    //append
                    conversations.append(recipient_newConversationsData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue([conversationId])
                }
                else{
                    //create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationsData])
                }
            })
            
            ///CURRENT USER ENTRY
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                ///conversations array exists for current user i.e user has at least one conversation
                conversations.append(newConversationsData)
                ///appending new data above so in the below statement re setting the usernode to updated conversations
                userNode["conversations"] = conversations
                ref.setValue(userNode, withCompletionBlock: { [weak self] error,_ in
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(conversationID: "conversation_\(firstMessage.messageId)", firstMessage: firstMessage, name: name, completion: completion)
                })
            }
            else{
                ///create new conversations array
                userNode["conversations"] = [
                    newConversationsData
                ]
                ref.setValue(userNode, withCompletionBlock: { [weak self] error,_ in
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(conversationID: "conversation_\(firstMessage.messageId)", firstMessage: firstMessage,name: name, completion: completion)
                })
                
            }
        })
        self.finishCreatingConversation(conversationID: "conversation_\(firstMessage.messageId)", firstMessage: firstMessage,name: name, completion: completion)
    }
    
    
    private func finishCreatingConversation(conversationID: String, firstMessage: Message, name: String, completion: @escaping (Bool)->Void){
        
        var message = ""
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        switch firstMessage.kind{
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let myEmail = UserDefaults.standard.string(forKey: "email") else{
            completion(false)
            return
        }
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        let collectionMessage: [String: Any] = [
            "id":firstMessage.messageId,
            "type":firstMessage.kind.messageKindString,
            "content": message,
            "date":dateString,
            "sender_email": currentUserEmail,
            "is_read":false,
            "name": name
            
        ]
        
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        database.child("\(conversationID)").setValue(value, withCompletionBlock: {error, _ in
            guard error == nil else{
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    ///GET ALL CONVO FOR EMAIL
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void){
        
        ///ATTACHING LISTENER FOR NEW CONVOS
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            ///converting dictionary to model check conversationsmodel,swift for model info
            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool
                else {
                    return nil
                }
                
                let latestMmessageObject = LatestMessage(date: date,
                                                         text: message,
                                                         isRead: isRead)
                return Conversation(id: conversationId,
                                    name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMessage: latestMmessageObject)
            })
            
            completion(.success(conversations))
        })
    }
    
    //NAME SUGGESTS ENOUGH
    public func getAllMessageForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void){
        ///ATTACHING LISTENER FOR NEW CONVOS
        database.child("\(id)/messages").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            ///converting dictionary to model check conversationsmodel,swift for model info
            let messages: [Message] = value.compactMap({ dictionary in
                guard let name =  dictionary["name"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let messageID = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let type = dictionary["type"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString) else{
                    
                    return nil
                    
                }
                
                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)
                return Message(sender: sender, messageId: messageID, sentDate: date, kind: .text(content))
            })
            
            completion(.success(messages))
        })
    }
    
    
    ///SENDING MESSAGES IN GENERAL
    public func sendMessage(otherUserEmail: otherUserEmail, name: String, to conversation: String, newMessage: Message, completion: @escaping (Bool) -> Void){
        database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: {[weak self] snapshot in
            
            guard let strongSelf = self else {
                return
            }
            
            guard var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            switch newMessage.kind{
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            guard let myEmail = UserDefaults.standard.string(forKey: "email") else{
                completion(false)
                return
            }
            let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
            let newMessageEntry: [String: Any] = [
                "id":newMessage.messageId,
                "type":newMessage.kind.messageKindString,
                "content": message,
                "date":dateString,
                "sender_email": currentUserEmail,
                "is_read":false,
                "name": name
                
            ]
            currentMessages.append(newMessageEntry)
            
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) { error, _ in
                guard error == nil else{
                   completion(false)
                    return
                }
                completion(true)
                
            }
        })
    }
}

//MARK:- USED TO GET FNAME AND LNAME FROM DATABASE FOR FIREBASE LOGIN
extension DatabaseManager{
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}

