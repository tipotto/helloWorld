//
//  Constants.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/10.
//

import Foundation
import FirebaseAuth

let userDefaults = UserDefaults.standard
let auth = Auth.auth()
public let kFILEREFERENCE = "gs://helloworld-2ff85.appspot.com"

public let kDISPLAYMESSAGESNUMBER = 8
public let kLOADMESSAGESNUMBER = 8
public let kNUMBEROFCHANNELS = 10

public let kCURRENTUSER = "currentUser"
public let kSTATUS = "status"
public let kCHANNELTYPE = "channelType"
public let kCHANNELTHEME = "channelTheme"
public let kFIRSTRUN = "firstRun"
public let kCHATROOMID = "chatRoomId"
public let kSENDERID = "senderId"


public let kTEXT = "text"
public let kPHOTO = "photo"
public let kVIDEO = "video"
public let kAUDIO = "audio"
public let kLOCATION = "location"

public let kDATE = "date"
public let kREADDATE = "readDate"




public let kNOTDETERMINED = "notDetermined"
public let kAUTHORIZEDWHENINUSE = "authorizedWhenInUse"
public let kAUTHORIZEDALWAYS = "authorizedAlways"
public let kRESTRICTED = "restricted"
public let kDENIED = "denied"
public let kID = "id"
public let kNAME = "name"
public let kLANG = "lang"
public let kISREAD = "isRead"

public let kAVATARLINK = "avatarLink"
public let kADMINID = "adminId"
public let kPARTNERID = "partnerId"
public let kREADCOUNTER = "readCounter"
public let kISADMIN = "isAdmin"
public let kLANGLIST = "langList"


public let kUSER = "users"
public let kCHAT = "chats"
public let kCHANNEL = "channels"
public let kCHANNELRES = "channelRes"
public let kMESSAGE = "messages"
public let kREADSTATUS = "readStatus"
//public let kCHANNELRES = "resources"

// 今後削除予定
public let kSENT = "Sent"
public let kREAD = "Read"
public let kMEMBERIDS = "memberIds"
