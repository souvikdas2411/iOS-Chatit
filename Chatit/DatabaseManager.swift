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
            
            
            completion(true)
        })
    }
    
}


