//
//  DatabaseManager.swift
//  Chatit
//
//  Created by Souvik Das on 09/12/20.
//

import Foundation
import FirebaseDatabase




final class DatabaseManager{
    static let shared =  DatabaseManager()
    
    public let database = Database.database().reference()
    
    
    
    
    
    //MARK: - HANDLING ACCOUNTS
    
    struct ChatAppUser{
        let firstName : String
        let lastName : String
        let emailAddress : String
        //let password : String
        //let profilePictureUrl : String
        var safeEmail : String {
            var safeEmail = emailAddress.replacingOccurrences(of: "@", with: "(at)")
            safeEmail = safeEmail.replacingOccurrences(of: ".", with: "(dot)")
            return safeEmail
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
    
    public func insertUser(with user: ChatAppUser){
        
        print("1")
        database.child(user.safeEmail).setValue([
            
            "first_name": user.firstName,
            "last_name": user.lastName
            //            "email_address": user.emailAddress
            
        ]){(error:Error?, ref:DatabaseReference) in
            if let error = error {
                print("2")
                print("Data could not be saved: \(error).")
            } else {
                print("3")
                print("Data saved successfully!")
            }
        }
    }
    
}


