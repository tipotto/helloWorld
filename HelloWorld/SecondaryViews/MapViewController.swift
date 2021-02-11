//
//  MapViewController.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/27.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {

    // MARK: - Vars
    var location: CLLocation?
    var mapView: MKMapView!
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        print("MapView's viewDidLoad is executed...")
        super.viewDidLoad()
        configureTitle()
        configureMapView()
        configureLeftBarButton()
        configureRightBarButton()
    }

    // MARK: - Configurations
    private func configureMapView() {
        mapView = MKMapView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height))
        mapView.showsUserLocation = true
        
        if location != nil {
            print("location is not nil...")
            let coordinate = location!.coordinate
            mapView.setCenter(coordinate, animated: false)
            let annotation = MapAnnotation(title: "User Location", coordinate: coordinate)
            mapView.addAnnotation(annotation)
            
//            centerMapOnLocation(location!, mapView: mapView)
        
        } else {
            print("location is nil...")
        }
        
        view.addSubview(mapView)
        
    }
    
//    private func centerMapOnLocation(_ location: CLLocation, mapView: MKMapView) {
//        print("centerMapOnLocation")
//
//        // マップの拡大率を変えるときは、regionRadiusを変更
//        let regionRadius: CLLocationDistance = 10000
//        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
//                                                  latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
//        mapView.setRegion(coordinateRegion, animated: true)
//    }
    
    private func configureLeftBarButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backButtonPressed))
    }

    private func configureRightBarButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Open in Map", style: .plain, target: self, action: #selector(openInMap))
    }
    
    private func configureTitle() {
        title = "Map View"
    }
    
    @objc func backButtonPressed() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func openInMap() {

        guard let location = location else { return }

        let regionDestination: CLLocationDistance = 1000
        let coordinates = location.coordinate

        let regionSpan = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionDestination, longitudinalMeters: regionDestination)

        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]

        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "User Location"
        mapItem.openInMaps(launchOptions: options)
    }
    
//    @objc func openInGoogleMap() {
//
//        guard let location = location else { return }
//
//        let lat = Double(location.coordinate.latitude)
//        let long = Double(location.coordinate.longitude)
//
//        let googleMapAppUrl = URL(string:"comgooglemaps://")!
//        let isInstalled = UIApplication.shared.canOpenURL(googleMapAppUrl)
//
//        print("isInstalled", isInstalled)
//
//        if isInstalled {
//            // iPhone has an app
//            if let url = URL(string: "comgooglemaps-x-callback://?saddr=&daddr=\(lat),\(long)&directionsmode=driving") {
//                UIApplication.shared.open(url, options: [:])
//            }}
//
//        else {
//            // Open in browser
//            if let urlDestination = URL.init(string: "https://www.google.co.in/maps/dir/?saddr=&daddr=\(lat),\(long)&directionsmode=driving") {
//                UIApplication.shared.open(urlDestination)
//            }
//        }
//    }
}
