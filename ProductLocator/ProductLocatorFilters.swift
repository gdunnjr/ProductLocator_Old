//
//  ProductLocatorFilters.swift
//  ProductLocator
//
//  Created by Gerald Dunn on 3/4/15.
//  Copyright (c) 2015 Gerald Dunn. All rights reserved.
//

class ProductLocatorFilters {
    
    var filters = [
        
        Filter(
            label: "Premise Type",
            name: "premise",
            options: [
                Option(label: "On Premise", value: "0", selected: true),
                Option(label: "Off Premise", value: "1"),
                //Option(label: "Rating", value: "2")
            ],
            type: .Single
        ),
        
        Filter(
            label: "Brand",
            name: "category_filter",
            options: [
                Option(label: "Arbor Mist", value: "arbormist"),
                Option(label: "Blackstone", value: "blackstone"),
                Option(label: "Diseno", value: "diseno"),
                Option(label: "Woodbridge", value: "woodbridge", selected: true)
            ],
            type: .Single,
            numItemsVisible: 3
        )
    ]
    
    init(instance: ProductLocatorFilters? = nil) {
        if instance != nil {
            self.copyStateFrom(instance!)
        }
    }
    
    func copyStateFrom(instance: ProductLocatorFilters) {
        for var f = 0; f < self.filters.count; f++ {
            for var o = 0; o < self.filters[f].options.count; o++ {
                self.filters[f].options[o].selected = instance.filters[f].options[o].selected
            }
        }
    }
    
    var parameters: Dictionary<String, String> {
        get {
            var parameters = Dictionary<String, String>()
            for filter in self.filters {
                switch filter.type {
                case .Single:
                    if filter.name != nil {
                        let selectedOption = filter.options[filter.selectedIndex]
                        if selectedOption.value != "" {
                            parameters[filter.name!] = selectedOption.value
                        }
                    }
                case .Multiple:
                    if filter.name != nil {
                        let selectedOptions = filter.selectedOptions
                        if selectedOptions.count > 0 {
                            parameters[filter.name!] = ",".join(selectedOptions.map({ $0.value }))
                        }
                    }
                default:
                    for option in filter.options {
                        if option.selected && option.name != nil && option.value != "" {
                            parameters[option.name!] = option.value
                        }
                    }
                }
            }
            return parameters
        }
    }
    
    class var instance: ProductLocatorFilters {
        struct Static {
            static let instance: ProductLocatorFilters = ProductLocatorFilters()
        }
        return Static.instance
    }
    
}

class Filter {
    
    var label: String
    var name: String?
    var options: Array<Option>
    var type: FilterType
    var numItemsVisible: Int?
    var opened: Bool = false
    
    init(label: String, name: String? = nil, options: Array<Option>, type: FilterType, numItemsVisible: Int? = 0) {
        self.label = label
        self.name = name
        self.options = options
        self.type = type
        self.numItemsVisible = numItemsVisible
    }
    
    var selectedIndex: Int {
        get {
            for var i = 0; i < self.options.count; i++ {
                if self.options[i].selected {
                    return i
                }
            }
            return -1
        }
        set {
            if self.type == .Single {
                self.options[self.selectedIndex].selected = false
            }
            self.options[newValue].selected = true
        }
    }
    
    var selectedOptions: Array<Option> {
        get {
            var options: Array<Option> = []
            for option in self.options {
                if option.selected {
                    options.append(option)
                }
            }
            return options
        }
    }
    
}

enum FilterType {
    case Default, Single, Multiple
}

class Option {
    
    var label: String
    var name: String?
    var value: String
    var selected: Bool
    
    init(label: String, name: String? = nil, value: String, selected: Bool = false) {
        self.label = label
        self.name = name
        self.value = value
        self.selected = selected
    }
    
}