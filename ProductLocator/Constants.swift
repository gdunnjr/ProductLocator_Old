//
//  Constants.swift
//  ProductLocator
//
//  Created by Gerald Dunn on 4/2/15.
//  Copyright (c) 2015 Gerald Dunn. All rights reserved.
//

import Foundation

class Constants {
    struct DeviceConstants {
        static let iPad = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? true : false
    }

    struct IOSVersionConstants {
        static let less_than_iOS_8 = (UIDevice.currentDevice().systemVersion as NSString).floatValue < 8.0 ? true : false
    }
    
    struct APIConstants {
        static let APIKey = "productlocatorios"
    }
    
    struct ImageConstants {
        static let brandImages = [
            "859": "anderra",
            "120": "arborMist",
            "152": "blackBox",
            "155": "blackVelvet",
            "157": "blackstone",
            "223": "ciosDuBois",
            "226": "cooks",
            "250": "diseno",
            "270": "estancia",
            "287": "franciscan",
            "848": "hiddenCrush",
            "341": "inniskillin",
            "359": "kimCrawford",
            "816": "markWest",
            "885": "milestone",
            "426": "mountVeederWinery",
            "446": "nobilo",
            "478": "paulMasson",
            "686": "primalRoots",
            "497": "ravensWood",
            "504": "rexGoliath",
            "512": "rmv",
            "511": "rmvps",
            "884": "rosatello",
            "517": "ruffino",
            "862": "saved",
            "536": "simi",
            "557": "svedka",
            "689": "theDreamingTree",
            "768": "thornyRose",
            "568": "toastedHead",
            "589": "vendange",
            "628": "wildHorse",
            "631": "woodbridge"
    ]
    }
}