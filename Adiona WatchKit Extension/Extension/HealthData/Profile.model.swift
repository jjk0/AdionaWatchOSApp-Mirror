//
//  Profile.model.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 7/15/22.
//

import Foundation

struct Profile: Codable {
    let caregiver_phone: String
    let living_situation: String
}

struct ProfileData: Codable {
    let profile_info: Profile
}

