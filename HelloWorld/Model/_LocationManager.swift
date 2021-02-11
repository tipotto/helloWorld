//
//  LocationManager.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/27.
//

import Foundation
import CoreLocation

class _LocationManager: NSObject, CLLocationManagerDelegate {
    
    static let shared = _LocationManager()
    
    var locationManager: CLLocationManager?
    var currentLocation: CLLocationCoordinate2D?
    
    private override init() {
        super.init()
        
        requestLocationAccess()
    }
    
    func requestLocationAccess() {
        print("Request Location Access...")
        if locationManager != nil { return }
        print("Location Manager is nil...")
        
        locationManager = CLLocationManager()
        locationManager!.delegate = self
        locationManager!.desiredAccuracy = kCLLocationAccuracyBest
        locationManager!.requestWhenInUseAuthorization()
    }
    
    func startUpdating() {
        print("start updating location")
        locationManager!.startUpdatingLocation()
    }
    
    func stopUpdating() {
        if locationManager == nil { return }
        print("stop updating location")
        locationManager!.stopUpdatingLocation()
    }
    
    // MARK: - Delegate
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location...")
    }
    
    // ユーザーの端末のロケーションを更新（座標が変わる度に実行）
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last!.coordinate
    }
    
    // ユーザーに位置情報を取得する許可を求めるポップアップを表示する
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus != .notDetermined { return }
        locationManager!.requestWhenInUseAuthorization()
        
//        let status = manager.authorizationStatus
//        switch status {
//        case .notDetermined:
//            locationManager!.requestWhenInUseAuthorization()
//        case .authorizedWhenInUse:
//            startUpdating()
//        case .authorizedAlways:
//            startUpdating()
//        case .restricted:
//            print("Restricted")
//        case .denied:
//            print("Denied location access")
//        }
    }
}
