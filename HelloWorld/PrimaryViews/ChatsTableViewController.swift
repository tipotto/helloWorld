//
//  ChatsTableViewController.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/15.
//

import UIKit

class ChatsTableViewController: UITableViewController {

    // MARK: - Vars
    var allRooms: [JoiningChat] = []
    var filteredRooms: [JoiningChat] = []
    
    let searchController = UISearchController(searchResultsController: nil)

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        setupSearchController()
        loadJoiningRooms()
    }
    
    // MARK: - IBActions
    @IBAction func composeBarButtonPressed(_ sender: Any) {
        
        let userView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "UsersView") as! UsersTableViewController
        
        navigationController?.pushViewController(userView, animated: true)
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController.isActive ? filteredRooms.count : allRooms.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecentTableViewCell.identifier, for: indexPath) as! RecentTableViewCell
        
        let room = searchController.isActive ? filteredRooms[indexPath.row] : allRooms[indexPath.row]
        
        cell.configure(room: room)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle != .delete { return }
        
        let isSearch = searchController.isActive
        let room = isSearch ? filteredRooms[indexPath.row] : allRooms[indexPath.row]
        
        FirebaseRecentListener.shared.deleteJoiningRoom(room)
        
        isSearch ? filteredRooms.remove(at: indexPath.row) : allRooms.remove(at: indexPath.row)
        
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
        
        let room = searchController.isActive ? filteredRooms[indexPath.row] : allRooms[indexPath.row]
//        FirebaseRecentListener.shared.clearUnreadCounter(chatRoomId: room.id)
        
        // Enter chat room
        enterChatRoom(room: room)

    }

    private func enterChatRoom(room: JoiningChat) {
        
        // 自分とチャット相手のJoiningChatが存在するか確認し、存在しなければ作成
        // TODO: もし片方でもユーザーが退会していた場合（この場合はチャット相手の可能性が高い）、
        // チャットを試みているユーザー（ログインユーザー）のリストから該当のJoiningChatを削除する
        restartChat(room: room)
        
        let privateChatView = ChatViewController(chatId: room.id,
                                                 recipientId: room.partnerId,
                                                 recipientName: room.name,
                                                 recipientLang: room.lang)
        
        // 遷移した後の画面では、下部のバーを表示しない
        privateChatView.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(privateChatView, animated: true)
        
    }

    private func loadJoiningRooms() {
        FirebaseRecentListener.shared.fetchJoiningRoomsByUser { [weak self] rooms in
            
            guard let strongSelf = self else { return }
            
            strongSelf.allRooms = rooms
            
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
    
//    private func filteredContentForSearchText(searchText: String) {
//        filteredRecents = allRecents.filter { recent -> Bool in
//            return recent.receiverName.lowercased().contains(searchText.lowercased())
//        }
//
//        tableView.reloadData()
//    }
    
    private func filteredContentForSearchText(searchText: String) {
        filteredRooms = allRooms.filter {
            $0.name.lowercased().contains(searchText.lowercased())
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
