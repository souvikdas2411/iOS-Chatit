//
//  ProfileViewController.swift
//  Chatit
//
//  Created by Souvik Das on 08/12/20.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
class ProfileViewController: UIViewController {
    
    @IBOutlet var signOut : UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    
    //MARK:- HANDLING SIGNOUTS
    @IBAction func didTapSignOut(){
        allOut()
        navigationController?.popToRootViewController(animated: true)
    }
    func allOut(){
        UserDefaults.standard.setValue(nil, forKey: "email")
        UserDefaults.standard.setValue(nil, forKey: "name")
        
        // Log Out facebook
        FBSDKLoginKit.LoginManager().logOut()
        
        // Google Log out
//        GIDSignIn.sharedInstance()?.signOut()
        
        
        try! FirebaseAuth.Auth.auth().signOut()
        
        
    }
}




