//
//  StatusTableViewController.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/13.
//

import UIKit

class ChannelThemeTableViewController: UITableViewController {

    // MARK: - Vars
    var channelThemes: [String] = []
    
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
        loadChannelThemes()
        configureCell()
    }

    // MARK: - TableView Delegates
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channelThemes.count
    }
    
    // tableViewがリロードされる度に実行（tableView.reloadDataメソッド）
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let theme = channelThemes[indexPath.row]
        cell.textLabel?.text = theme
        
        let addChannelTVC = getPreviousController()
        
        cell.accessoryType = addChannelTVC.channelTheme == theme ? .checkmark : .none
        
        return cell
    }
        
    // セル（row）がクリックされる度に実行
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let addChannelTVC = getPreviousController()
        addChannelTVC.channelTheme = channelThemes[indexPath.row]

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
    private func loadChannelThemes() {
        
        let themes = ChannelTheme.allCases.map({ $0.rawValue })
        print("channel themes", themes)
        
        channelThemes = themes
        tableView.reloadData()
    }
}

