//
//  TranslationManager.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/02/17.
//

import Foundation
import FirebaseFunctions

class TranslationManager: NSObject {
    
    static let shared = TranslationManager()
//    private let apiKey = "AIzaSyDi_b2uivXmqheYIx8CpSl_Olosc-6_xlw"
    lazy var functions = Functions.functions(region: "asia-northeast1")
    
    //    var supportedLanguages = [TranslationLanguage]()
    
    override init() {
        super.init()
    }
    
//    private func makeRequest(usingTranslationAPI api: TranslationAPI, urlParams: [String: Any], completion: @escaping (_ results: [String: Any]?) -> Void) {
//
//        guard var components = URLComponents(string: api.getURL()) else {
//            completion(nil); return
//        }
//
//        components.queryItems = [URLQueryItem]()
//
//        for (key, value) in urlParams {
//            if key != "q" {
//                components.queryItems?.append(URLQueryItem(name: key, value: value as? String))
//                continue
//            }
//
//            guard let value = value as? [String] else { continue }
//            for queryText in value {
//                components.queryItems?.append(URLQueryItem(name: key, value: queryText))
//            }
//        }
//
//        guard let url = components.url else {
//            completion(nil); return
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = api.getHTTPMethod()
//
//        let session = URLSession(configuration: .default)
//        let task = session.dataTask(with: request) { (results, response, error) in
//            if let error = error {
//                print("Error translating text", error.localizedDescription)
//                completion(nil); return
//            }
//
//            guard let response = response as? HTTPURLResponse, let results = results else { completion(nil); return
//            }
//
//            if !(response.statusCode == 200 || response.statusCode == 201) {
//                completion(nil); return
//            }
//
//            do {
//                guard let resultsDict = try JSONSerialization.jsonObject(with: results, options: JSONSerialization.ReadingOptions.mutableLeaves) as? [String: Any] else { completion(nil); return }
//
//                completion(resultsDict)
//
//            } catch {
//                print(error.localizedDescription)
//            }
//        }
//
//        task.resume()
//    }
//
//    // 翻訳テキストが複数であり、それぞれsrcLangは異なるため、
//    // こちらで明示的に渡さなくてもAPI側で自動的に検知してくれる？
//    func translate(transTextArr: [String], transLang: String, completion: @escaping (_ allTransTexts: [String]?) -> Void) {
//
//        print("Start translating text...")
//
//        var urlParams = [String: Any]()
//        urlParams["key"] = apiKey
//        urlParams["q"] = transTextArr
//        urlParams["target"] = transLang
////        urlParams["source"] = srcLang
//        urlParams["format"] = "text"
//
//        print("Translating text in", transLang)
//
////        if transLang == srcLang {
////            DispatchQueue.main.async {
////                completion(transTextArr, transLang)
////            }
////            return
////        }
//
//        makeRequest(usingTranslationAPI: .translate, urlParams: urlParams) { (results) in
//            guard let results = results else { completion(nil); return }
//
//            guard let data = results["data"] as? [String: Any], let translations = data["translations"] as? [[String: Any]] else { completion(nil); return }
//
//            var allTransTexts = [String]()
//            for translation in translations {
//                if let transText = translation["translatedText"] as? String {
//                    allTransTexts.append(transText)
//                }
//            }
//
//            DispatchQueue.main.async {
//                completion(allTransTexts)
//            }
//        }
//    }
    
    //    func translate(textToTranslate: String, langArr: [String], sourceLangCode: String, completion: @escaping (_ translatedText: String?, _ translateLang: String?) -> Void) {
    //
    //        print("Start translating text...")
    //
    //        var urlParams = [String: String]()
    //        urlParams["key"] = apiKey
    //        urlParams["q"] = textToTranslate
    //        urlParams["source"] = sourceLangCode
    //        urlParams["format"] = "text"
    //
    //         for targetLang in langArr {
    //
    //            print("Translating text in", targetLang)
    //
    //            if targetLang == sourceLangCode {
    //                DispatchQueue.main.async {
    //                    completion(textToTranslate, targetLang)
    //                }
    //                continue
    //            }
    //
    //            urlParams["target"] = targetLang
    //
    //            makeRequest(usingTranslationAPI: .translate, urlParams: urlParams) { (results) in
    //                guard let results = results else { completion(nil, nil); return }
    //
    //                guard let data = results["data"] as? [String: Any], let translations = data["translations"] as? [[String: Any]] else { completion(nil, nil); return }
    //
    //                guard let translatedText = translations.first?["translatedText"] as? String else { completion(nil, nil); return }
    //
    //                print("translatedText", !translatedText.isEmpty ? translatedText : "nil")
    //                print("targetLang", targetLang)
    //
    //                DispatchQueue.main.async {
    //                    completion(translatedText, targetLang)
    //                }
    //            }
    //        }
    //    }
    
    func fetchSupportedLanguages(completion: @escaping (_ langList: [[String: String]]) -> Void) {
        
        print("device lang code", Locale.current.languageCode ?? "nil")
        
        guard let currentUser = User.currentUser else { return }
        
        functions
            .httpsCallable("onFetchSupportedLangs").call([
                "userLang": currentUser.lang,
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
                
                guard let languages = result?.data as? [[String: String]]  else {
                    print("Error converting results...")
                    return
                }
                
                completion(languages)
                
//                var supportedLanguages = [[String: String]]()
//                for lang in languages {
//
//                    guard let langCode = lang["language"] as? String,
//                          let langName = lang["name"] as? String else {
//                        completion(nil); return
//                    }
//
//                    supportedLanguages.append(["code": langCode, "name": langName])
//                }
//
//                DispatchQueue.main.async {
//                    completion(supportedLanguages)
//                }
            }
    }
    
//    func fetchSupportedLanguages(completion: @escaping (_ langList: [[String: String]]?) -> Void) {
//
//        print("device lang code", Locale.current.languageCode ?? "nil")
//
//        var urlParams = [String: String]()
//        urlParams["key"] = apiKey
//        urlParams["target"] = Locale.current.languageCode ?? "en"
//
//        makeRequest(usingTranslationAPI: .supportedLanguages, urlParams: urlParams) { results in
//
//            guard let results = results else {
//                completion(nil); return
//            }
//
//            guard let data = results["data"] as? [String: Any],
//                  let languages = data["languages"] as? [[String: Any]] else {
//                completion(nil); return
//            }
//
//            var supportedLanguages = [[String: String]]()
//            for lang in languages {
//
//                guard let langCode = lang["language"] as? String,
//                      let langName = lang["name"] as? String else {
//                    completion(nil); return
//                }
//
//                supportedLanguages.append(["code": langCode, "name": langName])
//            }
//
//            DispatchQueue.main.async {
//                completion(supportedLanguages)
//            }
//        }
//    }
}
