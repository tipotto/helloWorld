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
    var allChannels: [Channel] = []
    var subscribedChannels: [Channel] = []
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ChannelTableViewCell
        
        let channel = channelSegmentOutlet.selectedSegmentIndex == 0 ? subscribedChannels[indexPath.row] : allChannels[indexPath.row]

        cell.configure(channel: channel)
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        if channelSegmentOutlet.selectedSegmentIndex == 1 { return false }
        return subscribedChannels[indexPath.row].adminId != User.currentId
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle != .delete { return }
        
        var channelToUnfollow = subscribedChannels[indexPath.row]
        subscribedChannels.remove(at: indexPath.row)
        
//        if let index = channelToUnfollow.memberIds.firstIndex(of: User.currentId) {
//            channelToUnfollow.memberIds.remove(at: index)
//        }
        
        let index = channelToUnfollow.memberIds.firstIndex(of: User.currentId)
        channelToUnfollow.memberIds.remove(at: index!)
        
        FirebaseChannelListener.shared.saveChannel(channelToUnfollow)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 15.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if channelSegmentOutlet.selectedSegmentIndex == 1 {
            // show channel view
            showChannelView(channel: allChannels[indexPath.row])
            
        } else {
            // show chat view
            showChatView(channel: subscribedChannels[indexPath.row])
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    // MARK: - UI Scroll View Delegate
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !refreshControl!.isRefreshing { return }
        downloadAllChannels()
        refreshControl!.endRefreshing()
    }
    
    // MARK: - Navigation
    private func showChannelView(channel: Channel) {
        
        let channelVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "channelView") as! ChannelDetailTableViewController
        
        channelVC.channel = channel
        channelVC.delegate = self
        navigationController?.pushViewController(channelVC, animated: true)
    }
    
    private func showChatView(channel: Channel) {
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
