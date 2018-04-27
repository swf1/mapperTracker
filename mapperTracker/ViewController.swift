//
//  ViewController.swift
//  mapperTracker
//
//  Created by Jason Hoffman on 4/14/18.
//  Copyright © 2018 Jason Hoffman. All rights reserved.
//

import UIKit
import CoreLocation
import Mapbox

class ViewController: UIViewController {
    
    @IBOutlet weak var mapboxView: MGLMapView!
    @IBOutlet weak var centerButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var toggleButton: UIButton!
    @IBOutlet weak var paceLabel: UILabel!
    @IBOutlet weak var avgPaceLabel: UILabel!
    
    var locationManager: CLLocationManager!
    var regionRadius: CLLocationDistance = 500
    var coordinateArray = [CLLocationCoordinate2D]()
    var cam = MGLMapCamera()
    var course: Double = 0.0
    var log = false
    var courseView = false
    var firstLast: [CLLocationCoordinate2D]?  // for start and end coordinate. should be added to activity object
    // For simulated reading from DB
    let fileManager = FileManager.default
    var paceArray = [Double]() // To calc average pace
    var df = DateComponentsFormatter()  // For time display
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // energy expensive
        locationManager.activityType = .fitness
        locationManager.startUpdatingLocation()
        
        mapboxView.delegate = self
        mapboxView.isPitchEnabled = true
        mapboxView.showsHeading = false
        mapboxView.compassView.isHidden = true
        
        mapboxView.attributionButton.isHidden = true
        mapboxView.logoView.isHidden = true
        
        df.allowedUnits = [.minute, .second]
        df.zeroFormattingBehavior = .pad
        
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
    @IBAction func toggleButtonPressed(_ sender: Any) {
        courseView ? topMode() : courseMode()
        courseView = !courseView
    }
    
    @IBAction func renderFromPolylineString(_ sender: Any) {
        locationManager.stopUpdatingLocation()
        readPolylineFromFile()
    }
    
    func courseMode() {
        mapboxView.userTrackingMode = .followWithCourse
        mapboxView.setCamera(
            MGLMapCamera(
                lookingAtCenter: mapboxView.userLocation!.coordinate,
                fromDistance: 500,
                pitch: 70.0,
                heading: mapboxView.camera.heading),
                animated: true
            )
    }
    
    func topMode() {
        mapboxView.userTrackingMode = .follow
        mapboxView.setCamera(
            MGLMapCamera(
                lookingAtCenter: mapboxView.userLocation!.coordinate,
                fromDistance: 1500,
                pitch: 0.0,
                heading: mapboxView.camera.heading),
                animated: true
            )
    }
    
    // Center the map
    func centerMapOnUserLocation() {
        if let loc = mapboxView.userLocation {
            mapboxView.setCenter(loc.coordinate, zoomLevel: 15.0, animated: true)
        }
    }
    
    
    // For annotations at start and end
    func annotationsAt(coordinates: [CLLocationCoordinate2D]) {
        var annotations = [MGLPointAnnotation]()
        for c in coordinates {
            let p = MGLPointAnnotation()
            p.coordinate = c
            annotations.append(p)
        }
        
        mapboxView.addAnnotations(annotations)
    }
    
    // Pace and average pace can be smoothed by checking for accuracy
    // of GPS coordinates:
    //  - no cell towers, no points older than previous, unrealistic acceleration or horiz accuracy low
    
    
    // Rough pace based off speed
    func pace() -> String {
        let mps = Measurement(value: locationManager.location!.speed, unit: UnitSpeed.metersPerSecond)
        let mph = mps.converted(to: .milesPerHour)
        let paceInSeconds = 3600.0 / mph.value
        paceArray.append(paceInSeconds)
        guard let formattedPace = df.string(from: paceInSeconds) else { return "Err" }
        return formattedPace
    }
    
    func avgPace() -> String {
        let s = paceArray.reduce(0.0, +)
        let avg = s / Double(paceArray.count)
        guard let avgPace = df.string(from: avg) else { return "Err" }
        return avgPace
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
        
        
    }
    
    func logLocation() {
        locationManager.startUpdatingLocation()
    }
}

// MARK: MGLMapViewDeleage

extension ViewController: MGLMapViewDelegate {
    
    // Functions for simulating db write
    func writePolylineToFile(_ data: Data) {
        let name = "pline.txt"
        if let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(name)
            do {
                try data.write(to: fileURL)
            } catch {
                print("Error writing file")
            }
        }
        
    }
    
    // Function for simulating db read
    func readPolylineFromFile() {

        if let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent("pline.txt")

            do {
                let data = try Data(contentsOf: fileURL)
                let shapeCollection = try! MGLShape(data: data, encoding: String.Encoding.utf8.rawValue) as! MGLPolylineFeature
                
                 //Add  annotation at start and end
                if let fl = firstLast {
                    annotationsAt(coordinates: fl)
                }
                
                mapboxView.add(shapeCollection)
                
            } catch { print("error creating shape") }
        }
    }
    
    func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) {
        if log {
            if let loc = locationManager.location {
//                print("Lat: " + String(loc.coordinate.latitude))
//                print("Lon: " + String(loc.coordinate.longitude))
//                print("Speed: " + String(loc.speed))
                paceLabel.text = pace()
                avgPaceLabel.text = avgPace()
                coordinateArray.append((loc.coordinate))
            }
            
            firstLast = [coordinateArray[0], coordinateArray[coordinateArray.count - 1]]
            let pline = MGLPolyline(coordinates: coordinateArray, count: UInt(coordinateArray.count))
            let encoded = pline.geoJSONData(usingEncoding: String.Encoding.utf8.rawValue)
            writePolylineToFile(encoded)
            
            mapboxView.add(pline)
        }
        
        // Course smoothing not necessary with mapbox
    }
    
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        let start = UIImage(named: "play-circle")
        var annotationImage = MGLAnnotationImage(image: start!, reuseIdentifier: "start")
        
        return annotationImage
    }
    
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        guard annotation is MGLPointAnnotation else {
            return nil
        }
        
        let reuseIdentifier = "\(annotation.coordinate.longitude)"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        

        // If there’s no reusable annotation view available, initialize a new one.
        if annotationView == nil {
            annotationView = MGLAnnotationView(reuseIdentifier: reuseIdentifier)
            annotationView!.frame = CGRect(x: 0, y: 0, width: 20, height: 20)

            annotationView?.backgroundColor = UIColor.red
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        if annotation.title == "recalled" {
            return UIColor.blue
        }

        return UIColor.orange
    }
    
    func mapView(_ mapView: MGLMapView, lineWidthForPolylineAnnotation annotation: MGLPolyline) -> CGFloat {
        return 5.0
    }
}
