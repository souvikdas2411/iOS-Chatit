//
//  RegisterViewController.swift
//  Chatit
//
//  Created by Souvik Das on 08/12/20.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import JGProgressHUD
import FirebaseStorage

class RegisterViewController: UIViewController {
    
    
    @IBOutlet var fname: UITextField!
    @IBOutlet var lname: UITextField!
    @IBOutlet var email: UITextField!
    @IBOutlet var pass: UITextField!
    @IBOutlet var passconf: UITextField!
    @IBOutlet var img: UIImageView!
    
    
    private let spinner = JGProgressHUD(style: .dark)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Looks for single or multiple taps.
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
        
        fname.delegate = self
        lname.delegate = self
        email.delegate = self
        pass.delegate = self
        passconf.delegate = self
        
        //        act.startAnimating()
        
        
        let gesture = UITapGestureRecognizer(target: self, action:#selector(didTapChangeProfilePic))
        //gesture.numberOfTouchesRequired =
        
        img.addGestureRecognizer(gesture)
        
    }
    func tap() {
        let uialert = UIAlertController(title: "Error", message: "Please check the details", preferredStyle: UIAlertController.Style.alert)
        uialert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
        self.present(uialert, animated: true, completion: nil)
    }
    func tap1() {
        let uialert = UIAlertController(title: "Error", message: "Error creating account", preferredStyle: UIAlertController.Style.alert)
        uialert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.default, handler: nil))
        self.present(uialert, animated: true, completion: nil)
    }
    func tap2() {
        let uialert = UIAlertController(title: "Error", message: "User already exists", preferredStyle: UIAlertController.Style.alert)
        uialert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.default, handler: nil))
        self.present(uialert, animated: true, completion: nil)
    }
    
    //MARK: - CREATING ACCOUNT SECTION
    @IBAction func didTapRegister(){
        
        
        email.resignFirstResponder()
        fname.resignFirstResponder()
        lname.resignFirstResponder()
        pass.resignFirstResponder()
        passconf.resignFirstResponder()
        guard let ee = email.text else {return}
        guard let pp = pass.text else {return}
        guard let fn = fname.text else{return}
        guard let ln = lname.text else{return}
        
        
        guard let f = fname.text, let l = lname.text, let e = email.text, let p = pass.text, let pc = passconf.text, !e.isEmpty, !p.isEmpty, !pc.isEmpty, !f.isEmpty, !l.isEmpty, p==pc, p.count >= 6 else {
            tap()
            return
        }
        
        self.spinner.show(in: view)
        
        
        DatabaseManager.shared.userExists(with: ee, completion: {exists in
            guard !exists else{
                return
            }
            DispatchQueue.main.async {
                self.spinner.dismiss()
            }
            FirebaseAuth.Auth.auth().createUser(withEmail: ee, password: pp, completion: { (authResult, error) in
                guard let _ = authResult, error == nil else{
                    self.fname.text = ""
                    self.lname.text = ""
                    self.email.text = ""
                    self.pass.text = ""
                    self.passconf.text = ""
                    self.tap2()
                    return
                }
                let chatUser = DatabaseManager.ChatAppUser(firstName: fn, lastName: ln, emailAddress: ee)
                DatabaseManager.shared.insertUser(with: chatUser, completion: {success in
                    if(success){
                        ///UPLOADS IMAGE IF DATABASE WRITING IS SUCCESSFULL
                        guard let image = self.img.image, let data = image.pngData() else{
                            
                            return
                        }
                        let fileName = chatUser.profilePictureFileName
                        StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { result in
                            switch result{
                            case .success(let downloadUrl):
                                ///Caching to sytem to not redundantly go to firebase for searching
                                UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                print(downloadUrl)
                            case .failure(let downloadUrl):
                                print("Storage manager error from register view")
                            }
                        })
                        
                    }
                })
                self.navigationController?.popToRootViewController(animated: true)
            })
            
        })
        
        
        
        
        
    }
    
    //MARK:- OTHER THINGS
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    
    @objc func didTapChangeProfilePic(){
        presentPhotoActionSheet()
    }
}
extension RegisterViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == fname{
            lname.becomeFirstResponder()
        }
        if textField == lname{
            email.becomeFirstResponder()
        }
        if textField == email{
            pass.becomeFirstResponder()
        }
        if textField == pass{
            passconf.becomeFirstResponder()
        }
        else if textField == passconf{
            didTapRegister()
        }
        
        return true
    }
}

//MARK: - PROFILE PICTURE
extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Profile Picture",
                                            message: "How would you like to select a picture?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel,
                                            handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Take Photo",
                                            style: .default,
                                            handler: { [weak self] _ in
                                                
                                                self?.presentCamera()
                                                
                                            }))
        actionSheet.addAction(UIAlertAction(title: "Chose Photo",
                                            style: .default,
                                            handler: { [weak self] _ in
                                                
                                                self?.presentPhotoPicker()
                                                
                                            }))
        
        present(actionSheet, animated: true)
    }
    
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        
        self.img.image = selectedImage
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
