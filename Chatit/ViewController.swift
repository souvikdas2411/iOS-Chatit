//
//  ViewController.swift
//  Chatit
//
//  Created by Souvik Das on 08/12/20.
//

import UIKit
import FirebaseAuth
class ViewController: UIViewController {
    
    @IBOutlet var profile: UIBarButtonItem!
    @IBOutlet var table: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()

    }
    
    //MARK:- VALIDATION
    private func validateAuth(){
        if FirebaseAuth.Auth.auth().currentUser == nil{
            guard let vc = storyboard?.instantiateViewController(identifier: "login") as? LoginViewController else{
                    return
            }
            navigationController?.pushViewController(vc, animated: true)
        }
        
    }
    //MARK:- PROFILE VIEW
    @IBAction func didTapProfile(){
        guard let vc = storyboard?.instantiateViewController(identifier: "prof") as? ProfileViewController else{
                return
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
}



