//
//  MyChannelsTableViewController.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/02/02.
//

import UIKit

class MyChannelsTableViewController: UITableViewController {
    
    // MARK: - Vars
    var myChannels: [Channel] = []

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        downloadUserChannels()
    }
    
    // MARK: - Download channels
    private func downloadUserChannels() {
        FirebaseChannelListener.shared.downloadUserChannels { [weak self] channels in
            
            self?.myChannels = channels
            
            // channelの取得はバックグラウンドキューで実行されるため、
            // UIの更新はメインキューで行う必要あり
            // 今回の場合は、Firebase Storageから画像データを取得するときのように
            // カスタムキューを使用してはいないが、Firestoreからの取得は非同期処理なので、
            //　同様にバックグラウンドキューが使用されているという認識で良さそう
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
    
    // MARK: - IBACtions
    @IBAction func addBarButtonPressed(_ sender: Any) {
        // ここではsenderのselfは、+ ボタンを表す
        performSegue(withIdentifier: "myChannelToAddSeg", sender: self)
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myChannels.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ChannelTableViewCell
        
        let channel = myChannels[indexPath.row]
        cell.configure(channel: channel)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // show channel messages
        performSegue(withIdentifier: "myChannelToAddSeg", sender: myChannels[indexPath.row])
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle != .delete { return }
        print("delete cell at indexPath", indexPath)
        
        let channelToDelete = myChannels[indexPath.row]
        myChannels.remove(at: indexPath.row)
        
        FirebaseChannelListener.shared.deleteChannel(channelToDelete)
        
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "myChannelToAddSeg" {
            let editChannelView = segue.destination as! AddChannelTableViewController
            editChannelView.channelToEdit = sender as? Channel
        }
    }

}
