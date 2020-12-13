///I WOULD DIE BEFORE I CLONE A GIT AND SAY THAT IT IS MY CODE - SOUVIK DAS
//  ViewController.swift
//  Chatit
//
//  Created by Souvik Das on 08/12/20.
//
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        table.delegate = self
        table.dataSource = self
        table.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        fetchConversations()
        startListeningForConversations()
        
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
        vc.isNewConversation = true
        vc.conversationId = nil
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
    
}



