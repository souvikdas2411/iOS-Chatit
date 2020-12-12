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
    public func createNewConversation(with otherUserEmail: String, firstMessage: Message, completion: @escaping (Bool) -> Void){
        
    }
    
    ///GET ALL CONVO FOR EMAIL
    public func getAllConversations(for email: String, completion: @escaping (Result<String, Error>) -> Void){
        
    }
    
    //
    public func getAllMessageForConversation(with id: String, completion: @escaping (Result<String, Error>) -> Void){
        
    }
    
    
    ///SENDING MESSAGES IN GENERAL
    public func sendMessage(toConversation: String, message: Message, completion: @escaping (Bool) -> Void){
        
    }
}


