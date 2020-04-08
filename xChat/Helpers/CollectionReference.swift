//
//  CollectionReference.swift
//  iChat
//
//  Created by David Kababyan on 08/06/2018.
//  Copyright © 2018 David Kababyan. All rights reserved.
//

import Foundation
import FirebaseFirestore


public enum FCollectionReference: String {
    case User
    case Typing
    case Recent
    case Message
    case Group
    case Call
    case Contact
    case UserKeywords
} 


public func reference(_ collectionReference: FCollectionReference) -> CollectionReference{
    return Firestore.firestore().collection(collectionReference.rawValue)
}
