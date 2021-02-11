//
//  LocationManager.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/27.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    static let shared = LocationManager()
    
    var locationManager: CLLocationManager?
    var authStatus = kNOTDETERMINED
    var isUpdatelocation = false
    var currentLocation: CLLocationCoordinate2D?
    
    // 一度インスタンスが生成された後は呼ばれない？
    private override init() {
        super.init()
        print("### init start ###")
//        configureLocationManager()
    }

    func configureLocationManager() {
        locationManager = CLLocationManager()
        locationManager!.delegate = self
        locationManager!.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func startUpdating() {
//        if locationManager == nil {
//            print("### locationManager is nil ###")
//            configureLocationManager()
//        }
        
        if isUpdatelocation { return }
        
        print("start updating location")
        locationManager!.startUpdatingLocation()
        isUpdatelocation = true
    }
    
    func stopUpdating() {
//        if locationManager == nil {
//            print("### locationManager is nil ###")
//            configureLocationManager()
//        }
        
        if !isUpdatelocation { return }
        
        print("stop updating location")
        locationManager!.stopUpdatingLocation()
        isUpdatelocation = false
    }
    
    // MARK: - Delegate
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location", error.localizedDescription)
    }
    
    // ユーザーデバイスのロケーションを更新（座標が変わる度に実行）
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last!.coordinate
    }
    
    // ユーザーに位置情報を取得する許可を求めるポップアップを表示する
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
//        print("authorization status(notDetermined)", manager.authorizationStatus == .notDetermined)
//        
//        print("authorization status(authorizedWhenInUse)", manager.authorizationStatus == .authorizedWhenInUse)
        
        let status = manager.authorizationStatus
        switch status {
        case .notDetermined:
            authStatus = kNOTDETERMINED
            locationManager!.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            authStatus = kAUTHORIZEDWHENINUSE
            startUpdating()
            print("Authorized When In Use")
        case .authorizedAlways:
            authStatus = kAUTHORIZEDALWAYS
            startUpdating()
            print("Authorized Always")
        case .restricted:
            authStatus = kRESTRICTED
            print("Restricted")
        case .denied:
            authStatus = kDENIED
            print("Denied location access")
        @unknown default:
            authStatus = kNOTDETERMINED
            print("Unknown cases")
        }
    }
}

