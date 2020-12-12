//
//  ViewController.swift
//  Chatit
//
//  Created by Souvik Das on 08/12/20.
//

import UIKit
import FirebaseAuth
import JGProgressHUD
class ViewController: UIViewController {
    
    
    @IBOutlet var profile: UIBarButtonItem!
    @IBOutlet var table: UITableView!
    @IBOutlet var noConv: UIImageView!
    
    private let spinner = JGProgressHUD(style: .extraLight)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        table.delegate = self
        table.dataSource = self
        fetchConversations()
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()

    }
    
    //MARK:- ADD
    @IBAction func didTapApp(){
        guard let vc = storyboard?.instantiateViewController(identifier: "new") as? NewConversationViewController else{
                return
        }
        vc.completion = {[weak self] result in
            self?.createNewConversation(result: result)
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    private func createNewConversation(result: [String: String]) {
        guard let vc = storyboard?.instantiateViewController(identifier: "chat") as? ChatViewController else{
            return
        }
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.otherUserEmail = result["email"] ?? ""
        vc.title = result["name"]
        navigationController?.pushViewController(vc, animated: true)
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
    
    //MARK:- CONVERSATIONS
    func fetchConversations(){
//        spinner.show(in: view)
        table.isHidden = false
    }
    
    
}
//MARK:- EXTENSIONS/Conversations table
extension ViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = table.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "Hello World"
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let vc = storyboard?.instantiateViewController(identifier: "chat") as? ChatViewController else{
                return
        }
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
}



