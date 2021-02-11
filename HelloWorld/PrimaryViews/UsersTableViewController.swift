//
//  UserTableViewController.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/13.
//

import UIKit

class UsersTableViewController: UITableViewController {

    // MARK: - Vars
    var allUsers: [User] = []
    var filteredUsers: [User] = []
    let searchController = UISearchController(searchResultsController: nil)

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        tableView.refreshControl = refreshControl
//        createDummyUsers()
        
        tableView.tableFooterView = UIView()
        setupSearchController()
        downloadUsers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController.isActive ? filteredUsers.count : allUsers.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! UserTableViewCell
        
        let user = searchController.isActive ? filteredUsers[indexPath.row] : allUsers[indexPath.row]
        cell.configure(user: user)
        
        return cell
    }
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor(named: "TableViewBackgroundColor")
        
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 15.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let user = searchController.isActive ? filteredUsers[indexPath.row] : allUsers[indexPath.row]
        showUserProfile(user)
    }

    // 各セルの高さを設定
    // Storyboardで高さを設定すると初期値でしか表示されないため、こちらで設定
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    private func downloadUsers() {
        FirebaseUserListener.shared.downloadAllUsersFromFirebase { [weak self] users in
            guard let strongSelf = self else { return }
            
            strongSelf.allUsers = users
            
            DispatchQueue.main.async {
                strongSelf.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Setup SearchController
    private func setupSearchController() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search user"
        searchController.searchResultsUpdater = self
        definesPresentationContext = true
    }
    
    private func filteredContentForSearchText(searchText: String) {
        filteredUsers = allUsers.filter { user -> Bool in
            return user.username.lowercased().contains(searchText.lowercased())
        }
        
        tableView.reloadData()
    }
    
    // MARK: - UIScrollViewDelegate
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        guard let refreshControl = refreshControl else { return }
        if !refreshControl.isRefreshing { return }
        
        downloadUsers()
        refreshControl.endRefreshing()
    }
    
    private func showUserProfile(_ user: User) {
        let profileView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "ProfileView") as! ProfileTableViewController
        
        profileView.user = user
        navigationController?.pushViewController(profileView, animated: true)
    }
}

extension UsersTableViewController: UISearchResultsUpdating {
    
    // ユーザー検索に文字を入力する度に実行
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        filteredContentForSearchText(searchText: searchText)
    }
}
