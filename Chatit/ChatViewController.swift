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
import SDWebImage
import CoreLocation

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
struct Media: MediaItem{
    var url: URL?
    
    var image: UIImage?
    
    var placeholderImage: UIImage
    
    var size: CGSize
    
    
}

struct Location: LocationItem{
    var location: CLLocation
    
    var size: CGSize
    
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
        messagesCollectionView.messageCellDelegate = self
        messagesCollectionView.delegate = self
        messageInputBar.delegate = self
        
        setupInputButton()
        if let id = conversationId {
            listenForMessages(id: id)
        }
        
    }
    
    //MARK:- ATTACHMENT BUTTON
    ///SETTING UP THE SEND IMAGE BUTTON AND REQUIRED STUFFS
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
        let actionSheet = UIAlertController(title: "Attachment", message: "What would you like to attach?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: {[weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: {[weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: {[weak self] _ in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: {[weak self] _ in
            self?.presentLocationPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil ))
        
        present(actionSheet, animated: true)
    }
    private func presentPhotoInputActionSheet(){
        let actionSheet = UIAlertController(title: "Attach Photo", message: "Select source", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {[weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Gallery", style: .default, handler: {[weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil ))
        
        present(actionSheet, animated: true)
    }
    private func presentLocationPicker(){
        let vc = LocationPickerViewController(coordinates: nil)
                vc.title = "Pick Location"
                vc.navigationItem.largeTitleDisplayMode = .never
                vc.completion = { [weak self] selectedCoorindates in

                    guard let strongSelf = self else {
                        return
                    }

                    guard let conversationId = strongSelf.conversationId,
                        let name = strongSelf.title
                         else {
                            return
                    }
//                    let selfSender = self?.selfSender
                    let messageId = UUID().uuidString
                    let longitude: Double = selectedCoorindates.longitude
                    let latitude: Double = selectedCoorindates.latitude

                    print("long=\(longitude) | lat= \(latitude)")


                    let location = Location(location: CLLocation(latitude: latitude, longitude: longitude),
                                         size: .zero)

                    let message = Message(sender: strongSelf.selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .location(location))

                    DatabaseManager.shared.sendMessage(otherUserEmail: strongSelf.otherUserEmail, name: name, to: conversationId, newMessage: message, completion: { success in
                        if success {
                            print("sent location message")
                        }
                        else {
                            print("failed to send location message")
                        }
                    })
                }
                navigationController?.pushViewController(vc, animated: true)
    }
    private func presentVideoInputActionSheet(){
        let actionSheet = UIAlertController(title: "Attach Video", message: "Select source", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {[weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Gallery", style: .default, handler: {[weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.mediaTypes = ["public.movie"]
            //            picker.videoQuality = .typeMedium
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil ))
        
        present(actionSheet, animated: true)
    }
    
    //MARK:- VIEW DID APPEAR SECTION
    //    override func viewDidAppear(_ animated: Bool) {
    //        super.viewDidAppear(animated)
    //        messageInputBar.inputTextView.becomeFirstResponder()
    //    }
    
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
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl, completed: nil)

        default:
            break
        }
    }
}
//MARK:- HANDLING WHEN USER TAPS INTO A MESSAGE
extension ChatViewController: MessageCellDelegate{
    
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .location(let locationData):
            let coordinates = locationData.location.coordinate
            let vc = LocationPickerViewController(coordinates: coordinates)
            vc.title = "Location"
            vc.navigationItem.largeTitleDisplayMode = .never
            vc.completion = nil
            navigationController?.pushViewController(vc, animated: true)
            
            
        default:
            break
        }
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            guard let vc = storyboard?.instantiateViewController(identifier: "photo") as? PhotoViewerViewController else{
                return
            }
            vc.imageUrl = imageUrl.absoluteString
            vc.title = "Photo"
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
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

//MARK:- IMAGE PICKER DELEGATE AND SENDING MEDIA
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let conversationId = conversationId,
              let name = self.title
        else{
            return
        }
        
        if let image = info[.editedImage] as? UIImage, let imageData = image.pngData(){
            let uuid = UUID().uuidString
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: "\(uuid).png", completion: {[weak self] result in
                guard let strongSelf = self else {
                    return
                }
                switch result{
                case .success(let urlString):
                    
                    guard let url = URL(string: urlString),
                          let placeholder = UIImage(systemName: "plus") else {
                        return
                    }
                    
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    let message = Message(sender: self?.selfSender as! SenderType, messageId: uuid, sentDate: Date(), kind: .photo(media))
                    DatabaseManager.shared.sendMessage(otherUserEmail: strongSelf.otherUserEmail, name: name, to: conversationId, newMessage: message, completion: {[weak self] success in
                        if success{
                            print("photo message sent")
                        }
                        else{
                            print("screwed up something")
                        }
                    })
                case .failure(let error):
                    print("failed to send photo \(error)")
                }
            })
        }
        else if let videoUrl = info[.mediaURL] as? URL{
            
            ///UPLOAD VIDEO CHECK StorageManager for reference
            let uuid = UUID().uuidString
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: "\(uuid).mov", completion: {[weak self] result in
                guard let strongSelf = self else {
                    return
                }
                switch result{
                case .success(let urlString):
                    
                    guard let url = URL(string: urlString),
                          let placeholder = UIImage(systemName: "plus") else {
                        return
                    }
                    
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    let message = Message(sender: self?.selfSender as! SenderType, messageId: uuid, sentDate: Date(), kind: .photo(media))
                    DatabaseManager.shared.sendMessage(otherUserEmail: strongSelf.otherUserEmail, name: name, to: conversationId, newMessage: message, completion: {[weak self] success in
                        if success{
                            print("Video message sent")
                        }
                        else{
                            print("screwed up something in video part")
                        }
                    })
                case .failure(let error):
                    print("failed to send video \(error)")
                }
            })
            
        }
        
        
        
    }
}
