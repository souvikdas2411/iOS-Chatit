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
    //let temporary = DatabaseManager.safeEmail(emailAddress: UserDefaults.standard.string(forKey: "email"))
    private let selfSender = Sender(photoURL: "", senderId: DatabaseManager.safeEmail(emailAddress: (UserDefaults.standard.string(forKey: "email" ) ?? FirebaseAuth.Auth.auth().currentUser?.email) ?? "") , displayName: "Me")
    
    
    //MARK:- VIEW DID LOAD
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(otherUserEmail)
        print(isNewConversation)
//        print(UserDefaults.standard.string(forKey: "email"))
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        messageInputBar.delegate = self
        
        setupInputButton()
        if let id = conversationId {
            listenForMessages(id: id)
        }
        
    }
    
    ///SETTING UP THE SEND IMAGE BUTTON
    private func setupInputButton(){
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.onTouchUpInside { [weak self] _ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    private func presentInputActionSheet(){
        let actionSheet = UIAlertController(title: "Attach", message: "What would you like to attach?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: {[weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: {[weak self] _ in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: {[weak self] _ in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {[weak self] _ in
            
        }))
        present(actionSheet, animated: true)
    }
    private func presentPhotoInputActionSheet(){
        
    }
    
    //MARK:- VIEW DID APPEAR SECTION
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
        
        let uuid = UUID().uuidString //GENERATING RANDOM MESSAGEID
        let message = Message(sender: selfSender, messageId: uuid, sentDate: Date(), kind: .text(text))

        ///SENDING MESSAGES IF NOT EMPTY STRING, UPDATE: INPUT BAR DOESNT ALLOW EMPTY STRINGS
        if isNewConversation{
            ///CREATING NEW CONVERSATION IN DATABASE
            print(text)
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, firstMessage: message, name: self.title ?? "Error 404", completion: {[weak self] success in
                if success{
                    print("message sent")
                    self?.isNewConversation = false
                    self?.messageInputBar.inputTextView.text = nil
                }
                else{
                    print("failed to send message")
                }
            })
            
        }
        else{
            guard let conversationId = conversationId, let name = self.title else {
                return
            }
            ///CONTINUE WITH THE EXISTING CONVERSATION
            DatabaseManager.shared.sendMessage(otherUserEmail: otherUserEmail,name: name, to: conversationId, newMessage: message, completion: {[weak self] success in
                if success{
                    self?.messageInputBar.inputTextView.text = nil
                    print("message sent")
                }
                else{
                    print("failed acknowledgenment from messages")
                }
            })
            
            
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
