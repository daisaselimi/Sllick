//
//  FUser.swift
//  Sllick
//
//  Created by Isa  Selimi on 15.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import Firebase
import FirebaseAuth
import FirebaseFirestore
import Foundation
import OneSignal

class FUser: Equatable {
    
    let objectId: String
    var pushId: String?
    
    let createdAt: Date
    var updatedAt: Date
    
    var email: String
    var firstname: String
    var lastname: String
    var fullname: String
    var avatar: String
    var isOnline: Bool
    var phoneNumber: String
    var countryCode: String
    var country: String
    var city: String
    
    var contacts: [String]
    var blockedUsers: [String]
    let loginMethod: String
    
    // MARK: Initializers
    
    init(_objectId: String, _pushId: String?, _createdAt: Date, _updatedAt: Date, _email: String, _firstname: String, _lastname: String, _avatar: String = "", _loginMethod: String, _phoneNumber: String, _city: String, _country: String, _countryCode: String) {
        objectId = _objectId
        pushId = _pushId
        
        createdAt = _createdAt
        updatedAt = _updatedAt
        
        email = _email
        firstname = _firstname
        lastname = _lastname
        fullname = _firstname + " " + _lastname
        avatar = _avatar
        isOnline = true
        
        city = _city
        country = _country
        
        loginMethod = _loginMethod
        phoneNumber = _phoneNumber
        countryCode = _countryCode
        blockedUsers = []
        contacts = []
    }
    
    init(_dictionary: NSDictionary) {
        objectId = _dictionary[kOBJECTID] as! String
        pushId = _dictionary[kPUSHID] as? String
        
        if let created = _dictionary[kCREATEDAT] {
            if (created as! String).count != 14 {
                createdAt = Date()
            } else {
                createdAt = dateFormatter().date(from: created as! String)!
            }
        } else {
            createdAt = Date()
        }
        if let updateded = _dictionary[kUPDATEDAT] {
            if (updateded as! String).count != 14 {
                updatedAt = Date()
            } else {
                updatedAt = dateFormatter().date(from: updateded as! String)!
            }
        } else {
            updatedAt = Date()
        }
        
        if let mail = _dictionary[kEMAIL] {
            email = mail as! String
        } else {
            email = ""
        }
        if let fname = _dictionary[kFIRSTNAME] {
            firstname = fname as! String
        } else {
            firstname = ""
        }
        if let lname = _dictionary[kLASTNAME] {
            lastname = lname as! String
        } else {
            lastname = ""
        }
        fullname = firstname + " " + lastname
        if let avat = _dictionary[kAVATAR] {
            avatar = avat as! String
        } else {
            avatar = ""
        }
        if let onl = _dictionary[kISONLINE] {
            isOnline = onl as! Bool
        } else {
            isOnline = false
        }
        if let phone = _dictionary[kPHONE] {
            phoneNumber = phone as! String
        } else {
            phoneNumber = ""
        }
        if let countryC = _dictionary[kCOUNTRYCODE] {
            countryCode = countryC as! String
        } else {
            countryCode = ""
        }
        if let cont = _dictionary[kCONTACT] {
            contacts = cont as! [String]
        } else {
            contacts = []
        }
        if let block = _dictionary[kBLOCKEDUSERID] {
            blockedUsers = block as! [String]
        } else {
            blockedUsers = []
        }
        
        if let lgm = _dictionary[kLOGINMETHOD] {
            loginMethod = lgm as! String
        } else {
            loginMethod = ""
        }
        if let cit = _dictionary[kCITY] {
            city = cit as! String
        } else {
            city = ""
        }
        if let count = _dictionary[kCOUNTRY] {
            country = count as! String
        } else {
            country = ""
        }
    }
    
    // MARK: Returning current user funcs
    
    class func currentId() -> String {

        return Auth.auth().currentUser!.uid
    }
    
    class func currentUser() -> FUser? {
        if Auth.auth().currentUser != nil {
            if let dictionary = UserDefaults.standard.object(forKey: kCURRENTUSER) {
                return FUser(_dictionary: dictionary as! NSDictionary)
            }
        }
        
        return nil
    }
    
    static func == (lhs: FUser, rhs: FUser) -> Bool {
        return lhs.objectId == rhs.objectId
    }
    
    // MARK: Login function
    
    class func loginUserWith(email: String, password: String, completion: @escaping (_ error: Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password, completion: { firUser, error in
            
            if error != nil {
                completion(error)
                return
                    
            } else {
                // get user from firebase and save locally
                fetchCurrentUserFromFirestore(userId: firUser!.user.uid)
                completion(error)
            }
            
        })
    }
    
    // MARK: Register functions
    
    class func registerUserWith(email: String, password: String, firstName: String, lastName: String, avatar: String = "", completion: @escaping (_ error: Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password, completion: { firuser, error in
            
            if error != nil {
                completion(error)
                return
            }
            
            let fUser = FUser(_objectId: firuser!.user.uid, _pushId: "", _createdAt: Date(), _updatedAt: Date(), _email: firuser!.user.email!, _firstname: firstName, _lastname: lastName, _avatar: avatar, _loginMethod: kEMAIL, _phoneNumber: "", _city: "", _country: "", _countryCode: "")
            
            saveUserLocally(fUser: fUser)
            saveUserToFirestore(fUser: fUser)
            completion(error)
            
        })
    }
    
    // phoneNumberRegistration
    
    class func registerUserWith(phoneNumber: String, verificationCode: String, verificationId: String!, completion: @escaping (_ error: Error?, _ shouldLogin: Bool) -> Void) {
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationId, verificationCode: verificationCode)
        
        Auth.auth().signInAndRetrieveData(with: credential) { firuser, error in
            
            if error != nil {
                completion(error!, false)
                return
            }
            
            // check if user exist - login else register
            fetchCurrentUserFromFirestore(userId: firuser!.user.uid, completion: { user in
                
                if user != nil, user!.firstname != "" {
                    // we have user, login
                    
                    saveUserLocally(fUser: user!)
                    saveUserToFirestore(fUser: user!)
                    
                    completion(error, true)
                    
                } else {
                    //    we have no user, register
                    let fUser = FUser(_objectId: firuser!.user.uid, _pushId: "", _createdAt: Date(), _updatedAt: Date(), _email: "", _firstname: "", _lastname: "", _avatar: "", _loginMethod: kPHONE, _phoneNumber: firuser!.user.phoneNumber!, _city: "", _country: "", _countryCode: "")
                    
                    saveUserLocally(fUser: fUser)
                    saveUserToFirestore(fUser: fUser)
                    completion(error, false)
                }
                
            })
        }
    }
    
    // MARK: LogOut func
    
    class func logOutCurrentUser(completion: @escaping (_ success: Bool) -> Void) {
        userDefaults.removeObject(forKey: kPUSHID)
        removeOneSignalId()
        
        userDefaults.removeObject(forKey: kCURRENTUSER)
        userDefaults.synchronize()
        
        do {
            try Auth.auth().signOut()
            completion(true)
            
        } catch let error as NSError {
            completion(false)
            print(error.localizedDescription)
        }
    }
    
    // MARK: Delete user
    
    class func deleteUser(completion: @escaping (_ error: Error?) -> Void) {
        let user = Auth.auth().currentUser
        
        user?.delete(completion: { error in
            
            completion(error)
        })
    }
} // end of class funcs

// MARK: Save user funcs

func saveUserToFirestore(fUser: FUser) {
    reference(.User).document(fUser.objectId).setData(userDictionaryFrom(user: fUser) as! [String: Any]) { error in
        
        print("error is \(error?.localizedDescription)")
    }
}

func saveUserLocally(fUser: FUser) {
    UserDefaults.standard.set(userDictionaryFrom(user: fUser), forKey: kCURRENTUSER)
    UserDefaults.standard.synchronize()
}

// MARK: Fetch User funcs

// New firestore
func fetchCurrentUserFromFirestore(userId: String) {
    reference(.User).document(userId).getDocument { snapshot, _ in
        
        guard let snapshot = snapshot else { return }
        
        if snapshot.exists {
            print("updated current users param")
            
            UserDefaults.standard.setValue(snapshot.data(), forKeyPath: kCURRENTUSER)
            UserDefaults.standard.synchronize()
            OneSignal.sendTag("userId", value: FUser.currentId())
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UserSavedLocally"), object: nil, userInfo: nil)
            // startActivityMonitoring()
        }
    }
}

func startActivityMonitoring() {
    let userId = Auth.auth().currentUser?.uid
    
    let userStatusDatabaseRef = Database.database().reference(withPath: "status/" + userId!)
    
    let isOfflineForDatabase = ["state": "Offline", "last_changed": ServerValue.timestamp(), "userId": userId!] as [String: Any]
    let isOnlineForDatabase = ["state": "Online", "last_changed": ServerValue.timestamp(), "userId": userId!] as [String: Any]
    
    Database.database().reference(withPath: ".info/connected").observe(.value) { snapshot in
        if snapshot.value == nil {
            // userStatusDatabaseRef.setValue(isOfflineForDatabase)
            return
        }
        userStatusDatabaseRef.onDisconnectSetValue(isOfflineForDatabase) { _, _ in
            // userStatusDatabaseRef.setValue(isOnlineForDatabase)
            userStatusDatabaseRef.setValue(isOnlineForDatabase)
        }
    }
    
    let userStatusFirestoreRef = Firestore.firestore().document("/status/" + userId!)
    
    let isOnlineForFirestore = ["state": "Online", "last_changed": FieldValue.serverTimestamp(), "userId": userId!] as [String: Any]
    let isOfflineForFirestore = ["state": "Offline", "last_changed": FieldValue.serverTimestamp(), "userId": userId!] as [String: Any]
    
    //        userStatusFirestoreRef.addSnapshotListener(includeMetadataChanges: true) { (snapshot, error) in
    //
    //            guard let snapshot = snapshot else { return }
    //
    //            if snapshot.data() != nil {
    //                let isOnline = snapshot.data()!["state"] as! String == "Online"
    //                         if isOnline {
    //                             print("O     N     L     I      N     E")
    //                         }else {
    //                             print(" O O O O F  L I N  N E E E E")
    //                         }
    //                     }
    //            }
    
    Database.database().reference(withPath: ".info/connected").observe(.value) { snapshot in
        
        if snapshot.value == nil {
            userStatusFirestoreRef.setData(isOfflineForFirestore)
            return
        }
        
        userStatusDatabaseRef.onDisconnectSetValue(isOfflineForDatabase) { _, _ in
            userStatusDatabaseRef.setValue(isOnlineForDatabase)
            userStatusFirestoreRef.setData(isOnlineForFirestore)
        }
    }
}

func fetchUser(withId userId: String, completion: @escaping (FUser) -> Void) {
    var fUser: FUser?
    
    reference(.User).document(userId).getDocument { snapshot, _ in
        
        guard let snapshot = snapshot else { return }
        
        if snapshot.exists {
            fUser = FUser(_dictionary: snapshot.data()! as NSDictionary)
            completion(fUser!)
        }
    }
}

func fetchCurrentUserFromFirestore(userId: String, completion: @escaping (_ user: FUser?) -> Void) {
    reference(.User).document(userId).getDocument { snapshot, _ in
        
        guard let snapshot = snapshot else { return }
        
        if snapshot.exists {
            let user = FUser(_dictionary: snapshot.data()! as NSDictionary)
            completion(user)
        } else {
            completion(nil)
        }
    }
}

// MARK: Helper funcs

func userDictionaryFrom(user: FUser) -> NSDictionary {
    let createdAt = dateFormatter().string(from: user.createdAt)
    let updatedAt = dateFormatter().string(from: user.updatedAt)
    
    return NSDictionary(objects: [user.objectId, createdAt, updatedAt, user.email, user.loginMethod, user.pushId!, user.firstname, user.lastname, user.fullname, user.avatar, user.contacts, user.blockedUsers, user.isOnline, user.phoneNumber, user.countryCode, user.city, user.country], forKeys: [kOBJECTID as NSCopying, kCREATEDAT as NSCopying, kUPDATEDAT as NSCopying, kEMAIL as NSCopying, kLOGINMETHOD as NSCopying, kPUSHID as NSCopying, kFIRSTNAME as NSCopying, kLASTNAME as NSCopying, kFULLNAME as NSCopying, kAVATAR as NSCopying, kCONTACT as NSCopying, kBLOCKEDUSERID as NSCopying, kISONLINE as NSCopying, kPHONE as NSCopying, kCOUNTRYCODE as NSCopying, kCITY as NSCopying, kCOUNTRY as NSCopying])
}

func getUsersFromFirestore(withIds: [String], completion: @escaping (_ usersArray: [FUser]) -> Void) {
    var count = 0
    var countNotFound = 0
    var usersArray: [FUser] = []
    
    // go through each user and download it from firestore
    for userId in withIds {
        reference(.User).document(userId).getDocument { snapshot, _ in
            guard let snapshot = snapshot else { return }
            
            if snapshot.exists {
                let user = FUser(_dictionary: snapshot.data()! as NSDictionary)
                
                count += 1
                
                // dont add if its current user
                if user.objectId != FUser.currentId() {
                    usersArray.append(user)
                }
                
            } else {
                countNotFound += 1
            }
            
            if count == withIds.count - countNotFound {
                print("count: \(count) ----- withIds: \(withIds.count)")
                // we have finished, return the array
                completion(usersArray)
            }
        }
    }
}

func updateCurrentUserInFirestore(withValues: [String: Any], completion: @escaping (_ error: Error?) -> Void) {
    if let dictionary = UserDefaults.standard.object(forKey: kCURRENTUSER) {
        var tempWithValues = withValues
        
        let currentUserId = FUser.currentId()
        
        let updatedAt = dateFormatter().string(from: Date())
        
        tempWithValues[kUPDATEDAT] = updatedAt
        
        let userObject = (dictionary as! NSDictionary).mutableCopy() as! NSMutableDictionary
        
        userObject.setValuesForKeys(tempWithValues)
        
        reference(.User).document(currentUserId).updateData(withValues) { error in
            
            if error != nil {
                completion(error)
                return
            }
            
            // update current user
            UserDefaults.standard.setValue(userObject, forKeyPath: kCURRENTUSER)
            UserDefaults.standard.synchronize()
            
            completion(error)
        }
    }
}

func updateUserInFirestore(userId: String, withValues: [String: Any], completion: @escaping (_ error: Error?) -> Void) {
    var tempWithValues = withValues
    
    let userId = userId
    
    let updatedAt = dateFormatter().string(from: Date())
    
    tempWithValues[kUPDATEDAT] = updatedAt
    
    reference(.User).document(userId).updateData(withValues) { error in
        
        if error != nil {
            completion(error)
            return
        }
        
        completion(error)
    }
}

// MARK: OneSignal

func updateOneSignalId() {
    if FUser.currentUser() != nil {
        if let pushId = UserDefaults.standard.string(forKey: kPUSHID) {
            setOneSignalId(pushId: pushId)
        } else {
            removeOneSignalId()
        }
    }
}

func setOneSignalId(pushId: String) {
    updateCurrentUserOneSignalId(newId: pushId)
}

func removeOneSignalId() {
    updateCurrentUserOneSignalId(newId: "")
}

// MARK: Updating Current user funcs

func updateCurrentUserOneSignalId(newId: String) {
    updateCurrentUserInFirestore(withValues: [kPUSHID: newId]) { error in
        if error != nil {
            print("error updating push id \(error!.localizedDescription)")
        }
    }
}

// MARK: Check User block status

func checkBlockedStatus(withUser: FUser) -> Bool {
    return withUser.blockedUsers.contains(FUser.currentId()) || FUser.currentUser()!.blockedUsers.contains(withUser.objectId)
}
