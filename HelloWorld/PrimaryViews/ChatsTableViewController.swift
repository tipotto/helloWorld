//
//  ChatsTableViewController.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/15.
//

import UIKit

class ChatsTableViewController: UITableViewController {

    // MARK: - Vars
    var allRecents: [RecentChat] = []
    var filteredRecents: [RecentChat] = []
    let searchController = UISearchController(searchResultsController: nil)

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        setupSearchController()
        downloadRecentChats()
    }
    
    // MARK: - IBActions
    @IBAction func composeBarButtonPressed(_ sender: Any) {
        
        let userView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "UsersView") as! UsersTableViewController
        
        navigationController?.pushViewController(userView, animated: true)
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController.isActive ? filteredRecents.count : allRecents.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! RecentTableViewCell
        
        let recent = searchController.isActive ? filteredRecents[indexPath.row] : allRecents[indexPath.row]
        cell.configure(recent: recent)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle != .delete { return }
        
        let isSearch = searchController.isActive
        let recent = isSearch ? filteredRecents[indexPath.row] : allRecents[indexPath.row]
        
        FirebaseRecentListener.shared.deleteRecent(recent)
        
        isSearch ? filteredRecents.remove(at: indexPath.row) : allRecents.remove(at: indexPath.row)
        
        tableView.deleteRows(at: [indexPath], with: .automatic)
        
    }
    
    // MARK: - Table view delegate
    // 各セルの高さを設定
    // Storyboardで高さを設定すると初期値でしか表示されないため、こちらで設定
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    
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
        
        let recent = searchController.isActive ? filteredRecents[indexPath.row] : allRecents[indexPath.row]
        FirebaseRecentListener.shared.clearUnreadCounter(recent: recent)
        
        // Enter chat room
        goToChat(recent: recent)

    }
    
    private func goToChat(recent: RecentChat) {
        
        // 自分とチャット相手のRecentが存在するか確認し、もし存在しなければ作成する
        // 確実にお互いのRecentが存在するようにする
        // しかし、お互いのユーザーデータが確実に存在することが前提となるため、
        // 万が一片方でもユーザーを削除していた場合、アプリがクラッシュする
        restartChat(chatRoomId: recent.chatRoomId, memberIds: recent.memberIds)
        
        let privateChatView = ChatViewController(chatId: recent.chatRoomId,
                                                 recipientId: recent.receiverId,
                                                 recipientName: recent.receiverName)
        
        // 遷移した後の画面では、下部のバーを表示しない
        privateChatView.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(privateChatView, animated: true)
        
    }
    
    private func downloadRecentChats() {
        FirebaseRecentListener.shared.downloadRecentChatsFromFireStore { [weak self] allRecents in
            
            guard let strongSelf = self else { return }
            
            strongSelf.allRecents = allRecents
            
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
        filteredRecents = allRecents.filter { recent -> Bool in
            return recent.receiverName.lowercased().contains(searchText.lowercased())
        }
        
        tableView.reloadData()
    }
}

extension ChatsTableViewController: UISearchResultsUpdating {
    
    // ユーザーを検索する度に実行
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        filteredContentForSearchText(searchText: searchText)
    }
}
