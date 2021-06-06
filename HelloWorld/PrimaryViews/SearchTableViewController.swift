//
//  UserTableViewController.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/13.
//

import UIKit
import FirebaseFunctions
import ProgressHUD

class SearchTableViewController: UITableViewController {
    
    // MARK: - Vars
    lazy var functions = Functions.functions(region: "asia-northeast1")
    var searchResults: [ChannelRes] = []
    var currentUser: User!
    var lang = ""
    var latestSearchText = ""
    var isKeywordTransNeeded = false
    var isChannelTransNeeded = false
    private var isTokenEnabled = false
  
    private var searchController = UISearchController()
    private var filteredItems: [[String]] = []
    
    private var searchBar: UISearchBar {
        searchController.searchBar
    }
    
    private var isSearchTextEmpty: Bool {
        if let searchText = searchBar.text, searchText.isEmpty {
            return true
        }
        return false
    }
    
    private var isSearchTokenEmpty: Bool {
        if searchBar.searchTextField.tokens.isEmpty {
            return true
        }
        return false
    }
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("SearchTableViewController viewDidLoad")
        
        guard let user = User.currentUser else { return }
        currentUser = user
        lang = user.lang
        
        configCustomCells()
        tableView.tableFooterView = UIView()
        setupSearchBar()
        setUpCancelButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        
        if lang == currentUser.lang { return }
        if !isKeywordTransNeeded { return }
        
        translateSearchKeyword()
    }
    
    private func setupSearchResultCell(indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: InactiveCustomCell.identifier, for: indexPath) as! InactiveCustomCell
        
        let channelRes = searchResults[indexPath.row]
        cell.configure(channelRes: channelRes)
        
        return cell
    }
    
    private func setupSearchTokenCell(indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let item = filteredItems[indexPath.section][indexPath.row]
        cell.textLabel?.text = item
        
        return cell
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell
        if isTokenEnabled {
            cell = setupSearchTokenCell(indexPath: indexPath)
            
        } else {
            cell = setupSearchResultCell(indexPath: indexPath)
        }

        return cell
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
//        if isSearchTextEmpty { return 0 }
        
        if isTokenEnabled {
            return filteredItems[section].count
        }
        
        return searchResults.count
    }
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if isTokenEnabled { return nil }

        if !isChannelTransNeeded {
            let headerView = UIView()
            headerView.backgroundColor = UIColor(named: "TableViewBackgroundColor")

            return headerView
        }

        let label = UILabel()
        label.text = "Translate"
        label.textColor = .link
        label.textAlignment = .center
        label.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(translateSearchResults))

        label.addGestureRecognizer(tap)

        return label
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30.0
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if isTokenEnabled {
            // 検索処理を追加する
            let item = filteredItems[indexPath.section][indexPath.row]
            print("Selected item", item)
            
        } else {
            
            let channelRes = searchResults[indexPath.row]
            showChannelView(channelRes: channelRes)
        }
    }

    // 各セルの高さを設定
    // Storyboardで高さを設定すると初期値でしか表示されないため、こちらで設定
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return isTokenEnabled ? 50 : 95
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
//        if isSearchTextEmpty { return 0 }
        
        if isTokenEnabled {
            return filteredItems.count
        }
        
        return searchResults.count
        
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        if !isTokenEnabled { return nil }
        return Plan.allCases[section].rawValue
    }
    
    private func translateSearchKeyword() {
        
        let keyword = searchBar.text!
        print("Search keyword", keyword)
        print("TransLang", lang)
        
        ProgressHUD.show("Translating...")
        ProgressHUD.animationType = .multipleCircleScaleRipple
        
        FirebaseChannelListener.shared.translateSearchKeyword(keyword: keyword, transLang: lang) { [weak self] transResults in
            
            self?.searchBar.text = transResults[0]
            self?.isKeywordTransNeeded = false
            
            DispatchQueue.main.async {
                ProgressHUD.dismiss()
            }
        }
    }
    
    private func configCustomCells() {
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        tableView.register(UINib(nibName: InactiveCustomCell.identifier, bundle: nil), forCellReuseIdentifier: InactiveCustomCell.identifier)
    }
    
    // MARK: - Setup setUpSearchBar
    private func setUpCancelButton() {
        
        let barButtonInSearchBar = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self])
        barButtonInSearchBar.image = UIImage(systemName: "return")?.withRenderingMode(.alwaysTemplate)
        barButtonInSearchBar.title = nil
    }
    
    @objc func translateKeyword(_ sender: UILongPressGestureRecognizer) {
        
        print("Translate button is clicked...")
        
        if isSearchTextEmpty {
            print("Keyword is empty")
            return
        }
        
        print("keyword", searchBar.text!)
        
        performSegue(withIdentifier: "searchBarToTranslateLangSeg", sender: self)
    }
    
    private func setupTransKeywordButton() {
        let transIcon = searchBar.searchTextField.leftView!
        transIcon.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(translateKeyword))
        
        transIcon.addGestureRecognizer(tap)
        searchBar.searchTextField.addSubview(transIcon)
        searchBar.setImage(UIImage(systemName: "globe"), for: .search, state: .normal)
    }
    
    private func setupSearchBar() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true
        
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        
        searchBar.delegate = self
        searchBar.placeholder = "Search channels"
        searchBar.searchTextField.leftView?.tintColor = .link
        setupTransKeywordButton()
        
        searchBar.searchTextField.tokenBackgroundColor = .systemBlue
        searchBar.searchTextField.allowsDeletingTokens = true

    }
        
    // MARK: - UIScrollViewDelegate
    //    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    //
    //        guard let refreshControl = refreshControl else { return }
    //        if !refreshControl.isRefreshing { return }
    //
    //        downloadUsers()
    //        refreshControl.endRefreshing()
    //    }
}

extension SearchTableViewController: ChannelDetailTableViewControllerDelegate {
    
    func didClickFollow() {}
    
    private func showChannelView(channelRes: ChannelRes) {
        
        let channelVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "channelView") as! ChannelDetailTableViewController
        
        channelVC.channelRes = channelRes
        channelVC.delegate = self
        navigationController?.pushViewController(channelVC, animated: true)
    }
}

extension SearchTableViewController: UISearchResultsUpdating {
    
//    private func searchWithToken(searchText: String) {}
    
    private func searchWithKeyword(searchText: String) {
        
//        if isTokenEnabled {
//            print("Token is being enabled now.")
//            return
//        }
        
        if !latestSearchText.isEmpty && (latestSearchText == searchText) {
            print("Search results are already fetched with the searchText.")
            return
        }
        
        httpsCallableRequest(funcName: "onSearchChannels", searchText: searchText) { [weak self] result in
            
            guard let strongSelf = self else { return }
            
            guard let results = result["results"] as? [[String: Any]],
                  let isTransNeeded = result["isTransNeeded"] as? Bool else {
                print("updateSearchResults: Error converting translated results...")
                return
            }
            
            let searchResults = results.map {
                ChannelRes(id: $0["id"]! as! String,
                           name: $0["name"]! as! String,
                           avatarLink: $0["avatarLink"]! as! String,
                           aboutChannel: $0["aboutChannel"]! as! String,
                           channelId: $0["channelId"]! as! String)
            }
            
            strongSelf.searchResults = searchResults
            strongSelf.latestSearchText = searchText
            strongSelf.isChannelTransNeeded = isTransNeeded
            
            DispatchQueue.main.async {
                strongSelf.tableView.reloadData()
            }
        }
    }
    
//    func updateSearchResults(for searchController: UISearchController) {
//
//        print("updateSearchResults")
//
//        guard let searchText = searchBar.text, !searchText.isEmpty else {
//            print("SearchText is empty.")
//            lang = currentUser.lang
//            return
//        }
//
//        if !latestSearchText.isEmpty && (latestSearchText == searchText) {
//            print("Search results are already fetched with the searchText.")
//            return
//        }
//
//        httpsCallableRequest(funcName: "onSearchChannels", searchText: searchText) { [weak self] result in
//
//            guard let strongSelf = self else { return }
//
//            guard let results = result["results"] as? [[String: Any]],
//                  let isTransNeeded = result["isTransNeeded"] as? Bool else {
//                print("updateSearchResults: Error converting translated results...")
//                return
//            }
//
//            let searchResults = results.map {
//                ChannelRes(id: $0["id"]! as! String,
//                           name: $0["name"]! as! String,
//                           avatarLink: $0["avatarLink"]! as! String,
//                           aboutChannel: $0["aboutChannel"]! as! String,
//                           channelId: $0["channelId"]! as! String)
//            }
//
//            strongSelf.searchResults = searchResults
//            strongSelf.latestSearchText = searchText
//            strongSelf.isChannelTransNeeded = isTransNeeded
//
//            DispatchQueue.main.async {
//                strongSelf.tableView.reloadData()
//            }
//        }
//    }
    func updateSearchResults(for searchController: UISearchController) {
        
        print("updateSearchResults")
        
        if isSearchTextEmpty {
            print("Search text is empty...")
            
            if isSearchTokenEmpty {
                isTokenEnabled = false
                tableView.reloadData()
                return
            }
        }
        
        print("tokens", searchBar.searchTextField.tokens)
        print("isTokenEnabled", isTokenEnabled)
        
        // 日本語の場合も、lowercasedを使用しても問題ない？
        let text = searchBar.text!.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("Search Text", text)
        
        var searchPlans: [Plan] = extractSearchPlans()
        if let plan = Plan(text) {
            print("Token search")
            
            isTokenEnabled = true
            setToken(from: plan)
            searchPlans.append(plan)
            updateUI(plans: searchPlans)
            
        } else if !isTokenEnabled {
//            isTokenEnabled = false
            print("Keyword search")
            searchWithKeyword(searchText: text)
        }
    }

    private func extractSearchPlans() -> [Plan] {
        searchBar.searchTextField.tokens.compactMap { $0.representedObject as? Plan }
    }
    
    private func setToken(from plan: Plan) {
        let planToken = UISearchToken(icon: UIImage(systemName: plan.iconName), text: plan.rawValue)
        
        planToken.representedObject = plan
        let field = searchBar.searchTextField
        field.replaceTextualPortion(of: field.textualRange, with: planToken, at: field.tokens.count)
    }
    
    private func updateUI(plans: [Plan]) {
        filteredItems = plans.map { $0.items }
        tableView.reloadData()
    }

    func httpsCallableRequest(funcName: String, searchText: String, completion: @escaping(_ resultDict: [String: Any]) -> Void) {

        print("httpsCallableRequest")

        functions
            .httpsCallable(funcName).call([
                "keyword": searchText,
                "lang": lang,
                "userLang": currentUser.lang
            ]) { (result, error) in

                if let error = error as NSError? {
                    if error.domain == FunctionsErrorDomain {
                        let code = FunctionsErrorCode(rawValue: error.code)
                        let message = error.localizedDescription
                        let details = error.userInfo[FunctionsErrorDetailsKey]
                        print("Error code", code ?? "NULL")
                        print("Error message", message)
                        print("Error details", details ?? "NULL")
                        print("FunctionsError...", error.localizedDescription)
                        return
                    }

                    print("NSError...", error.localizedDescription)
                    return
                }

                guard let resultDict = result?.data as? [String: Any] else {
                    print("httpsCallableRequest: Error converting translated results...")
                    return
                }

                completion(resultDict)
            }
    }
}
    
extension SearchTableViewController: UISearchControllerDelegate {
    
}

extension SearchTableViewController: UISearchBarDelegate {
    
    @objc func translateSearchResults() {
        
        print("translateSearchResults")
        
//        ProgressHUD.show("Translating...")
//        ProgressHUD.animationType = .multipleCircleScaleRipple
        
        FirebaseChannelListener.shared.translateChannels(channels: searchResults, userLang: currentUser.lang) { [weak self] transChannels in
            
            guard let strongSelf = self else { return }
            
            strongSelf.searchResults = transChannels
            strongSelf.isChannelTransNeeded = false
            
            DispatchQueue.main.async {
//                ProgressHUD.dismiss()
                strongSelf.tableView.reloadData()
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        print("searchBarSearchButtonClicked")
        print("keyword", searchBar.text ?? "Empty keyword")
        
        guard let searchText = searchBar.text, !searchText.isEmpty else {
            print("Keyword is empty")
            return
        }
        
//        ProgressHUD.show("Searching...")
//        ProgressHUD.animationType = .multipleCircleScaleRipple
//
//        httpsCallableRequest(funcName: "onSearchChannels", searchText: searchText) { [weak self] result in
//
//            guard let strongSelf = self else { return }
//
//            guard let results = result["results"] as? [[String: String]],
//                  let isTransNeeded = result["isTransNeeded"] as? Bool else {
//                print("Error getting or converting translated results...")
//                return
//            }
//
//            let searchResults = results.map {
//                ChannelRes(id: $0["id"]!,
//                           name: $0["name"]!,
//                           avatarLink: $0["avatarLink"]!,
//                           aboutChannel: $0["aboutChannel"]!,
//                           channelId: $0["channelId"]!)
//            }
//
//            strongSelf.searchResults = searchResults
//
//            DispatchQueue.main.async {
//                ProgressHUD.dismiss()
//                strongSelf.tableView.reloadData()
//            }
//
//            if isTransNeeded {
//                strongSelf.translateSearchResults()
//            }
//        }
    }
            
}
