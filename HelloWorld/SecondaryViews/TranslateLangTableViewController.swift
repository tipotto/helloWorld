//
//  LangTableViewController.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/02/22.
//

import UIKit

class TranslateLangTableViewController: UITableViewController {

    // MARK: - Vars
    var allLangs: [[String: String]] = []

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        loadLangList()
        tableView.tableFooterView = UIView()
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

        return cell
    }
    
    // セル（row）がクリックされる度に実行
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let transLang = allLangs[indexPath.row]
        guard let transLangCode = transLang["code"] else { return }
        
        let nav = self.navigationController
        
        // 一つ前のViewControllerを取得する
        let searchTVC = nav?.viewControllers[(nav?.viewControllers.count)! - 2] as! SearchTableViewController
        
        // 値を渡す
        searchTVC.lang = transLangCode
        searchTVC.isKeywordTransNeeded = true
        
        navigationController?.popViewController(animated: true)
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

