//
//  FCollectionReference.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/10.
//

import Foundation
import FirebaseFirestore

enum FCollectionReference: String {
    case User = "users"
    case Chat = "chats"
    case Channel = "channels"
    case ChannelRes = "channelRes"
//    case ChannelRes = "resources"
    case Messages = "messages"
    
    case Typing
    case Recent
    case Room
    
}

func FirebaseReference(_ collectionReference: FCollectionReference) -> CollectionReference {
    return Firestore.firestore().collection(collectionReference.rawValue)
}

func FirebaseGroupQuery(_ collectionReference: FCollectionReference) -> Query {
    return Firestore.firestore().collectionGroup(collectionReference.rawValue)
}
