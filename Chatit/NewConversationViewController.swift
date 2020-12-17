//
//  NewConversationViewController.swift
//  Chatit
//
//  Created by Souvik Das on 08/12/20.
//

import UIKit
import JGProgressHUD
class NewConversationViewController: UIViewController {
    
    public var completion: ((SearchResult) -> (Void))?
    
    private let spinner = JGProgressHUD(style: .extraLight)
    
    private var users = [[String: String]]()
    
    private var results = [SearchResult]()
    
    private var hasFetched = false
    
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(NewConversationCell.self, forCellReuseIdentifier: NewConversationCell.identifier)
        
        //Looks for single or multiple taps.
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
        
        searchBar.delegate = self
        searchBar.becomeFirstResponder()     
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
}
//MARK:- Table View delegate
extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identifier,for: indexPath) as! NewConversationCell
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print(results)
        // start conversation
        let targerUserData = results[indexPath.row]
        
        self.completion?(targerUserData)
        
        
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
}

//MARK:- Search bar delegate
extension NewConversationViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        searchBar.resignFirstResponder()
        
        results.removeAll()
        spinner.show(in: view)
        
        searchUsers(query: text)
    }
    
    func searchUsers(query: String) {
        // check if array has firebase results
        if hasFetched {
            // if it does: filter
            filterUsers(with: query)
        }
        else {
            // if not, fetch then filter
            DatabaseManager.shared.getAllUsers(completion: {result in
                switch result {
                case .success(let usersCollection):
                    self.hasFetched = true
                    self.users = usersCollection
                    self.filterUsers(with: query)
                case .failure(let error):
                    print("Failed to get users: \(error)")
                }
            })
        }
    }
    
    func filterUsers(with term: String) {
        // update the UI: eitehr show results or show no results label
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String, hasFetched else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        self.spinner.dismiss()
        
        let results: [SearchResult] = users.filter({
            
            //WE DO NOT WANNA SHOW THE CURRENT USER IN THE SEARCH LIST SO THE TWO STATEMENTS BELOW
            guard let email = $0["email"], email != safeEmail else {
                return false
            }
            
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            
            return name.hasPrefix(term.lowercased())
        }).compactMap({
        
                    guard let email = $0["email"],
                          let name = $0["name"] else {
                        return nil
                    }
        
                    return SearchResult(name: name, email: email)
                })
        
        self.results = results
        
        updateUI()
    }
    
    func updateUI() {
        if results.isEmpty {
            tableView.isHidden = true
        }
        else {
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
    
}
struct SearchResult {
    let name : String
    let email : String
}
