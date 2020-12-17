///I WOULD DIE BEFORE I CLONE A GIT AND SAY THAT IT IS MY CODE - SOUVIK DAS
//  ViewController.swift
//  Chatit
//
//  Created by Souvik Das on 08/12/20.
//
///NOTES TO SELF
///FOR SMOOTHER UI EXPERIENCE CACHE EVERYTHING ON DEVICE USING REALM WHICH I THINK I WOULD IMPLEMENT
///THIS PROJECT MIGHT BE SUBJECT TO RETAIN CYCLES BECAUSE OF WEAK SELF BEING ABSENT IN SOME SLEF CALLS, FUNCTIONALLY IT WILL PERFORM JUST LIKE ANY OTHER APPLICATION

import UIKit
import FirebaseAuth
import JGProgressHUD
class ViewController: UIViewController {
    
    
    @IBOutlet var profile: UIBarButtonItem!
    @IBOutlet var table: UITableView!
    @IBOutlet var noConv: UIImageView!
    
    private let spinner = JGProgressHUD(style: .extraLight)
    
    private var conversations = [Conversation]()
    
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        table.delegate = self
        table.dataSource = self
        table.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        fetchConversations()
        startListeningForConversations()
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: {[weak self] _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.startListeningForConversations()
        })
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
        
    }
    
    //MARK:- REALTIME FETCHING OF CONVERSATIONS AND HENCE UPDATING THE conversations ARRAY
    private func startListeningForConversations() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        print("starting conversation fetch...")
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        DatabaseManager.shared.getAllConversations(for: safeEmail, completion: { [weak self] result in
            switch result {
            case .success(let conversations):
                
                guard !conversations.isEmpty else {
                    print("successfully got conversation models empty")
                    return
                }
                print("successfully got conversation models")
                self?.conversations = conversations
                
                DispatchQueue.main.async {
                    self?.table.reloadData()
                }
            case .failure(let error):
                print("failed to get convos: \(error)")
            }
        })
        
    }
    
    //MARK:- ADDING NEW CONVERSATION
    @IBAction func didTapApp(){
        guard let vc = storyboard?.instantiateViewController(identifier: "new") as? NewConversationViewController else{
            return
        }
        vc.completion = {[weak self] result in
            
            let currentConversation = self?.conversations
            if let targetConversation = currentConversation?.first(where: {
                $0.otherUserEmail == DatabaseManager.safeEmail(emailAddress: result.email)
            }){
                guard let vc = self?.storyboard?.instantiateViewController(identifier: "chat") as? ChatViewController else{
                    return
                }
                vc.isNewConversation = false
                vc.navigationItem.largeTitleDisplayMode = .never
                vc.otherUserEmail = targetConversation.otherUserEmail
                vc.conversationId = targetConversation.id
                vc.title = targetConversation.name
                self?.navigationController?.pushViewController(vc, animated: true)
                
            }
            else{
                self?.createNewConversation(result: result)
            }
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    private func createNewConversation(result: SearchResult) {
        let name = result.name
        let email = DatabaseManager.safeEmail(emailAddress: result.email)
        
        DatabaseManager.shared.conversationExists(iwth: email, completion: { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let conversationId):
                guard let vc = self?.storyboard?.instantiateViewController(identifier: "chat") as? ChatViewController else{
                    return
                }
                vc.otherUserEmail = email
                vc.isNewConversation = false
                vc.title = name
                vc.conversationId = conversationId
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            case .failure(_):
                guard let vc = self?.storyboard?.instantiateViewController(identifier: "chat") as? ChatViewController else{
                    return
                }
                vc.isNewConversation = true
                vc.title = name
                vc.otherUserEmail = email
                vc.navigationItem.largeTitleDisplayMode = .never
                vc.conversationId = nil
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        })
    }
    
    //MARK:- VALIDATION
    private func validateAuth(){
        if FirebaseAuth.Auth.auth().currentUser == nil{
            guard let vc = storyboard?.instantiateViewController(identifier: "login") as? LoginViewController else{
                return
            }
            navigationController?.pushViewController(vc, animated: true)
        }
        else{
            startListeningForConversations()
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
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = table.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        cell.configure(with: conversations[indexPath.row])
        //        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let vc = storyboard?.instantiateViewController(identifier: "chat") as? ChatViewController else{
            return
        }
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.conversationId = conversations[indexPath.row].id
        vc.otherUserEmail = conversations[indexPath.row].otherUserEmail
        vc.title = conversations[indexPath.row].name
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete{
            
            let conversationId = conversations[indexPath.row].id
            tableView.beginUpdates()
            
            DatabaseManager.shared.deleteConversation(conversationId: conversationId, completion: { [weak self] success in
                if success{
                    self?.conversations.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
            })
            
            
            
            tableView.endUpdates()
        }
    }
    
    
}



