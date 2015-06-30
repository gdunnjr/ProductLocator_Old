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

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, FiltersViewDelegate, GMSMapViewDelegate {
    
    //@IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var brandLabel: UILabel!
    @IBOutlet weak var varietalLabel: UILabel!
    
    
    @IBOutlet weak var viewMap: GMSMapView!
  
    //var locationManager = CLLocationManager()
    
    var didFindMyLocation = false
    
    var locationMarker: GMSMarker!
    
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
   
        //mapView.delegate = self
        
        // Get the current location
        self.requestLocation()
        
        let camera: GMSCameraPosition = GMSCameraPosition.cameraWithLatitude(48.857165, longitude: 2.354613, zoom: 13.0)
        viewMap.camera = camera
        
        viewMap.delegate = self
        
        locationManager.delegate = self
        // this is not supported in IOS 7, so check that that the selector exists
        if locationManager.respondsToSelector("requestWhenInUseAuthorization") {
            self.locationManager.requestWhenInUseAuthorization()
        }
        //self.locationManager.startUpdatingLocation()

        
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
    
    func mapView(mapView: GMSMapView!, willMove gesture: Bool) {
        println("In Will Move: ")
    }
    
    func mapView(mapView: GMSMapView!, didChangeCameraPosition position: GMSCameraPosition) {
        println("In did change position: ")
    }
    
    func mapView(mapView: GMSMapView!, idleAtCameraPosition position: GMSCameraPosition) {
        println("In camera idle: ")
        
        let center = position.target
        self.latitude = center.latitude
        self.longitude = center.longitude

        getStores()
        
        var visibleRegion : GMSVisibleRegion = mapView.projection.visibleRegion()
        var bounds = GMSCoordinateBounds(coordinate: visibleRegion.nearLeft, coordinate: visibleRegion.farRight)
        
        let northEast = bounds.northEast
        let southWest = bounds.southWest
        
        println(northEast.latitude)  // maxLat
        println(southWest.latitude)  // minLat
        
        println(northEast.longitude)  // maxLng
        println(southWest.longitude)  // minLng
        
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if !didFindMyLocation {
            let myLocation: CLLocation = change[NSKeyValueChangeNewKey] as CLLocation
            viewMap.camera = GMSCameraPosition.cameraWithTarget(myLocation.coordinate, zoom: 13.0)
            viewMap.settings.myLocationButton = true
            
            didFindMyLocation = true
        }
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.AuthorizedWhenInUse {
            viewMap.myLocationEnabled = true
        }
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
        
        
        var visibleRegion : GMSVisibleRegion = viewMap.projection.visibleRegion()
        var bounds = GMSCoordinateBounds(coordinate: visibleRegion.nearLeft, coordinate: visibleRegion.farRight)
        
        let northEast = bounds.northEast
        let southWest = bounds.southWest
        
        let maxLat = northEast.latitude  // maxLat
        let minLat = southWest.latitude  // minLat
        
        let maxLng = northEast.longitude  // maxLng
        let minLng = southWest.longitude  // minLng
        
        activityIndicator.frame = CGRectMake(100, 100, 100, 100);
        activityIndicator.startAnimating()
        activityIndicator.center = self.view.center
        self.view.addSubview( activityIndicator )
       
        //TODO replace with google map call
        //let loc : CLLocationCoordinate2D  = mapView.centerCoordinate
      
        let prodDomain = "https://api.cbrands.com/"
        let testDomain = "http://cbi-api-pl-prototype.herokuapp.com/"
        var baseURL = testDomain + "pl/productlocations.json?apiKey=\(Constants.APIConstants.APIKey)&stateRestriction=Y&latitude=\(self.latitude)&longitude=\(self.longitude)&radiusInMiles=15&from=0&to=200"
        baseURL = baseURL + "&minLatitude=\(minLat)&maxLatitude=\(maxLat)&minLongitude=\(minLng)&maxLongitude=\(maxLng)&storeInfoOnly=Y"
       // baseURL = baseURL + "&premiseTypeDesc=\(premiseType.filterDescription())"
       // baseURL = baseURL + "&brandCode=\(brandCdFilter)&varietalCode=\(varietalCdFilter)"

        println(baseURL)
        
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
                            self.viewMap.clear()
                            
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
                                    
                                    
                                    self.locationMarker = GMSMarker(position: coordinate)
                                    self.locationMarker.map = self.viewMap
                                    
                                    self.locationMarker.title = storeName
                                    self.locationMarker.appearAnimation = kGMSMarkerAnimationPop
                                    self.locationMarker.icon = GMSMarker.markerImageWithColor(UIColor.blueColor())
                                    self.locationMarker.opacity = 0.75
                                    
                                    //self.locationMarker.flat = true
                                    self.locationMarker.snippet = storeAddress + " " + storeCity
                                    
                                    
                                    //TODO replace with google map call
                                    //self.mapView.addAnnotation(annotation)
                                    
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
                self.activityIndicator.stopAnimating()
                
        })

        droppingPins = false
    }

//    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
//        if annotation is MKUserLocation {
//            //return nil so map view draws "blue dot" for standard user location
//            return nil
//        }
//        
//        let identifier = "pin"
//        var view: MKPinAnnotationView
//        if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
//            as? MKPinAnnotationView {
//                dequeuedView.annotation = annotation
//                view = dequeuedView
//        } else {
//            
//            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
//            view.canShowCallout = true
//            view.calloutOffset = CGPoint(x: -5, y: 5)
//            
//            let directionButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
//            let directionIcon = UIImage(named: "113-navigation") as UIImage?
//            directionButton.frame = CGRectMake(0, 0, 32, 32)
//            directionButton.setImage(directionIcon, forState: UIControlState.Normal)
//            
//            view.rightCalloutAccessoryView = directionButton as UIView
//        }
//        return view
//    }
    
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
            
            //TODO replace with google map call
            //self.mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: false)
            
            viewMap.camera = GMSCameraPosition(target: location.coordinate, zoom: 13, bearing: 0, viewingAngle: 0)
            
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
    
//TODO replace with google map call
//    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool)
//    {
//        if !foundUserLocation {
//            return
//        }
//        
//        let newLoc : CLLocationCoordinate2D  = mapView.centerCoordinate
//        
//        //println("new center")
//        //println(newLoc.latitude)
//        //println(newLoc.longitude)
//        
//        self.latitude = newLoc.latitude
//        self.longitude = newLoc.longitude
//        
//        getStores()
//        
//    }
 
    
// TODO - rewrite for google maps
//    func centerMapByMiles(miles: Double) {
//        //TODO replace with google map call
//        //var location = mapView.centerCoordinate
//        
//        
//        var span = MKCoordinateSpanMake(0.1, 0.1)
//        var region = MKCoordinateRegion(center: location, span: span)
//        
//        //TODO replace with google map call
//        //mapView.setRegion(region, animated: true)
//        
//        //let miles = 15.0;
//        var scalingFactor =  (cos(2 * M_PI * location.latitude / 360.0) );
//        if scalingFactor < 0 {
//            scalingFactor = scalingFactor * (-1)
//        }
//        var mySpan = MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0)
//        
//        mySpan.latitudeDelta = miles/69.0;
//        mySpan.longitudeDelta = miles/(scalingFactor * 69.0);
//        
//        var myRegion = MKCoordinateRegion(center: location, span: mySpan)
//        
//        //TODO replace with google map call
//        //mapView.setRegion(myRegion, animated: true)
//        
//    }
    
    final func onFiltersDone(controller: FiltersTableViewController) {
        brandCdFilter=ProductLocatorFilters.instance.filters[0].selectedOptions[0].value
        varietalCdFilter=ProductLocatorFilters.instance.filters[1].selectedOptions[0].value

        brandLabel.text = ProductLocatorFilters.instance.filters[0].selectedOptions[0].label.lowercaseString.capitalizedString
        varietalLabel.text = ProductLocatorFilters.instance.filters[1].selectedOptions[0].label.lowercaseString.capitalizedString
        
        //TODO replace with google map call
        //mapView.removeAnnotations(mapView.annotations)
        
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
        
        //TODO replace with google map call
        //mapView.removeAnnotations(mapView.annotations)
        
        getStores()
    }
    
    @IBAction func mapCurrentLocationPinTapped(sender: AnyObject) {
        
        //TODO replace with google map call
        //mapView.removeAnnotations(mapView.annotations)
        
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

// TODO - rewrite for google maps
//    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!,
//        calloutAccessoryControlTapped control: UIControl!) {
//        let location = view.annotation
//        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
//        let lat: Double = location.coordinate.latitude
//        let lng: Double = location.coordinate.longitude
//        let locationTargetDesc:String = location.title! + " " + location.subtitle!
//        
//        openAMapWithCoordinates(location.coordinate.latitude, theLon:location.coordinate.longitude, targetDesc:locationTargetDesc)
//
//    }
    
}



