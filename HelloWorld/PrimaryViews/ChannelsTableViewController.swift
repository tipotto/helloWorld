//
//  ChannelsTableViewController.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/02/01.
//

import UIKit

class ChannelsTableViewController: UITableViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var channelSegmentOutlet: UISegmentedControl!
    
    // MARK: - Vars
    var allChannels: [ChannelRes] = []
    var subscribedChannels: [JoiningChannel] = []
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("ChannelsTableViewController viewDidLoad")
        
        configCustomCells()
        
        // TODO: ユーザーにレコメンドするチャンネルを取得する
        // HTTP呼び出し可能関数を呼び出し、バックエンドで処理を実行
        // Algoliaからユーザーの興味や嗜好に合ったチャンネルを10件ほど取得して表示
        // そのため、ユーザープロフィールに興味や嗜好を追加できるようにする必要あり
        downloadAllChannels()
        downloadSubscribedChannels()
        
        navigationItem.largeTitleDisplayMode = .always
        title = "Channels"
        tableView.tableFooterView = UIView()
        
        refreshControl = UIRefreshControl()
        tableView.refreshControl = refreshControl
    }
    
    // MARK: - IBActions
    // セグメントタグが変更された時に実行
    @IBAction func channelSegmentValueChanged(_ sender: Any) {
        tableView.reloadData()
    }
    
    private func configCustomCells() {
        
        tableView.register(UINib(nibName: ActiveCustomCell.identifier, bundle: nil), forCellReuseIdentifier: ActiveCustomCell.identifier)
        
        tableView.register(UINib(nibName: InactiveCustomCell.identifier, bundle: nil), forCellReuseIdentifier: InactiveCustomCell.identifier)
    }
    
    // MARK: - Download channels
    private func downloadAllChannels() {
        FirebaseChannelListener.shared.downloadAllChannels { [weak self] channels in

            guard let strongSelf = self else { return }
            strongSelf.allChannels = channels

            if strongSelf.channelSegmentOutlet.selectedSegmentIndex == 0 { return }

            DispatchQueue.main.async {
                strongSelf.tableView.reloadData()
            }
        }
    }

    private func isSelectedSubscribe() -> Bool {
        return channelSegmentOutlet.selectedSegmentIndex == 0
    }
    
    private func downloadSubscribedChannels() {
        FirebaseChannelListener.shared.downloadSubscribedChannels { [weak self] channels in
            
            guard let strongSelf = self else { return }
            strongSelf.subscribedChannels = channels
            
            if strongSelf.channelSegmentOutlet.selectedSegmentIndex == 1 { return }
            DispatchQueue.main.async {
                strongSelf.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channelSegmentOutlet.selectedSegmentIndex == 0 ? subscribedChannels.count : allChannels.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if isSelectedSubscribe() {
            let activeCell = tableView.dequeueReusableCell(withIdentifier: ActiveCustomCell.identifier, for: indexPath) as! ActiveCustomCell
            
            let channel = subscribedChannels[indexPath.row]
            activeCell.configure(channel: channel)
            return activeCell
        }
        
        let inactiveCell = tableView.dequeueReusableCell(withIdentifier: InactiveCustomCell.identifier, for: indexPath) as! InactiveCustomCell
        
        let channelRes = allChannels[indexPath.row]
        inactiveCell.configure(channelRes: channelRes)
        return inactiveCell
        
        
        //        let cell = tableView.dequeueReusableCell(withIdentifier: ActiveCustomCell.identifier, for: indexPath) as! ActiveCustomCell
        //
        //        let channel = subscribedChannels[indexPath.row]
        //        cell.configure(channel: channel)
        //        return cell
        
        
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        if !isSelectedSubscribe() { return false }
        
        let channel = subscribedChannels[indexPath.row]
        if channel.isAdmin { return false }
        
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle != .delete { return }
        
        let channel = subscribedChannels[indexPath.row]
        FirebaseChannelListener.shared.unfollowChannel(channelId: channel.id)
        
        subscribedChannels.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
    
    // MARK: - Table view delegate
//    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 15.0
//    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if !isSelectedSubscribe() {
            // show channel view
            showChannelView(channelRes: allChannels[indexPath.row])
            
        } else {
            let channel = subscribedChannels[indexPath.row]
            
//            FirebaseRecentListener.shared.clearUnreadCounter(chatRoomId: channel.id, isChannel: true)
            // show chat view
            showChatView(channel: channel)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 95
    }
    
    // MARK: - UI Scroll View Delegate
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !refreshControl!.isRefreshing { return }
        downloadAllChannels()
        refreshControl!.endRefreshing()
    }
    
    // MARK: - Navigation
    private func showChannelView(channelRes: ChannelRes) {
        
        let channelVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "channelView") as! ChannelDetailTableViewController
        
        channelVC.channelRes = channelRes
        channelVC.delegate = self
        navigationController?.pushViewController(channelVC, animated: true)
    }
    
    private func showChatView(channel: JoiningChannel) {
        let channelChatVC = ChannelChatViewController(channel: channel)
        
        channelChatVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(channelChatVC, animated: true)
    }
}

extension ChannelsTableViewController: ChannelDetailTableViewControllerDelegate {
    
    func didClickFollow() {
        print("didClickFollow is executed.")
        channelSegmentOutlet.selectedSegmentIndex = 0
        downloadAllChannels()
    }
}
