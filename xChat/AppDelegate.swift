//
//  AppDelegate.swift
//  Sllick
//
//  Created by Isa  Selimi on 15.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import UIKit
import Firebase
import ProgressHUD
import OneSignal
import PushKit
import FirebaseFirestore
import GSMessages
import GradientLoadingBar
import Reachability
import SystemConfiguration

extension NSNotification.Name {
    static let globalContactsVariable = NSNotification.Name(Bundle.main.bundleIdentifier! + ".globalContactsVariable")
    static let internetConnectionState = NSNotification.Name(Bundle.main.bundleIdentifier! + ".internetConnectionState")
}

struct MyVariables {
    static var globalContactsVariable: [String] = [] {
           didSet {
               NotificationCenter.default.post(name: .globalContactsVariable, object: nil)
           }
       }
    
    static var internetConnectionState: Bool = true {
        didSet {
            NotificationCenter.default.post(name: .internetConnectionState, object: nil)
        }
    }
    
    static var wasShowingVariableInChat = false
    
    static var isSyncingContacts = false
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    //
    //    var window: UIWindow?
    //    var authListener: AuthStateDidChangeListenerHandle?
    var orientationLock = UIInterfaceOrientationMask.all
    var reachability: Reachability!
        

   
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure() 
        
        UNUserNotificationCenter.current().delegate = self
        
        

       
        checkReachability()

        setupUIForAlerts()
        GradientLoadingBar.shared.gradientColors = [UIColor.getAppColor(.light), .systemTeal, UIColor.getAppColor(.dark)]
        
       UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(UIOffset(horizontal: -1000.0, vertical: 0.0), for: .default)
       // print(FUser.currentUser()!.objectId)

   

     
        
//        Database.database().reference(withPath: ".info/connected").observe(.value) { (snapshot) in
//            if snapshot.value == nil {
//                userStatusDatabaseRef.setValue(isOfflineForDatabase)
//             return
//            }
//            userStatusDatabaseRef.onDisconnectSetValue(isOfflineForDatabase) { (error, dbref) in
//                userStatusDatabaseRef.setValue(isOnlineForDatabase)
//                userStatusDatabaseRef.setValue(isOnlineForDatabase)
//            }
//        }
        
  
        //reference(.User).document(FUser.currentUser()!.objectId).updateData([kCOUNTRYCODE : "KS"])
//        reference(.User).getDocuments { (snapshot, error) in
//            let docs = snapshot?.documents
//                            for doc in docs! {
//                                reference(.User).document(doc[kOBJECTID] as! String).updateData([kCOUNTRYCODE : "KS"])
//                            }
//        }
        
        //        // request permission from user to send notification
        //        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { authorized, error in
        //          if authorized {
        //            DispatchQueue.main.async(execute: {
        //                application.registerForRemoteNotifications()
        //            })
        //          }
        //        })
        
        
        //
        //
        //
        ////
        //        reference(.User).getDocuments { (snapshot, error) in
        //
        //            var docs = snapshot?.documents
        //
        //            for doc in docs! {
        //                var fullname = doc["fullname"] as! String
        ////                var lastName = doc["lastname"] as! String
        ////                var firstNameKeywords = createKeywords(word: firstName.lowercased())
        ////                var lastNameKeywords = createKeywords(word: lastName.lowercased())
        ////                var allKeywords = Array(firstNameKeywords.union(lastNameKeywords))
        //
        //                var keywords = Array(createKeywords(word: fullname.lowercased()))
        //                reference(.UserKeywords).addDocument(data: ["userId" : doc["objectId"], "keywords" : keywords])
        //            }
        //        }
        
        
        //        let settings = FirestoreSettings()
        //        settings.isPersistenceEnabled = false
        //
        //        var firestore = Firestore.firestore()
        //        firestore.settings = settings
        //
        //        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        //
        //        firestore = Firestore.firestore()
        //        firestore.settings = settings
        
        //        authListener = Auth.auth().addStateDidChangeListener({ (auth, user) in
        //
        //            Auth.auth().removeStateDidChangeListener(self.authListener!)
        //
        //            if user != nil {
        //                if UserDefaults.standard.object(forKey: kCURRENTUSER) != nil {
        //                    DispatchQueue.main.async {
        //                        self.goToApp()
        //                    }
        //                }
        //            }
        //        })
        
        
        //let onesignalInitSettings = [kOSSettingsKeyAutoPrompt: false]
        
        // Replace 'YOUR_APP_ID' with your OneSignal App ID.
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound], completionHandler: { (granted, error) in
            })
            application.registerForRemoteNotifications()
        } else {
            let types: UIUserNotificationType = [.alert, .badge, .sound]
            let settings = UIUserNotificationSettings(types: types, categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        //
        //        let notificationReceived: OSHandleNotificationReceivedBlock = {
        //            notification in
        //
        //            let payload: OSNotificationPayload = notification!.payload
        //
        //            if payload.additionalData != nil {
        //                let additionalData = payload.additionalData
        //                if (UIApplication.getTopViewController()?.isKind(of: ChatViewController.self))! {
        //                    if ((UIApplication.getTopViewController() as? ChatViewController)?.chatRoomId ==  (additionalData!["chatRoomId"] as! String)) {
        //                        print("WOAHHHHH")
        //                    }
        //                } else {
        //
        //                    print("NOT SAME")
        //                }
        //            }
        //
        //        }
        
        let notificationReceivedBlock: OSHandleNotificationReceivedBlock = { notification in
            
            print("Received Notification: \(notification!.payload.notificationID)")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ReceivedNotification"), object: self, userInfo: ["notificationPayload" : notification!.payload!]) // post notification to view controller
        }
        
        
        
        let notificationOpenedBlock: OSHandleNotificationActionBlock = { result in
            let payload: OSNotificationPayload = result!.notification.payload
            
            
            if payload.additionalData != nil {
                let additionalData = payload.additionalData
                
                getUsersFromFirestore(withIds: additionalData!["memberIds"] as! [String]) { (users) in
                    let chatVC = ChatViewController()
                    chatVC.membersToPush = (additionalData!["membersToPush"] as? [String])!
                    chatVC.memberIds = (additionalData!["memberIds"] as? [String])!
                    chatVC.chatRoomId = (additionalData!["chatRoomId"] as? String)!
                    chatVC.titleName = additionalData!["titleName"] as? String
                    chatVC.isGroup = additionalData!["isGroup"] as? Bool
                    chatVC.initialWithUser = chatVC.isGroup! ? additionalData!["titleName"] as? String :  (additionalData!["withUser"] as! String)
                    chatVC.initialImage = chatVC.isGroup! ? UIImage(named: "grouph") : UIImage(named: "avatarph")
                    chatVC.hidesBottomBarWhenPushed = true
                    
                    let tabBarController = UIApplication.shared.windows.first!.rootViewController! as! UITabBarController
                    tabBarController.selectedIndex = 0
                    let navigationController = tabBarController.viewControllers!.first! as! UINavigationController
                    let viewController = navigationController.viewControllers.first as! ChatsViewController
                    
                    if (UIApplication.getTopViewController()?.isKind(of: ChatViewController.self))! {
                        if ((UIApplication.getTopViewController() as? ChatViewController)?.chatRoomId !=  (additionalData!["chatRoomId"] as! String)) {
                            //                            let idx = navigationController.viewControllers.firstIndex(of: navigationController.topViewController!)
                            //                            navigationController.viewControllers.remove(at: idx!)
                            navigationController.popToRootViewController(animated: false)
                            viewController.navigationController?.pushViewController(chatVC, animated: false)
                        }
                    }
                    else {
                        let animated = (viewController.navigationController?.topViewController?.isKind(of: ChatsViewController.self))! ? true : false
                        if navigationController.viewControllers.count > 1 {
                            navigationController.popToRootViewController(animated: false)
                        }
                        
                        
                        viewController.navigationController?.pushViewController(chatVC, animated: animated)
                    }
                    
                }
            }
        }
        
        let onesignalInitSettings = [kOSSettingsKeyAutoPrompt: false,
                                     kOSSettingsKeyInAppLaunchURL: true, kOSSettingsKeyInAppAlerts : false]
        
        OneSignal.initWithLaunchOptions(launchOptions, appId: kONESIGNALAPPID, handleNotificationReceived: notificationReceivedBlock, handleNotificationAction: notificationOpenedBlock, settings: onesignalInitSettings)
        
        //         OneSignal.initWithLaunchOptions(launchOptions,
        //         appId: kONESIGNALAPPID,
        //         handleNotificationAction: nil,
        //         settings: onesignalInitSettings)
        //
        //         OneSignal.inFocusDisplayType = OSNotificationDisplayType.notification;
        //
        //         // Recommend moving the below line to prompt for push after informing the user about
        //         //   how your app will use them.
        //         OneSignal.promptForPushNotifications(userResponse: { accepted in
        //         print("User accepted notifications: \(accepted)")
        //         })
        OneSignal.inFocusDisplayType = OSNotificationDisplayType.none
        return true
    }

    func checkReachability() {
       
        do {
            reachability = try Reachability()
            reachability.whenReachable = { reachability in
                if reachability.connection == .wifi {
                    print("- - - - - - -- - - - - - - - - - - - - - - - -Reachable via WiFiiiiii")
                } else {
                    print("- - - - - - - - - - - - - - - - - - - - - -- - Reachable via Cellular")
                }
                MyVariables.internetConnectionState = true
            }
            
            reachability.whenUnreachable = { _ in
                print("- - - - - - - - - -Not reachable")
                MyVariables.internetConnectionState = false
            }
            
            do {
                try reachability.startNotifier()
            } catch {
                print("Unable to start notifier")
            }
        } catch {
            print("Unable to start reachability")
        }
    }
    
    func setupUIForAlerts() {
        GSMessage.font = UIFont.boldSystemFont(ofSize: 14)
      //  GSMessage.successBackgroundColor = UIColor(red: 142.0/255, green: 183.0/255, blue: 64.0/255,  alpha: 0.95)
       // GSMessage.warningBackgroundColor = UIColor(red: 230.0/255, green: 189.0/255, blue: 1.0/255,   alpha: 0.95)
        GSMessage.errorBackgroundColor   = UIColor.systemPink.withAlphaComponent(0.7)
        //GSMessage.infoBackgroundColor    = UIColor(red: 44.0/255,  green: 187.0/255, blue: 255.0/255, alpha: 0.90)
    }
    
    //    func goToApp() {
    //
    //        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo:  [kUSERID : FUser.currentId()])
    //        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "mainApplication") as! UITabBarController
    //
    //        self.window?.rootViewController = mainView
    //    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
//        updateUserInFirestore(userId: FUser.currentId(), withValues: [kISONLINE : false]) { (error) in
//
//        }
    }
    
    //    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    //
    //             // show the notification alert (banner), and with sound
    //             completionHandler([.alert, .sound])
    //           }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let dictionaryItm = userInfo as? [String : [String : Any]]
        
        let dictionaryItem = dictionaryItm!["additionalData"]
        
        if (dictionaryItem?["inApp"]) == nil {
            return 
        }
        
        getUsersFromFirestore(withIds: dictionaryItem!["memberIds"] as! [String]) { (users) in
            let chatVC = ChatViewController()
            chatVC.membersToPush = (dictionaryItem!["membersToPush"] as? [String])!
            chatVC.memberIds = (dictionaryItem!["memberIds"] as? [String])!
            chatVC.chatRoomId = (dictionaryItem!["chatRoomId"] as? String)!
            chatVC.titleName = dictionaryItem!["titleName"] as? String
            chatVC.isGroup = dictionaryItem!["isGroup"] as? Bool
            chatVC.initialWithUser = chatVC.isGroup! ? dictionaryItem!["titleName"] as? String :  (dictionaryItem!["withUser"] as! String)
            chatVC.initialImage =  chatVC.isGroup! ? UIImage(named: "grouph") : UIImage(named: "avatarph")
            chatVC.hidesBottomBarWhenPushed = true
            
            let tabBarController = UIApplication.shared.windows.first!.rootViewController! as! UITabBarController
            tabBarController.selectedIndex = 0
            let navigationController = tabBarController.viewControllers!.first! as! UINavigationController
            let viewController = navigationController.viewControllers.first as! ChatsViewController
            
            if (UIApplication.getTopViewController()?.isKind(of: ChatViewController.self))! {
                if ((UIApplication.getTopViewController() as? ChatViewController)?.chatRoomId !=  (dictionaryItem!["chatRoomId"] as! String)) {
                    //                            let idx = navigationController.viewControllers.firstIndex(of: navigationController.topViewController!)
                    //                            navigationController.viewControllers.remove(at: idx!)
                    navigationController.popToRootViewController(animated: false)
                    viewController.navigationController?.pushViewController(chatVC, animated: false)
                }
            }
            else {
                let animated = (viewController.navigationController?.topViewController?.isKind(of: ChatsViewController.self))! ? true : false
                if navigationController.viewControllers.count > 1 {

                    navigationController.popToRootViewController(animated: false)
                }
                          UIApplication.getTopViewController()?.dismiss(animated: true, completion: nil)
                
                viewController.navigationController?.pushViewController(chatVC, animated: animated)
            }
            completionHandler()
            
        }
    }
    
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }
    
    struct AppUtility {
        static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                delegate.orientationLock = orientation
            }
        }
        
        static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
            self.lockOrientation(orientation)
            UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
        }
    }
}

func createKeywords(word: String) -> Set<String> {
    var allKeywords: Set<String> = Set<String>()
    
    for num in 0..<word.count {
        for num1 in num...word.count {
            if num == num1 {
                continue
            }
            let substr = word[num..<num1]
            if substr == " " || substr == ""{
                continue
            }
            allKeywords.insert(substr)
        }
    }
    
    return allKeywords
}

extension String {
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }
    
    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
    
    func removeExtraSpaces() -> String {
        return self.replacingOccurrences(of: "[\\s\n]+", with: " ", options: .regularExpression, range: nil)
    }
    
}


