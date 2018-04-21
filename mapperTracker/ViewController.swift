//
//  ViewController.swift
//  mapperTracker
//
//  Created by Jason Hoffman on 4/14/18.
//  Copyright © 2018 Jason Hoffman. All rights reserved.
//

import UIKit
import Mapbox

class ViewController: UIViewController {
    
    @IBOutlet weak var mapboxView: MGLMapView!
    @IBOutlet weak var centerButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var northUp: UIButton!
    
    var locationManager: CLLocationManager!
    var regionRadius: CLLocationDistance = 500
    var coordinateArray = [CLLocationCoordinate2D]()
    var cam = MGLMapCamera()
    var course: Double = 0.0
    var log = false
    var courseView = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // energy expensive
        locationManager.startUpdatingLocation()
        
        mapboxView.delegate = self
        mapboxView.isPitchEnabled = true
        mapboxView.showsHeading = false
        
        // Request location access
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            locationManager.requestAlwaysAuthorization()
            mapboxView.showsUserLocation = true
            mapboxView.userTrackingMode = .follow
        }
        
        //        if mapboxView.isUserLocationVisible {
        //            if let loc = mapboxView.userLocation {
        //                mapboxView.setCenter(loc.coordinate, zoomLevel: 20.0, animated: true)
        //            }
        //        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let loc = locationManager.location {
            mapboxView.setCenter(loc.coordinate, zoomLevel: 17.0, animated: true)
        }
    }
    
    @IBAction func centerButtonPressed(_ sender: Any) {
        centerMapOnUserLocation()
    }
    
    @IBAction func goButtonPressed(_ sender: Any) {
        logLocation()
        log = !log
    }
    
    // 'north up' vs course toggle
    @IBAction func northButtonPressed(_ sender: Any) {
        courseView ? topMode() : courseMode()
        courseView = !courseView
    }
    
    func courseMode() {
        mapboxView.userTrackingMode = .followWithCourse
        mapboxView.camera.pitch = 70
        mapboxView.setZoomLevel(20.0, animated: true)
        
    }
    
    func topMode() {
        mapboxView.userTrackingMode = .follow
        mapboxView.camera.pitch = 0
        mapboxView.setZoomLevel(20.0, animated: true)
    }
    
    // Center the map
    func centerMapOnUserLocation() {
        mapboxView.setCenter(mapboxView.userLocation!.coordinate, zoomLevel: 25.0, animated: true)
    }
    
}

// MARK: CLLocationManagerDelegate

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            mapboxView.showsUserLocation = true
        }
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // Apple says to throw away cached results
        // Could come into play in tracking pace
        //        let location = locations.last
        //        let locTime = location?.timestamp
        //        let howRecent = locTime?.timeIntervalSinceNow
        
        //        if (howRecent < 5.0) {
        //            print("recent")
        //        }
        
        // Moved to MKMapViewDelegate
        // Update course when location updates
        //        if courseView {
        //            if let loc = locationManager.location {
        //                // Ignore minor course changes
        //                if loc.course >= (course + 2.0) || loc.course <= (course - 2.0) {
        //                    mapView.camera.heading = loc.course
        //                    course = loc.course
        //                }
        //
        //                print("Course: " + String(round(loc.course)))
        //                mapView.setCamera(mapView.camera, animated: true)
        //            }
        //        }
    }
    
    func logLocation() {
        locationManager.startUpdatingLocation()
        mapboxView.camera.pitch = 0
    }
}

// MARK: MKMapViewDeleage

extension ViewController: MGLMapViewDelegate {
    
    func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) {
        if log {
            if let loc = locationManager.location {
                //                print("Lat: " + String(loc.coordinate.latitude))
                //                print("Lon: " + String(loc.coordinate.longitude))
                //                print("Speed: " + String(loc.speed))
                
                coordinateArray.append((loc.coordinate))
            }
            
            let pline = MGLPolyline(coordinates: coordinateArray, count: UInt(coordinateArray.count))
            let encoded = pline.geoJSONData(usingEncoding: String.Encoding.utf8.rawValue)
            mapboxView.add(pline)
        }
        
        // Course smoothing not necessary with mapbox
    }
    
    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        return UIColor.orange
    }
    
    func mapView(_ mapView: MGLMapView, lineWidthForPolylineAnnotation annotation: MGLPolyline) -> CGFloat {
        return 5.0
    }
}
