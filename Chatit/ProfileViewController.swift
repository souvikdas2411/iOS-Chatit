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
import JGProgressHUD
class ProfileViewController: UIViewController {
    
    @IBOutlet var signOut : UIBarButtonItem!
    @IBOutlet var address : UITextView!
    @IBOutlet var profileImg : UIImageView!
    
    private let spinner = JGProgressHUD(style: .extraLight)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        spinner.show(in: view)
        
        let safeText = UserDefaults.standard.string(forKey: "email")
        address.text = safeText
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: safeText ?? " ")
        let fileName = safeEmail + "_profile_pic.png"
        let path = "images/"+fileName
        
        StorageManager.shared.downloadURL(for: path, completion: {result in
            switch result{
            
            case .success(let url):
                self.downloadImage(imageView: self.profileImg, url: url)
            case .failure(let error):
                print("Error to get profile image \(error)")
            }
        })
    }
    
    func downloadImage(imageView: UIImageView, url:URL){
        
        URLSession.shared.dataTask(with: url, completionHandler: {data,_, error in
            guard let data = data, error == nil else{
                return
            }
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                self.profileImg.image = image
                self.spinner.dismiss()
            }
            
        }).resume()
    }
    
    
    //MARK:- HANDLING SIGNOUTS
    @IBAction func didTapSignOut(){
        allOut()
        navigationController?.popToRootViewController(animated: true)
    }
    func allOut(){
//        UserDefaults.standard.setValue(nil, forKey: "email")
//        UserDefaults.standard.setValue(nil, forKey: "name")
        
        if let appDomain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: appDomain)
        }
        
        // Log Out facebook
        FBSDKLoginKit.LoginManager().logOut()
        
        // Google Log out
        //        GIDSignIn.sharedInstance()?.signOut()
        
        
        try! FirebaseAuth.Auth.auth().signOut()
        
        
    }
}




