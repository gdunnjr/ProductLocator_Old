//
//  ViewController.swift
//  ProductLocator
//
//  Created by Gerald Dunn on 2/27/15.
//  Copyright (c) 2015 Gerald Dunn. All rights reserved.
//

import UIKit
import MapKit
import AddressBook

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, FiltersViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var brandLabel: UILabel!
    @IBOutlet weak var varietalLabel: UILabel!
    
    var locationManager: CLLocationManager = CLLocationManager()
    var annotations: Array<MKPointAnnotation>!
    var foundUserLocation = false
    var droppingPins = false

    // these will hold current location - set a default
    var latitude: Double = 37.7710347
    var longitude: Double = -122.4040795
    
    let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    
    enum premise: Int {
        case OnPremise = 0
        case OffPremise = 1
        case Jack, Queen, King
        func filterDescription() -> String {
            switch self {
            case .OnPremise:
                return "ON%20PREMISE"
            case .OffPremise:
                return "OFF%20PREMISE"
            default:
                return String(self.rawValue)
            }
        }
    }
    
    var premiseType = premise.OnPremise
    var brandCdFilter = "631"
    var varietalCdFilter = "225"
    
    override func viewDidLoad() {
        super.viewDidLoad()
   
        mapView.delegate = self
        
        // Get the current location
        self.requestLocation()
        
        // Code to get the bounding box of the visible map area - Future
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
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "modalFilterSegue"
        {
            let navController = segue.destinationViewController as UINavigationController
            //let destVC = navController.viewControllers[0]  as FiltersTableViewController
            let destVC = navController.topViewController as FiltersTableViewController
            
            destVC.delegate = self
        }
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
        let baseURL = "https://api.cbrands.com/pl/productlocations.json?apiKey=ldtst&stateRestriction=Y&latitude=\(self.latitude)&longitude=\(self.longitude)&brandCode=\(brandCdFilter)&varietalCode=\(varietalCdFilter)&radiusInMiles=15&premiseTypeDesc=\(premiseType.filterDescription())&from=0&to=50"
        
        //println(self.latitude)
        //println(self.longitude)
        
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

    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        
        let identifier = "pin"
        var view: MKPinAnnotationView
        if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
            as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
        } else {
            
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            
            let directionButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
            let directionIcon = UIImage(named: "113-navigation") as UIImage?
            directionButton.frame = CGRectMake(0, 0, 32, 32)
            directionButton.setImage(directionIcon, forState: UIControlState.Normal)
            
            view.rightCalloutAccessoryView = directionButton as UIView
        }
        return view
    }
    
    func requestLocation() {
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
    
        // this is not supported in IOS 7, so check that that the selector exists
        if locationManager.respondsToSelector("requestWhenInUseAuthorization") {
            self.locationManager.requestWhenInUseAuthorization()
        }

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
        
        let newLoc : CLLocationCoordinate2D  = mapView.centerCoordinate
        
        //println("new center")
        //println(newLoc.latitude)
        //println(newLoc.longitude)
        
        self.latitude = newLoc.latitude
        self.longitude = newLoc.longitude
        
        getStores()
        
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
    
    final func onFiltersDone(controller: FiltersTableViewController) {
        brandCdFilter=ProductLocatorFilters.instance.filters[0].selectedOptions[0].value
        varietalCdFilter=ProductLocatorFilters.instance.filters[1].selectedOptions[0].value

        brandLabel.text = ProductLocatorFilters.instance.filters[0].selectedOptions[0].label.lowercaseString.capitalizedString
        varietalLabel.text = ProductLocatorFilters.instance.filters[1].selectedOptions[0].label.lowercaseString.capitalizedString
        
        mapView.removeAnnotations(mapView.annotations)
        getStores()
        
    }

    @IBAction func premiseBarAction(sender: AnyObject) {
        
        let barButton = sender as UISegmentedControl
        if barButton.selectedSegmentIndex == 1
        {
            premiseType = premise.OffPremise
        }
        else
        {
            premiseType = premise.OnPremise
        }
        mapView.removeAnnotations(mapView.annotations)
        getStores()
    }
    
    @IBAction func mapCurrentLocationPinTapped(sender: AnyObject) {
        mapView.removeAnnotations(mapView.annotations)
        foundUserLocation = false
        requestLocation()
    }

    func openAMapWithCoordinates(theLat:Double, theLon:Double, targetDesc:String){
        
        var coordinate = CLLocationCoordinate2DMake(CLLocationDegrees(theLat), CLLocationDegrees(theLon))
        let addressDictionary = [String(kABPersonAddressStreetKey): targetDesc]
        var placemark:MKPlacemark = MKPlacemark(coordinate: coordinate, addressDictionary:addressDictionary)
        var mapItem:MKMapItem = MKMapItem(placemark: placemark)
        mapItem.name = targetDesc
        let launchOptions:NSDictionary = NSDictionary(object: MKLaunchOptionsDirectionsModeDriving, forKey: MKLaunchOptionsDirectionsModeKey)
        var currentLocationMapItem:MKMapItem = MKMapItem.mapItemForCurrentLocation()
        MKMapItem.openMapsWithItems([currentLocationMapItem, mapItem], launchOptions: launchOptions)
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!,
        calloutAccessoryControlTapped control: UIControl!) {
        let location = view.annotation
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        let lat: Double = location.coordinate.latitude
        let lng: Double = location.coordinate.longitude
        let locationTargetDesc:String = location.title! + " " + location.subtitle!
        
        openAMapWithCoordinates(location.coordinate.latitude, theLon:location.coordinate.longitude, targetDesc:locationTargetDesc)

    }
    
}



