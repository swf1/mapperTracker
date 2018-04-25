//
//  Activity.swift
//  mapperTracker
//
//  Created by Jason Hoffman on 4/22/18.
//  Copyright © 2018 Jason Hoffman. All rights reserved.
//

import Foundation


class Activity: NSObject {
    var uid: String
    var name: String
    var type: String
    var startDateLocal: String
    var activityDescription: String
    var elapsedTime: Int?
    var distance: String?
    var visible: Bool?
    var trainer: Bool?
    var commute: Bool?
    
    init(uid: String, name: String, type: String, startDateLocal: String, description: String) {
        self.uid = uid
        self.name = name
        self.type = type
        self.startDateLocal = startDateLocal
        self.activityDescription = description
    }

}
