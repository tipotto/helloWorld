//
//  StatusTableViewController.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/13.
//

import UIKit

class StatusTableViewController: UITableViewController {

    // MARK: - Vars
    var allStatuses: [String] = []

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        loadUserStatus()
    }

    // MARK: - TableView Delegates
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allStatuses.count
    }
    
    // tableViewがリロードされる度に実行（tableView.reloadDataメソッド）
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let status = allStatuses[indexPath.row]
        cell.textLabel?.text = status
        
        guard let user = User.currentUser else { return cell }
        cell.accessoryType = user.status == status ? .checkmark : .none
        
        return cell
    }
    
    // セル（row）がクリックされる度に実行
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        updateCellCheck(indexPath)
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor(named: "TableViewBackgroundColor")
        return headerView
    }
    
    // MARK: - Loading Status
    private func loadUserStatus() {
        
        guard let statuses = userDefaults.object(forKey: kSTATUS) as? [String] else { return }
        allStatuses = statuses
        tableView.reloadData()
    }
    
    private func updateCellCheck(_ indexPath: IndexPath) {
        
        guard var user = User.currentUser else { return }
        
        user.status = allStatuses[indexPath.row]
        saveUserLocally(user)
        FirebaseUserListener.shared.saveUsersToFireStore(user)
    }
}
