//
//  LangTableViewController.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/02/22.
//

import UIKit
import ProgressHUD

class ChannelLangTableViewController: UITableViewController {

    // MARK: - Vars
    var allLangs: [[String: String]] = []
    var currentUser: User!
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        print("viewDidLoad")
        
        super.viewDidLoad()
        loadLangList()
        tableView.tableFooterView = UIView()
        currentUser = User.currentUser!
        configureCell()
    }
    
    // MARK: - Loading Langs
    private func loadLangList() {
        if let langList = userDefaults.array(forKey: kLANGLIST) as? [[String: String]] {
            print("Lang list exists in userDefault.")
            allLangs = langList
            tableView.reloadData()
            
        } else {
            print("Lang list DOES NOT exist in userDefault.")
            fetchLangListFromGoogle()
        }
    }
    
    private func fetchLangListFromGoogle() {
        
        TranslationManager.shared.fetchSupportedLanguages { [weak self] langList in
            guard let strongSelf = self else { return }
            
            strongSelf.allLangs = langList
            strongSelf.tableView.reloadData()
            userDefaults.set(langList, forKey: kLANGLIST)
        }
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allLangs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let transLang = allLangs[indexPath.row]
        cell.textLabel?.text = transLang["name"]
        
        let addChannelTVC = getPreviousController()
        
        cell.accessoryType = addChannelTVC.channelLangs.contains(transLang["code"]!) ? .checkmark : .none

        return cell
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
    
    // セル（row）がクリックされる度に実行
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let transLang = allLangs[indexPath.row]
        let transLangCode = transLang["code"]!
        
        if transLangCode == currentUser.lang || transLangCode == "en" {
            ProgressHUD.showFailed("The language is necessary.")
            return
        }
        
        let addChannelTVC = getPreviousController()
        
        if addChannelTVC.channelLangs.contains(transLangCode) {
            addChannelTVC.channelLangs.removeAll(where: { $0 == transLangCode})
            tableView.reloadData()
            return
        }
        
        if addChannelTVC.channelLangs.count >= 5 {
            ProgressHUD.showFailed("You can select up to 5 languages.")
            return
        }
        
        addChannelTVC.channelLangs.append(transLangCode)
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor(named: "TableViewBackgroundColor")
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
}


