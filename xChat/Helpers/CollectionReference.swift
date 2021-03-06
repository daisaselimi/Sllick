//
//  CollectionReference.swift
//  Sllick
//
//  Created by Isa  Selimi on 15.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import FirebaseFirestore
import Foundation

public enum FCollectionReference: String {
    case User
    case Typing
    case Recent
    case Message
    case Group
    case Call
    case Contact
    case UserKeywords
    case status
}

public func reference(_ collectionReference: FCollectionReference) -> CollectionReference {
    return Firestore.firestore().collection(collectionReference.rawValue)
}
