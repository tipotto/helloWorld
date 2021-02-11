//
//  Status.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/13.
//

import Foundation

enum Status: String, CaseIterable {
    
    case Available = "Available"
    case Busy = "Busy"
    case AtSchool = "At School"
    case AtTheMovies = "At the Movies"
    case AtWork = "At Work"
    case BatteryAboutToDie = "Battery About to Die"
    case CantTalk = "Can't Talk"
    case InAMeeting = "In a Meeting"
    case AtTheGym = "At the Gym"
    case Sleeping = "Sleeping"
    case UrgentCallsOnly = "Urgent Calls Only"
}
