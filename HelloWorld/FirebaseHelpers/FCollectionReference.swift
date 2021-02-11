//
//  FCollectionReference.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/10.
//

import Foundation
import FirebaseFirestore

enum FCollectionReference: String {
    case User
    case Recent
    case Messages
    case Typing
    case Channel
}

func FirebaseReference(_ collectionReference: FCollectionReference) -> CollectionReference {
    return Firestore.firestore().collection(collectionReference.rawValue)
}
