////
////  MyChannelsTableViewController.swift
////  HelloWorld
////
////  Created by egamiyuji on 2021/02/02.
////
//
//import UIKit
//
//class _MyChannelsTableViewController: UITableViewController {
//
//    // MARK: - Vars
//    var myChannels: [ChannelRes] = []
//
//    // MARK: - View Life Cycle
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        // Storyboardでの設定により、ChannelsTableViewControllerからノーコードで遷移
//        // 画面が表示される度に毎回呼ばれる
//        print("MyChannelsTableViewController viewDidLoad")
//
//        configCustomCell()
//        tableView.tableFooterView = UIView()
//        downloadUserChannels()
//    }
//
//    private func configCustomCell() {
//        tableView.register(UINib(nibName: InactiveCustomCell.identifier, bundle: nil), forCellReuseIdentifier: InactiveCustomCell.identifier)
//    }
//
//    // MARK: - Download channels
//    private func downloadUserChannels() {
//        FirebaseChannelListener.shared.downloadUserChannels { [weak self] channels in
//
//            self?.myChannels = channels
//
//            // channelの取得はバックグラウンドキューで実行されるため、
//            // UIの更新はメインキューで行う必要あり
//            // 今回の場合は、Firebase Storageから画像データを取得するときのように
//            // カスタムキューを使用してはいないが、Firestoreからの取得は非同期処理なので、
//            //　同様にバックグラウンドキューが使用されているという認識で良さそう
//            DispatchQueue.main.async {
//                self?.tableView.reloadData()
//            }
//        }
//    }
//
//    // MARK: - IBACtions
//    @IBAction func addBarButtonPressed(_ sender: Any) {
//        // ここではsenderのselfは、+ ボタンを表す
//        performSegue(withIdentifier: "myChannelToAddSeg", sender: self)
//    }
//
//    // MARK: - Table view data source
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return myChannels.count
//    }
//
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//
//        let cell = tableView.dequeueReusableCell(withIdentifier: InactiveCustomCell.identifier, for: indexPath) as! InactiveCustomCell
//
//        let channel = myChannels[indexPath.row]
//        cell.configure(channel: channel)
//
//        return cell
//    }
//
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//
//        // show channel messages
//        performSegue(withIdentifier: "myChannelToAddSeg", sender: myChannels[indexPath.row])
//    }
//
//    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
//        return false
//    }
//
////    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
////        if editingStyle != .delete { return }
////        print("delete cell at indexPath", indexPath)
////
////        // チャンネルデータ自体の削除
////        let channelToDelete = myChannels[indexPath.row]
////        myChannels.remove(at: indexPath.row)
////
////        FirebaseChannelListener.shared.deleteChannel(channelToDelete)
////
////        tableView.deleteRows(at: [indexPath], with: .automatic)
////    }
//
//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 95
//    }
//
////    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
////
////        if segue.identifier == "myChannelToAddSeg" {
////            let editChannelView = segue.destination as! AddChannelTableViewController
////            editChannelView.editChannelId = (sender as? JoiningChannel)?.id
////        }
////    }
//
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//
//        if segue.identifier == "myChannelToAddSeg" {
//            let editChannelView = segue.destination as! AddChannelTableViewController
//            editChannelView.editChannel = sender as? ChannelRes
//        }
//    }
//}
