//
//  FileStorage.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/12.
//

import Foundation
import FirebaseStorage
import ProgressHUD

let storage = Storage.storage()

class FileStorage {

    // MARK: - Images
    class func uploadImage(_ image: UIImage, directory: String, completion: @escaping (_ documentLink: String?) -> Void) {
        
        let storageRef = storage.reference(forURL: kFILEREFERENCE).child(directory)

        // 画像（UIImage）をjpegに変換
        guard let imageData = image.jpegData(compressionQuality: 0.6) else {
            completion(nil)
            return
        }
        
        var task: StorageUploadTask!
        
        // Firebase Storageに画像を保存
        task = storageRef.putData(imageData, metadata: nil) { (metadata, error) in
            
            task.removeAllObservers()
            ProgressHUD.dismiss()
            
            if error != nil {
                print("error uploading image", error!.localizedDescription)
                completion(nil)
                return
            }
            
            // 保存先のURLをダウンロード
            storageRef.downloadURL { (url, error) in
                guard let downloadUrl = url else {
                    completion(nil)
                    return
                }
                
                completion(downloadUrl.absoluteString)
            }
        }
        
        // putDataメソッドは非同期処理のため、実行され次第以下の処理に移る
        // putDataメソッドの実行結果を受け取り次第、
        // 以下の処理は削除され、ProguressHUDもdismissされる
        task.observe(StorageTaskStatus.progress) { snapshot in
            
            guard let progress = snapshot.progress else {
                completion(nil)
                return
            }
            
            let progressCount = progress.completedUnitCount / progress.totalUnitCount
            ProgressHUD.showProgress(CGFloat(progressCount))
        }
    }

    class func downloadImage(imageUrl: String, completion: @escaping (_ image: UIImage?) -> Void) {

        if imageUrl.isEmpty {
            completion(nil)
            return
        }

        guard let imageFileName = fileNameFrom(fileUrl: imageUrl) else {
            completion(nil)
            return
        }

        // iPhoneのDocumentsフォルダに画像が存在する場合
        if fileExistsAtPath(path: imageFileName) {
            print("Get image from local storage.")

            let fileContents = fileInDocumentsDirectory(fileName: imageFileName)
            completion(UIImage(contentsOfFile: fileContents))
            return
        }

        // iPhoneのDocumentsフォルダに画像が存在しない場合
        // Firebase Storageから画像を取得する
        print("Download image from database.")
        guard let documentUrl = URL(string: imageUrl) else {
            completion(nil)
            return
        }

        // サブスレッドでイメージを取得
        // Custom Serial Queue
//        DispatchQueue.global().async {
        DispatchQueue(label: "imageDownloadQueue").async {
            guard let imageData = NSData(contentsOf: documentUrl) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            // iPhoneのDocumentsフォルダに画像を保存
            saveFileLocally(fileData: imageData, fileName: imageFileName)

            // UIImageをクロージャーに渡す際に、Mainスレッドで処理する必要があるのか？
            // Main Queue
            DispatchQueue.main.async {
                completion(UIImage(data: imageData as Data))
            }
        }
    }
    
//    class func downloadImage(imageUrl: String, completion: @escaping (_ image: UIImage?) -> Void) {
//
//        let imageFileName = fileNameFrom(fileUrl: imageUrl)
//
//        if fileExistsAtPath(path: imageFileName!) {
//            if let contentsOfFile = UIImage(contentsOfFile: fileInDocumentsDirectory(fileName: imageFileName!)) {
//                completion(contentsOfFile)
//
//            } else {
//                print("couldnt convert local image")
//                completion(UIImage(named: "avatar"))
//            }
//
//        } else {
//            if imageUrl != "" {
//
//                let documentUrl = URL(string: imageUrl)
//
//                let downloadQueue = DispatchQueue(label: "imageDownloadQueue")
//                downloadQueue.async {
//
//                    let data = NSData(contentsOf: documentUrl!)
//
//                    if data != nil {
//
//                        //Save locally
//                        FileStorage.saveFileLocally(fileData: data!, fileName: imageFileName!)
//
//                        DispatchQueue.main.async {
//                            completion(UIImage(data: data! as Data))
//                        }
//
//                    } else {
//                        print("no document in database")
//                        DispatchQueue.main.async {
//                            completion(nil)
//                        }
//                    }
//                }
//            }
//        }
//    }
    
    // MARK: - Video
    class func uploadVideo(_ video: NSData, directory: String, completion: @escaping (_ videoLink: String?) -> Void) {
        
        let storageRef = storage.reference(forURL: kFILEREFERENCE).child(directory)

        
        var task: StorageUploadTask!
        
        // Firebase Storageに画像を保存
        task = storageRef.putData(video as Data, metadata: nil) { (metadata, error) in
            
            task.removeAllObservers()
            ProgressHUD.dismiss()
            
            if error != nil {
                print("error uploading video", error!.localizedDescription)
                completion(nil)
                return
            }
            
            // 保存先のURLをダウンロード
            storageRef.downloadURL { (url, error) in
                guard let downloadUrl = url else {
                    completion(nil)
                    return
                }
                
                completion(downloadUrl.absoluteString)
            }
        }
        
        // putDataメソッドは非同期処理のため、実行され次第以下の処理に移る
        // putDataメソッドの実行結果を受け取り次第、
        // 以下の処理は削除され、ProguressHUDもdismissされる
        task.observe(StorageTaskStatus.progress) { snapshot in
            
            guard let progress = snapshot.progress else {
                completion(nil)
                return
            }
            
            let progressCount = progress.completedUnitCount / progress.totalUnitCount
            ProgressHUD.showProgress(CGFloat(progressCount))
        }
    }
    
    class func downloadVideo(videoUrl: String, completion: @escaping (_ isReadyToPlay: Bool, _ videoFileName: String) -> Void) {
        
        let videoFileName = fileNameFrom(fileUrl: videoUrl)! + ".mov"
        
        if fileExistsAtPath(path: videoFileName) {
                completion(true, videoFileName)

        } else {
            
            let downloadQueue = DispatchQueue(label: "videoDownloadQueue")
            downloadQueue.async {
                
                let videoUrl = URL(string: videoUrl)
                let data = NSData(contentsOf: videoUrl!)
                
                if data != nil {
                    
                    //Save locally
                    FileStorage.saveFileLocally(fileData: data!, fileName: videoFileName)
                    
                    DispatchQueue.main.async {
                        completion(true, videoFileName)
                    }
                    
                } else {
                    print("no document in database")
                }
            }
        }
    }
    
    // MARK: - Audio
    class func uploadAudio(_ filePath: String, fileName: String, directory: String, completion: @escaping (_ audioLink: String?) -> Void) {
        
//        let fileName = audioFileName + ".m4a"
        
        let storageRef = storage.reference(forURL: kFILEREFERENCE).child(directory)

        var task: StorageUploadTask!
        
        // iPhoneのtmpフォルダに音声ファイルが存在するか確認
        if !FileManager.default.fileExists(atPath: filePath) {
            print("Nothing to upload...")
            completion(nil)
            return
        }
        
        guard let audioData = NSData(contentsOfFile: filePath) else {
            completion(nil)
            return
        }
        
        // iPhoneのDocumentsフォルダに保存
        // この時にtmpフォルダにあるデータは削除した方が良いかも
        FileStorage.saveFileLocally(fileData: audioData, fileName: "\(fileName).m4a")
        
        // Firebase Storageに保存
        task = storageRef.putData(audioData as Data, metadata: nil) { (metadata, error) in
            
            task.removeAllObservers()
            ProgressHUD.dismiss()
            
            if error != nil {
                print("error uploading audio", error!.localizedDescription)
                completion(nil)
                return
            }
            
            // 保存先のURLをダウンロード
            storageRef.downloadURL { (url, error) in
                guard let downloadUrl = url else {
                    completion(nil)
                    return
                }
                
                completion(downloadUrl.absoluteString)
            }
        }
        
        // putDataメソッドは非同期処理のため、実行され次第以下の処理に移る
        // putDataメソッドの実行結果を受け取り次第、
        // 以下の処理は削除され、ProguressHUDもdismissされる
        task.observe(StorageTaskStatus.progress) { snapshot in
            
            guard let progress = snapshot.progress else {
                completion(nil)
                return
            }
            
            let progressCount = progress.completedUnitCount / progress.totalUnitCount
            ProgressHUD.showProgress(CGFloat(progressCount))
        }
        
    }
    
//    class func uploadAudio(_ audioFileName: String, directory: String, completion: @escaping (_ audioLink: String?) -> Void) {
//
//        let fileName = audioFileName + ".m4a"
//
//        let storageRef = storage.reference(forURL: kFILEREFERENCE).child(directory)
//
//        var task: StorageUploadTask!
//
//        if !fileExistsAtPath(path: fileName) {
//            print("Nothing to upload...")
//            completion(nil)
//            return
//        }
//
//        guard let audioData = NSData(contentsOfFile: fileInDocumentsDirectory(fileName: fileName)) else {
//            completion(nil)
//            return
//        }
//
//        // Firebase Storageに画像を保存
//        task = storageRef.putData(audioData as Data, metadata: nil) { (metadata, error) in
//
//            task.removeAllObservers()
//            ProgressHUD.dismiss()
//
//            if error != nil {
//                print("error uploading audio", error!.localizedDescription)
//                completion(nil)
//                return
//            }
//
//            // 保存先のURLをダウンロード
//            storageRef.downloadURL { (url, error) in
//                guard let downloadUrl = url else {
//                    completion(nil)
//                    return
//                }
//
//                completion(downloadUrl.absoluteString)
//            }
//        }
//
//        // putDataメソッドは非同期処理のため、実行され次第以下の処理に移る
//        // putDataメソッドの実行結果を受け取り次第、
//        // 以下の処理は削除され、ProguressHUDもdismissされる
//        task.observe(StorageTaskStatus.progress) { snapshot in
//
//            guard let progress = snapshot.progress else {
//                completion(nil)
//                return
//            }
//
//            let progressCount = progress.completedUnitCount / progress.totalUnitCount
//            ProgressHUD.showProgress(CGFloat(progressCount))
//        }
//
//    }
    
    class func downloadAudio(audioUrl: String, completion: @escaping (_ audioFileName: String) -> Void) {
        
        let audioFileName = fileNameFrom(fileUrl: audioUrl)! + ".m4a"
        
        if fileExistsAtPath(path: audioFileName) {
                completion(audioFileName)

        } else {
            
            let downloadQueue = DispatchQueue(label: "audioDownloadQueue")
            downloadQueue.async {
                
                let audioUrl = URL(string: audioUrl)
                let data = NSData(contentsOf: audioUrl!)
                
                if data != nil {
                    
                    //Save locally
                    FileStorage.saveFileLocally(fileData: data!, fileName: audioFileName)
                    
                    DispatchQueue.main.async {
                        completion(audioFileName)
                    }
                    
                } else {
                    print("no audio in database")
                }
            }
        }
    }
    
    // MARK: - Save locally
    // atomically: 指定したパスに既にファイルが存在する場合、上書きせずにバックアップとして残しておき、
    // 新規ファイルの作成が完了した後に削除する
    class func saveFileLocally(fileData: NSData, fileName: String) {
        let docUrl = getDocumentsURL().appendingPathComponent(fileName, isDirectory: false)
        fileData.write(to: docUrl, atomically: true)
    }
}

// MARK: - Helpers
// Documentsディレクトリ内に特定のファイルが存在するか確認
func fileExistsAtPath(path: String) -> Bool {
    let filePath = fileInDocumentsDirectory(fileName: path)
    return FileManager.default.fileExists(atPath: filePath)
}

// Documentディレクトリ内にある特定のファイルのパスを取得
func fileInDocumentsDirectory(fileName: String) -> String {
    return getDocumentsURL().appendingPathComponent(fileName).path
}

// iPhone内のDocumentディレクトリのパスを取得
func getDocumentsURL() -> URL {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
}

