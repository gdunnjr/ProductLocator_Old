//
//  FiltersTableViewController.swift
//  ProductLocator
//
//  Created by Gerald Dunn on 3/3/15.
//  Copyright (c) 2015 Gerald Dunn. All rights reserved.
//

import UIKit

class FiltersTableViewController: UITableViewController,UINavigationBarDelegate, NSXMLParserDelegate {
    
    var delegate: FiltersViewDelegate?
    var model: ProductLocatorFilters?
    
    // variables for parsing the varietals xml
    var elements = NSMutableDictionary()
    var element = NSString()
    var varietalBlendCd = NSMutableString()
    var varietalBlendDsc = NSMutableString()
    
    @IBOutlet var customImageView: UIImageView!
    @IBOutlet var customImageViewBrand: UIImageView!
    let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rowHeight = 90.0
        
        // Create a new instance of the model for this "session"
        self.model = ProductLocatorFilters(instance: ProductLocatorFilters.instance)
        
        // load up the brands
        if self.model!.filters[0].options.count<=2 {
            getBrands()
        }

        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: "cancelButtonTapped")
        let searchButton = UIBarButtonItem(title: "Find", style: UIBarButtonItemStyle.Plain, target: self, action: "searchButtonTapped")
        self.navigationItem.leftBarButtonItem = cancelButton
        self.navigationItem.rightBarButtonItem = searchButton
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.model!.filters.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let filter = self.model!.filters[section] as Filter
        if !filter.opened {
            if filter.type == FilterType.Single {
                return 1
            } else if filter.numItemsVisible > 0 && filter.numItemsVisible < filter.options.count {
                return filter.numItemsVisible! + 1
            }
        }
        return filter.options.count
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let filter = self.model!.filters[section]
        let label = filter.label.lowercaseString.capitalizedString
        
        // Add the number of selected options for multiple-select filters with hidden options
        if filter.type == .Multiple && filter.numItemsVisible > 0 && filter.numItemsVisible < filter.options.count && !filter.opened {
            let selectedOptions = filter.selectedOptions
            return "\(label) (\(selectedOptions.count) selected)"
        }
        
        return label
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("filterTableViewCellIdentifier") as! FilterTableViewCell
        
        let filter = self.model!.filters[indexPath.section] as Filter
        switch filter.type {
        case .Single:
            if filter.opened {
                let option = filter.options[indexPath.row]
                //cell.textLabel!.text = option.label
                cell.brandLabel.text = option.label.lowercaseString.capitalizedString
              
                var imageName = ""
                if indexPath.section == 0 {
                    if let imageName = Constants.ImageConstants.brandImages[option.value] {
                        cell.brandImageView.image = UIImage(named: imageName)
                        cell.brandLabel.hidden = true
                        cell.brandImageView.hidden = false
                    } else {
                        //cell.brandImageView.image = UIImage(named: "cbrandsWhite")
                        cell.brandLabel.hidden = false
                        cell.brandImageView.hidden = true
                    }
                } else {
                    cell.brandLabel.hidden = false
                    cell.brandImageView.hidden = true
                }
                
                
                if option.selected {
                    cell.accessoryView = UIImageView(image: UIImage(named: "Check"))
                } else {
                    cell.accessoryView = UIImageView(image: UIImage(named: "Uncheck"))
                }
            } else {
                cell.brandLabel.text = filter.options[filter.selectedIndex].label.lowercaseString.capitalizedString
                cell.accessoryView = UIImageView(image: UIImage(named: "Dropdown"))
                //cell.textLabel!.text = filter.options[filter.selectedIndex].label
                
                var imageName = ""
                if indexPath.section == 0 {
                    if let imageName = Constants.ImageConstants.brandImages[filter.options[filter.selectedIndex].value] {
                        cell.brandImageView.image = UIImage(named: imageName)
                        cell.brandLabel.hidden = true
                        cell.brandImageView.hidden = false
                    } else {
                        //cell.brandImageView.image = UIImage(named: "cbrandsWhite")
                        cell.brandLabel.hidden = false
                        cell.brandImageView.hidden = true
                    }
                } else {
                    cell.brandLabel.hidden = false
                    cell.brandImageView.hidden = true
                }
                
            }
        
        case .Multiple:
            if filter.opened || indexPath.row < filter.numItemsVisible {
                let option = filter.options[indexPath.row]
                cell.textLabel!.text = option.label
                if option.selected {
                    cell.accessoryView = UIImageView(image: UIImage(named: "Check"))
                } else {
                    cell.accessoryView = UIImageView(image: UIImage(named: "Uncheck"))
                }
            } else {
                cell.textLabel!.text = "See All"
                cell.textLabel!.textAlignment = NSTextAlignment.Center
                cell.textLabel!.textColor = .darkGrayColor()
            }

        default:
            let option = filter.options[indexPath.row]
            cell.brandLabel.text = option.label.lowercaseString.capitalizedString
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            let switchView = UISwitch(frame: CGRectZero)
            switchView.on = option.selected
            switchView.onTintColor = UIColor(red: 73.0/255.0, green: 134.0/255.0, blue: 231.0/255.0, alpha: 1.0)
            switchView.addTarget(self, action: "handleSwitchValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.accessoryView = switchView
        }
        
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var reloadVarietals = false
        
        let filter = self.model!.filters[indexPath.section]
        switch filter.type {
        case .Single:
            if filter.opened {
                let previousIndex = filter.selectedIndex
                if previousIndex != indexPath.row {
                    filter.selectedIndex = indexPath.row
                    let previousIndexPath = NSIndexPath(forRow: previousIndex, inSection: indexPath.section)
                    self.tableView.reloadRowsAtIndexPaths([indexPath, previousIndexPath], withRowAnimation: .Automatic)
                
                    //println(indexPath.section)
                    if indexPath.section == 0 {
                        reloadVarietals = true
                    }
                
                }
            }
            
            let opened = filter.opened;
            filter.opened = !opened;
            
            if opened {
                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(0.25 * Double(NSEC_PER_SEC)))
                dispatch_after(time, dispatch_get_main_queue(), {
                    self.tableView.reloadSections(NSMutableIndexSet(index: indexPath.section), withRowAnimation: .Automatic)
                })
            } else {
                self.tableView.reloadSections(NSMutableIndexSet(index: indexPath.section), withRowAnimation: .Automatic)
            }
 
        case .Multiple:
            if !filter.opened && indexPath.row == filter.numItemsVisible {
                filter.opened = true
                self.tableView.reloadSections(NSMutableIndexSet(index: indexPath.section), withRowAnimation: .Automatic)
            } else {
                let option = filter.options[indexPath.row]
                option.selected = !option.selected
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        default:
            break
        }
        
        if reloadVarietals == true {
            getVarietals(filter.options[indexPath.row].value)
        }
 
    }
    
    func searchButtonTapped() {
        
        // Commit the changes to the global instance of the filters
        ProductLocatorFilters.instance.copyStateFrom(self.model!)
        self.dismissViewControllerAnimated(true, completion: nil)
        self.delegate?.onFiltersDone(self)

    }
    
    func cancelButtonTapped() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func parser(parser: NSXMLParser!, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!)
    {
        var varCd = ""
        var varDsc = ""
        
        if (elementName as NSString).isEqualToString("plBrandDetails") {
            if !varietalBlendCd.isEqual(nil) {
                //elements.setObject(title1, forKey: "varietalBlendCd")
                varCd = varietalBlendCd as String
                //println(varCd)
            }
            if !varietalBlendDsc.isEqual(nil) {
                //elements.setObject(title1, forKey: "varietalBlendCd")
                varDsc = varietalBlendDsc as String
                //println(varDsc)
            }
            
            // add it
            let option = Option(label: varietalBlendDsc as String, name: varietalBlendDsc as String, value: varietalBlendCd as String, selected: false)
            
            
            // see if it already exists
            var alreadyAdded = false
            if self.model!.filters[1].options.count > 0 {
                for index in 0...self.model!.filters[1].options.count-1 {
                    if self.model!.filters[1].options[index].value == varCd {
                        alreadyAdded = true
                        break
                    }
                }
            }
            if !alreadyAdded {
                self.model!.filters[1].options.append(option)
            }

        }
    }
  
    //func parser(parser: NSXMLParser!, didStartElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!, attributes attributeDict: NSDictionary!) {
    func parser(parser: NSXMLParser,
        didStartElement elementName: String,
        #namespaceURI: String?,
        #qualifiedName: String?,
        attributes attributeDict: [NSObject : AnyObject]) {
        element = elementName
        
        if (elementName as NSString).isEqualToString("plBrandDetails")
        {
            elements = NSMutableDictionary.alloc()
            elements = [:]
            varietalBlendCd = NSMutableString.alloc()
            varietalBlendCd = ""
            varietalBlendDsc = NSMutableString.alloc()
            varietalBlendDsc = ""
        }
     }
  
    func parser(parser: NSXMLParser!, foundCharacters string: String!)
    {
        if element.isEqualToString("varietalBlendCd") {
            varietalBlendCd.appendString(string)
        } else if element.isEqualToString("varietalBlendDsc") {
            varietalBlendDsc.appendString(string)
        }
    }
 
    func getVarietals(brandCode: String)
    {

        let baseURL = "https://api.cbrands.com/pl/brand/\(brandCode)?apiKey=\(Constants.APIConstants.APIKey)"
        
        let manager = AFHTTPRequestOperationManager()
        let xmlSerializer = AFXMLParserResponseSerializer()
        manager.responseSerializer = xmlSerializer
        manager.GET( baseURL,
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!,responseObject: AnyObject!) in
                //println("JSON: " + String(responseObject.description))
                
                self.model!.filters[1].options.removeAll(keepCapacity: false)
                
                let xmlParser = responseObject as! NSXMLParser
                xmlParser.delegate = self
                xmlParser.parse()
                self.model!.filters[1].options[0].selected = true
                self.model!.filters[1].options.sort { $0.label < $1.label }
                self.tableView.reloadData()
                
            },
            failure: { (operation: AFHTTPRequestOperation!,error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
        //println("in varietal sort...")
    }

    func getBrands()
    {
        activityIndicator.frame = CGRectMake(100, 100, 100, 100);
        activityIndicator.startAnimating()
        activityIndicator.center = self.view.center
        self.view.addSubview( activityIndicator )
        
        let baseURL = "https://api.cbrands.com/pl/brands.json?apiKey=\(Constants.APIConstants.APIKey)"
       
        let manager = AFHTTPRequestOperationManager()
        manager.GET( baseURL,
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!,responseObject: AnyObject!) in
                //println("JSON: " + String(responseObject.description))
                
                var brandCd = ""
                var brandDsc = ""
                var firstLoad = false
                if self.model!.filters[0].options.count == 1 {
                    firstLoad = true
                }
                
                if let brandsJsonDict = responseObject as? NSDictionary {
                    
                    if let brands = brandsJsonDict["brand"] as? NSArray {
                        
                        if brands.count == 0
                        {
                            println("no brands")
                        }
                        else
                        {
                            
                            self.model!.filters[0].options.removeAll(keepCapacity: false)
                
                            for index in 0...brands.count-1 {
                                if let tmpBrandCd = brands[index]["brandCd"] as? String {
                                    brandCd = tmpBrandCd
                                    //println(brandCd)
                                }
                                
                                if let tmpBrandDsc = brands[index]["brandDsc"] as? String {
                                    brandDsc = tmpBrandDsc
                                    //println(brandDsc)
                                }
                                
                                // add it
                                let option = Option(label: brandDsc as String, name: brandDsc as String, value: brandCd as String, selected: false)
                                
                                // see if it already exists
                                var alreadyAdded = false
                                if self.model!.filters[0].options.count > 0 {
                                    for index in 0...self.model!.filters[0].options.count-1 {
                                        if self.model!.filters[0].options[index].value == brandCd {
                                            alreadyAdded = true
                                            break
                                        }
                                    }
                                }
                                if !alreadyAdded {
                                    self.model!.filters[0].options.append(option)
                                }
                                
                            }
                            self.model!.filters[0].options[0].selected = true
                            // if first load, select woodbridge
                            for index in 0...self.model!.filters[0].options.count-1 {
                                if self.model!.filters[0].options[index].value == "631" {
                                    self.model!.filters[0].options[0].selected = false
                                    self.model!.filters[0].options[index].selected = true
                                    break
                                }
                            }
                            
                        }
                    }
                }
                self.model!.filters[0].options.sort({$0.label < $1.label })
                self.activityIndicator.stopAnimating()
                
            },
            failure: { (operation: AFHTTPRequestOperation!,error: NSError!) in
                println("Error: " + error.localizedDescription)
                self.activityIndicator.stopAnimating()
        })

        
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}

protocol FiltersViewDelegate {
    func onFiltersDone(controller: FiltersTableViewController)
}

