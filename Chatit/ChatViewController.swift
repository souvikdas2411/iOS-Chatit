//
//  ChatViewController.swift
//  Chatit
//
//  Created by Souvik Das on 11/12/20.
//

import UIKit
import MessageKit
import InputBarAccessoryView

struct Message: MessageType{
    var sender: SenderType
    
    var messageId: String
    
    var sentDate: Date
    
    var kind: MessageKind
}

struct Sender: SenderType{
    
    var photoURL: String
    
    var senderId: String
    
    var displayName: String
    
    
}


class ChatViewController: MessagesViewController {
    
    public var otherUserEmail = ""
    public var isNewConversation = false
    
    
    private var messages = [Message]()
    private let selfSender = Sender(photoURL: "", senderId: "1", displayName: "Souvik's Mac")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(otherUserEmail)
        messages.append(Message(sender: selfSender, messageId: "1", sentDate: Date(), kind: .text("From mac")))
        messages.append(Message(sender: selfSender, messageId: "1", sentDate: Date(), kind: .text("From mac")))

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        messageInputBar.delegate = self
    }

}
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
