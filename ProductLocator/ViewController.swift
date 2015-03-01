//
//  ViewController.swift
//  ProductLocator
//
//  Created by Gerald Dunn on 2/27/15.
//  Copyright (c) 2015 Gerald Dunn. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager: CLLocationManager = CLLocationManager()
    var annotations: Array<MKPointAnnotation>!
    var foundUserLocation = false
    var droppingPins = false

    // these will hold current location, set some defaults justin case
    var latitude: Double = 37.7710347
    var longitude: Double = -122.4040795
    
    let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
   
        mapView.delegate = self
        
        // Get the current location
        self.requestLocation()
        
       
        // Code to get the bounding box of the visible map area
        /*
        var getLat: CLLocationDegrees = mapView.centerCoordinate.latitude
        var getLng: CLLocationDegrees = mapView.centerCoordinate.longitude
        let rect = self.mapView.visibleMapRect
        let neCoord = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMaxX(rect), rect.origin.y))
        let swCoord = MKCoordinateForMapPoint(MKMapPointMake(rect.origin.x, MKMapRectGetMaxY(rect)))
        println("\(swCoord.latitude),\(swCoord.longitude)|\(neCoord.latitude),\(neCoord.longitude)")
        */
        
        // array to hold map pins
        self.annotations = []
        
        // Example of how to read json from a file
        let filePath = NSBundle.mainBundle().pathForResource("data",ofType:"json")
        var readError:NSError?
        if let data = NSData(contentsOfFile:filePath!, options:NSDataReadingOptions.DataReadingUncached, error:&readError) {
            var jsonErrorOptional: NSError?
            if let jsonResult = NSJSONSerialization.JSONObjectWithData(data, options: nil, error:&jsonErrorOptional) as? NSDictionary {
                if let tmpStoreName = jsonResult["store_dsc"] as? String {
                    let myStoreName = tmpStoreName
                    println(myStoreName)
                }
                if let tmpStoreAddress = jsonResult["address"] as? String {
                    let myStoreAddress = tmpStoreAddress
                    println(myStoreAddress)
                }
            }
        }
        
        //getStore()
        //getStores()
        
        // Code to add array of annotation map pins
        //self.mapView.addAnnotations(self.annotations)
        
        
        /* Code to drop map pins
        self.annotations = []
        for business in results {
        let annotation = MKPointAnnotation()
        let coordinate = CLLocationCoordinate2D(latitude: business.latitude!, longitude: business.longitude!)
        annotation.setCoordinate(coordinate)
        annotation.title = business.name
        annotation.subtitle = business.displayCategories
        self.annotations.append(annotation)
        }
        self.mapView.addAnnotations(self.annotations)
        */
        
    }
    
    
    func getStores()
    {
        if droppingPins {
            return
        }
        
        activityIndicator.frame = CGRectMake(100, 100, 100, 100);
        activityIndicator.startAnimating()
        activityIndicator.center = self.view.center
        self.view.addSubview( activityIndicator )
        
        let loc : CLLocationCoordinate2D  = mapView.centerCoordinate
        
        let baseURL = "https://api.cbrands.com/beta/productlocations.json?apiKey=jet&stateRestriction=Y&latitude=\(self.latitude)&longitude=\(self.longitude)&brandCode=631&varietalCode=198&radiusInMiles=15&premiseTypeDesc=OFF%20PREMISE&from=0&to=50"
        
        println(self.latitude)
        println(self.longitude)
        
        
        let manager = AFHTTPRequestOperationManager()
        manager.GET( baseURL,
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!,responseObject: AnyObject!) in
                //println("JSON: " + String(responseObject.description))
                
                var storeName = ""
                var storeAddress = ""
                var storeState = ""
                var storeCity = ""
                var storeZip = ""
                var storePhone = ""
                var storeLat : Double = 0.00
                var storeLng : Double = 0.00
                
                var lastStore : String = ""
                var currentStore : String = ""
                
                if let productLocation = responseObject as? NSDictionary {
                   
                    if let prodLocs = productLocation["productLocation"] as? NSArray {
          
                        if prodLocs.count == 0
                        {
                            println("no locs")
                        }
                        else
                        {
                            for index in 0...prodLocs.count-1 {
                                let currentStore = ((prodLocs[index]["storeName"]) as String)
                                if (currentStore != lastStore) {
                                    //println((prodLocs[index]["storeName"]) as String)
                                    //println((prodLocs[index]["latitude"]) as Float)
                                    //println((prodLocs[index]["longitude"]) as Float)
                                
                                    if let tmpStoreName = prodLocs[index]["storeName"] as? String {
                                        storeName = tmpStoreName
                                    }
                                    
                                    if let tmpStoreAddress = prodLocs[index]["addr01Dsc"] as? String {
                                        storeAddress = tmpStoreAddress
                                    }
                                    
                                    if let tmpStoreCity = prodLocs[index]["cityDsc"] as? String {
                                        storeCity = tmpStoreCity
                                    }
                                    
                                    if let tmpStoreLat = prodLocs[index]["latitude"] as? Double {
                                        storeLat = tmpStoreLat
                                    }
                                    if let tmpStoreLng = prodLocs[index]["longitude"] as? Double {
                                        storeLng = tmpStoreLng
                                    }
                                    
                                    let annotation = MKPointAnnotation()
                                    let coordinate = CLLocationCoordinate2D(latitude: storeLat, longitude: storeLng)
                                    annotation.setCoordinate(coordinate)
                                    annotation.title = storeName
                                    annotation.subtitle = storeAddress + " " + storeCity
                                    //self.annotations.append(annotation)
                                    self.mapView.addAnnotation(annotation)
                                    
                                }
                                lastStore = ((prodLocs[index]["storeName"]) as String)
                            }
                        }
                    }
                }
                self.activityIndicator.stopAnimating()
      
            },
            failure: { (operation: AFHTTPRequestOperation!,error: NSError!) in
                println("Error: " + error.localizedDescription)
        })

        droppingPins = false


    }

    func getStore()
    {
        
        let manager = AFHTTPRequestOperationManager()
        
        let storeEndpointURL = "https://cbi-api-test.herokuapp.com/v2/stores/5110665?apiKey=1&signature=Ydz7LTPUq2gVAE/WobrHnpSLNh1WtyVfcWOHu3exR3w="
        // read store from the heroku endpoint
        manager.GET( storeEndpointURL,
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!,responseObject: AnyObject!) in
                println("JSON: " + String(responseObject.description))
                
                var storeName = ""
                var storeAddress = ""
                var storeState = ""
                var storeZip = ""
                var storePhone = ""
                var storeLat : Double = 0.00
                var storeLng : Double = 0.00
                // Parsing without Swift Library
                if let productLocation = responseObject[0] as? NSDictionary {
                    if let tmpStoreName = productLocation["store_dsc"] as? String {
                        storeName = tmpStoreName
                    }
                    if let tmpStoreAddress = productLocation["address"] as? String {
                        storeAddress = tmpStoreAddress
                    }
                    if let tmpStoreState = productLocation["state"] as? String {
                        storeState = tmpStoreState
                    }
                    if let tmpStoreZip = productLocation["postal_cd"] as? String {
                        storeZip = tmpStoreZip
                    }
                    if let tmpStorePhone = productLocation["phone_no"] as? String {
                        storePhone = tmpStorePhone
                    }
                    if let tmpStoreLat = productLocation["latitude"] as? Double {
                        storeLat = tmpStoreLat
                    }
                    if let tmpStoreLng = productLocation["longitude"] as? Double {
                        storeLng = tmpStoreLng
                    }
                    
                    let annotation = MKPointAnnotation()
                    let coordinate = CLLocationCoordinate2D(latitude: storeLat, longitude: storeLng)
                    annotation.setCoordinate(coordinate)
                    annotation.title = storeName
                    annotation.subtitle = storeAddress
                    //self.annotations.append(annotation)
                    self.mapView.addAnnotation(annotation)
                    
                }

            },
            failure: { (operation: AFHTTPRequestOperation!,error: NSError!) in
                println("Error: " + error.localizedDescription)
        })

    }

    func requestLocation() {
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let location = locations.last as CLLocation
        if location.horizontalAccuracy > 0 {
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
            
            onUserLocationChange()
            
            self.locationManager.stopUpdatingLocation()
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(60.0 * Double(NSEC_PER_SEC)))
            //dispatch_after(time, dispatch_get_main_queue(), {
            //    self.locationManager.startUpdatingLocation()
            //})
        }

    }

    func onUserLocationChange() {
        if !foundUserLocation
        {
            getStores()
            
            let center = self.location.coordinate
            
            let span = MKCoordinateSpanMake(0.5, 0.5)
            self.mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: false)
            
            self.latitude = center.latitude
            
            self.longitude = center.longitude
            
            foundUserLocation = true
            
            // this is crashing
            //centerMapByMiles(15)
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var location: CLLocation {
        get {
            return CLLocation(latitude: self.latitude, longitude: self.longitude)
        }
    }
    
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated userLocation: MKUserLocation!) {
        
        if !foundUserLocation {
            return
        }
        println("New Location: ")
       // println(userLocation)
        
        let newLoc : CLLocationCoordinate2D  = mapView.centerCoordinate
        
        println("new center")
        println(newLoc.latitude)
        println(newLoc.longitude)
        
        self.latitude = newLoc.latitude
        self.longitude = newLoc.longitude
        
        getStores()
        
        /*
        // Not getting called
        if let loc = userLocation {
        getProductLocations(userLocation.coordinate)
        }
        let newLoc : CLLocationCoordinate2D  = mapView.centerCoordinate
        
        var annotation = MKPointAnnotation()
        annotation.setCoordinate(newLoc)
        annotation.title = "Yo"
        annotation.subtitle = "Yo"
        self.mapView.addAnnotation(annotation)
        
        getProductLocations(newLoc)
        */
    }
 
    
    func centerMapByMiles(miles: Double) {
        var location = mapView.centerCoordinate
        var span = MKCoordinateSpanMake(0.1, 0.1)
        var region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
        
        //let miles = 15.0;
        var scalingFactor =  (cos(2 * M_PI * location.latitude / 360.0) );
        if scalingFactor < 0 {
            scalingFactor = scalingFactor * (-1)
        }
        var mySpan = MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0)
        
        mySpan.latitudeDelta = miles/69.0;
        mySpan.longitudeDelta = miles/(scalingFactor * 69.0);
        
        var myRegion = MKCoordinateRegion(center: location, span: mySpan)
        
        mapView.setRegion(myRegion, animated: true)
    }
    
}



