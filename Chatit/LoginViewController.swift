//
//  LoginViewController.swift
//  Chatit
//
//  Created by Souvik Das on 08/12/20.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD
class LoginViewController: UIViewController {
    
    @IBOutlet var eid: UITextField!
    @IBOutlet var pass: UITextField!
    @IBOutlet var cont: UIButton!
    
    private let spinner = JGProgressHUD(style: .extraLight)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        spinner.show(in: view)

        
        
        
        let loginButton: FBLoginButton = {
            let button = FBLoginButton()
            button.permissions = ["email,public_profile"]
            return button
        }()
        loginButton.center = view.center
        view.addSubview(loginButton)
        
        //MARK:- HARDCODING GOOGLE BUTTON CUZ OF SOME ANCHOR PROBLEM
        //        googleLoginButton.frame =  CGRect(x: 125, y: 355, width: 50, height: 30)
        //        view.addSubview(googleLoginButton)
        
        
        loginButton.delegate = self
        //        googleLoginButton. = self
        //Looks for single or multiple taps.
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        //tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
        
        // Do any additional setup after loading the view.
        
        eid.delegate = self
        pass.delegate = self
        
        
    }
    func tap1() {
        let uialert = UIAlertController(title: "Error", message: "Error siging in", preferredStyle: UIAlertController.Style.alert)
        uialert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.default, handler: nil))
        self.present(uialert, animated: true, completion: nil)
    }
    
    
    @IBAction func didTapRegister(){
        guard let vc = storyboard?.instantiateViewController(identifier: "register") as? RegisterViewController else{
            return
        }
        navigationController?.pushViewController(vc, animated: true)
        
    }
    @IBAction func didTapLogin(){
        eid.resignFirstResponder()
        pass.resignFirstResponder()
        spinner.show(in: view)
        guard let e = eid.text, let p = pass.text, !e.isEmpty, !p.isEmpty, p.count >= 6 else {
            self.spinner.dismiss()
            tap()
            return
        }
        
        //FIREBASE LOGIN
        FirebaseAuth.Auth.auth().signIn(withEmail: e, password: p, completion: {authResult,error in
            guard let _ = authResult, error == nil else{
                self.tap1()
                return
            }
            DispatchQueue.main.async {
                self.spinner.dismiss()
            }
            ///CACHING USER DATA ON THE DEVICE
            UserDefaults.standard.set(e, forKey: "email")
            
            self.navigationController?.popToRootViewController(animated: true)
        })
        
        
    }
    func tap() {
        let uialert = UIAlertController(title: "Error", message: "Please fill in the details", preferredStyle: UIAlertController.Style.alert)
        uialert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
        self.present(uialert, animated: true, completion: nil)
    }
    
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
}

extension LoginViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == eid{
            pass.becomeFirstResponder()
        }
        else if textField == pass{
            didTapLogin()
        }
        
        return true
    }
}

//MARK:- HANDLING THE FACEBOOK LOGIN
extension LoginViewController: LoginButtonDelegate{
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        //No Operation as of now
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields":
                                                                        "email, first_name, last_name, picture.type(large), name"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        
        facebookRequest.start(completionHandler: { _, result, error in
            guard let result = result as? [String: Any],
                  error == nil else {
                print("Failed to make facebook graph request")
                return
            }
            
            guard let fname = result["first_name"] as? String,
                  let lname = result["last_name"] as? String,
//                  let full_name = result["name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String: Any],
                  let data = picture["data"] as? [String: Any],
                  let pictureUrl = data["url"] as? String else {
                
                return
            }
            ///CACHING USER DATA ON THE DEVICE
            UserDefaults.standard.set(email, forKey: "email")
//            UserDefaults.standard.set(fname, forKey: "first_name")
            
            DatabaseManager.shared.userExists(with: email, completion: { exists in
                if !exists {
                    let chatUser = DatabaseManager.ChatAppUser(firstName: fname,
                                                               lastName: lname,
                                                               emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                        if success {
                            
                            guard let url = URL(string: pictureUrl) else {
                                return
                            }
                            
                            print("Downloading data from facebook image")
                            
                            ///Was prolly missing the statement below for the data bug
                            URLSession.shared.dataTask(with: url, completionHandler: { data, _,_ in
                                guard let data = data else {
                                    print("Failed to get data from facebook")
                                    return
                                }
                                
                                print("got data from FB, uploading...")
                                
                                ///SOMEHOW MANAGED TO BREAK THE CODE data: NOW SOLVED
                                let filename = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: filename, completion: { result in
                                    switch result {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("Storage maanger error: \(error)")
                                    }
                                })
                            }).resume()
                            ///The resume() above tells the URLSession to start
                        }
                    })
                }
            })
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: {authResult, error in
                
                //MARK:-MFA HANDLING
                guard let _ = authResult, error == nil else{
                    print("MFA")
                    return
                }
                print("NO MFA")
                self.navigationController?.popToRootViewController(animated: true)
            })
            
        })
        
        
    }
    
}
