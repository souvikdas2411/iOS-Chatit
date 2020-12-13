//
//  ChatViewController.swift
//  Chatit
//
//  Created by Souvik Das on 11/12/20.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import FirebaseAuth

struct Message: MessageType{
    var sender: SenderType
    
    var messageId: String
    
    var sentDate: Date
    
    var kind: MessageKind
}

extension MessageKind{
    var messageKindString: String{
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "link_preview"
        case .custom(_):
            return "custom"
        }
    }
}

struct Sender: SenderType{
    
    var photoURL: String
    
    var senderId: String
    
    var displayName: String
    
    
}


class ChatViewController: MessagesViewController {
    
    public static let dateFormatter: DateFormatter = {
        let formattre = DateFormatter()
        formattre.dateStyle = .medium
        formattre.timeStyle = .long
        formattre.locale = .current
        return formattre
    }()
    
    public var otherUserEmail = ""
    public var isNewConversation = false
    public var conversationId: String?
    
    private var messages = [Message]()
    private let selfSender = Sender(photoURL: "", senderId: (UserDefaults.standard.string(forKey: "email") ?? FirebaseAuth.Auth.auth().currentUser?.email) ?? " ", displayName: "Me")
    
    
    //MARK:- VIEW DID LOAD
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(otherUserEmail)
        print(isNewConversation)
        print(UserDefaults.standard.string(forKey: "email"))
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        messageInputBar.delegate = self
        
        if let id = conversationId {
            listenForMessages(id: id)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
    //MARK:- LISTENING FOR EXISTING MESSAGES IN A CONVERSATION
    public func listenForMessages(id: String){
        DatabaseManager.shared.getAllMessageForConversation(with: id, completion: {[weak self] result in
            switch result{
            case .success(let messages):
                guard !messages.isEmpty else{
                    return
                }
                self?.messages = messages
                
                DispatchQueue.main.async {
                    ///THE STATEMENT BELOW KEEPS THE USER IN THE SAME SCROLL POSITION EVEN IF A NEW MESSAGE ARRIVES
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                }
            case .failure(let error):
                print("failed to get messages acknowledgement from ChatViewController \(error)")
            }
        })
    }
}
//MARK:-HANDLING ACCESSORY BAR/TEXT BAR DELEGATE
extension ChatViewController: InputBarAccessoryViewDelegate{
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        ///SENDING MESSAGES IF NOT EMPTY STRING, UPDATE: INPUT BAR DOESNT ALLOW EMPTY STRINGS
        if isNewConversation{
            ///CREATING NEW CONVERSATION IN DATABASE
            let uuid = UUID().uuidString //GENERATING RANDOM MESSAGEID
            let message = Message(sender: selfSender, messageId: uuid, sentDate: Date(), kind: .text(text))
            print(text)
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, firstMessage: message, name: self.title ?? "Error 404", completion: {[weak self] success in
                if success{
                    print("message sent")
                    self?.isNewConversation = false
                    //                    let newConversationId = "conversation_\(mmessage.messageId)"
                    //                    self?.conversationId = newConversationId
                    //                    self?.listenForMessages(id: newConversationId, shouldScrollToBottom: true)
                    self?.messageInputBar.inputTextView.text = nil
                }
                else{
                    print("failed to send message")
                }
            })
            
        }
        else{
            
            ///CONTINUE WITH THE EXISTING CONVERSATION
            
            
        }
    }
}


//MARK:- HANDLING CHAT DELEGATES
extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate{
    func currentSender() -> SenderType {
        return selfSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
}
