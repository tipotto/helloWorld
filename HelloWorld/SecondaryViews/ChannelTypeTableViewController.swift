//
//  StatusTableViewController.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/13.
//

import UIKit

class ChannelTypeTableViewController: UITableViewController {

    // MARK: - Vars
    var channelTypes: [String] = []
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        loadChannelTypes()
        configureCell()
    }

    // MARK: - TableView Delegates
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channelTypes.count
    }
    
    // tableViewがリロードされる度に実行（tableView.reloadDataメソッド）
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let type = channelTypes[indexPath.row]
        cell.textLabel?.text = type
        
        let addChannelTVC = getPreviousController()
        
        cell.accessoryType = addChannelTVC.channelType == type ? .checkmark : .none
        
        return cell
    }
        
    // セル（row）がクリックされる度に実行
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let addChannelTVC = getPreviousController()
        addChannelTVC.channelType = channelTypes[indexPath.row]

        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor(named: "TableViewBackgroundColor")
        return headerView
    }
    
    private func configureCell() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    private func getPreviousController() -> AddChannelTableViewController {
        
        let nav = self.navigationController
        
        // 一つ前のViewControllerを取得する
        let addChannelTVC = nav?.viewControllers[(nav?.viewControllers.count)! - 2] as! AddChannelTableViewController
        
        return addChannelTVC
    }
    
    // MARK: - Loading Status
    private func loadChannelTypes() {
        
//        guard let types = userDefaults.object(forKey: kCHANNELTYPE) as? [String] else {
//            print("Channel types are empty.")
//            return
//        }
        
        let types = ChannelType.allCases.map({ $0.rawValue })
        print("channel types", types)
        
        channelTypes = types
        tableView.reloadData()
    }
}
