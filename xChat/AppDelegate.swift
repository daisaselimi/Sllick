//
//  AppDelegate.swift
//  Sllick
//
//  Created by Isa  Selimi on 15.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import Firebase
import FirebaseFirestore
import GradientLoadingBar
import GSMessages
import OneSignal
import ProgressHUD
import PushKit
import Reachability
import SystemConfiguration
import UIKit

extension NSNotification.Name {
    static let globalContactsVariable = NSNotification.Name(Bundle.main.bundleIdentifier! + ".globalContactsVariable")
    static let internetConnectionState = NSNotification.Name(Bundle.main.bundleIdentifier! + ".internetConnectionState")
    static let onlineUsersNotification = NSNotification.Name(Bundle.main.bundleIdentifier! + ".onlineUsersNotification")
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var orientationLock = UIInterfaceOrientationMask.all
    var reachability: Reachability!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        UNUserNotificationCenter.current().delegate = self
        
        checkReachability()
        
        setupUIForAlerts()
        GradientLoadingBar.shared.gradientColors = [UIColor.getAppColor(.light), .systemTeal, UIColor.getAppColor(.dark)]
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(named: "outgoingBubbleColor")
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound], completionHandler: { _, _ in
            })
            application.registerForRemoteNotifications()
        } else {
            let types: UIUserNotificationType = [.alert, .badge, .sound]
            let settings = UIUserNotificationSettings(types: types, categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        let notificationReceivedBlock: OSHandleNotificationReceivedBlock = { notification in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ReceivedNotification"), object: self, userInfo: ["notificationPayload": notification!.payload!]) // post notification to view controller
        }
        
        let notificationOpenedBlock: OSHandleNotificationActionBlock = { result in
            let payload: OSNotificationPayload = result!.notification.payload
            
            if payload.additionalData != nil {
                let additionalData = payload.additionalData
                
                getUsersFromFirestore(withIds: additionalData!["memberIds"] as! [String]) { _ in
                    let chatVC = ChatViewController()
                    chatVC.membersToPush = (additionalData!["membersToPush"] as? [String])!
                    chatVC.memberIds = (additionalData!["memberIds"] as? [String])!
                    chatVC.chatRoomId = (additionalData!["chatRoomId"] as? String)!
                    chatVC.titleName = additionalData!["titleName"] as? String
                    chatVC.isGroup = additionalData!["isGroup"] as? Bool
                    chatVC.initialWithUser = chatVC.isGroup! ? additionalData!["titleName"] as? String : (additionalData!["withUser"] as! String)
                    chatVC.initialImage = chatVC.isGroup! ? UIImage(named: "grouph") : UIImage(named: "avatarph")
                    chatVC.hidesBottomBarWhenPushed = true
                    
                    let tabBarController = UIApplication.shared.windows.first!.rootViewController! as! UITabBarController
                    tabBarController.selectedIndex = 0
                    let navigationController = tabBarController.viewControllers!.first! as! UINavigationController
                    let viewController = navigationController.viewControllers.first as! ChatsViewController
                    
                    if (UIApplication.getTopViewController()?.isKind(of: ChatViewController.self))! {
                        if (UIApplication.getTopViewController() as? ChatViewController)?.chatRoomId != (additionalData!["chatRoomId"] as! String) {
                            navigationController.popToRootViewController(animated: false)
                            viewController.navigationController?.pushViewController(chatVC, animated: false)
                        }
                    } else {
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
                                     kOSSettingsKeyInAppLaunchURL: true, kOSSettingsKeyInAppAlerts: false]
        
        OneSignal.initWithLaunchOptions(launchOptions, appId: kONESIGNALAPPID, handleNotificationReceived: notificationReceivedBlock, handleNotificationAction: notificationOpenedBlock, settings: onesignalInitSettings)
        
        OneSignal.inFocusDisplayType = OSNotificationDisplayType.none
        return true
    }
    
    func checkReachability() {
        do {
            reachability = try Reachability()
            reachability.whenReachable = { reachability in
                if reachability.connection == .wifi {
                    print("- - - - - - -- - - - - - - - - - - - - - - - -Reachable via WiFi")
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
        GSMessage.warningBackgroundColor = UIColor.systemGray6
        
        GSMessage.errorBackgroundColor = UIColor.systemPink.withAlphaComponent(0.7)
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
    
    func applicationWillTerminate(_ application: UIApplication) {}
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let dictionaryItm = userInfo as? [String: [String: Any]]
        
        let dictionaryItem = dictionaryItm!["additionalData"]
        
        if (dictionaryItem?["inApp"]) == nil {
            return
        }
        
        getUsersFromFirestore(withIds: dictionaryItem!["memberIds"] as! [String]) { _ in
            let chatVC = ChatViewController()
            chatVC.membersToPush = (dictionaryItem!["membersToPush"] as? [String])!
            chatVC.memberIds = (dictionaryItem!["memberIds"] as? [String])!
            chatVC.chatRoomId = (dictionaryItem!["chatRoomId"] as? String)!
            chatVC.titleName = dictionaryItem!["titleName"] as? String
            chatVC.isGroup = dictionaryItem!["isGroup"] as? Bool
            chatVC.initialWithUser = chatVC.isGroup! ? dictionaryItem!["titleName"] as? String : (dictionaryItem!["withUser"] as! String)
            chatVC.initialImage = chatVC.isGroup! ? UIImage(named: "grouph") : UIImage(named: "avatarph")
            chatVC.hidesBottomBarWhenPushed = true
            
            let tabBarController = UIApplication.shared.windows.first!.rootViewController! as! UITabBarController
            tabBarController.selectedIndex = 0
            let navigationController = tabBarController.viewControllers!.first! as! UINavigationController
            let viewController = navigationController.viewControllers.first as! ChatsViewController
            
            if (UIApplication.getTopViewController()?.isKind(of: ChatViewController.self))! {
                if (UIApplication.getTopViewController() as? ChatViewController)?.chatRoomId != (dictionaryItem!["chatRoomId"] as! String) {
                    navigationController.popToRootViewController(animated: false)
                    viewController.navigationController?.pushViewController(chatVC, animated: false)
                }
            } else {
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
        return orientationLock
    }
    
    struct AppUtility {
        static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                delegate.orientationLock = orientation
            }
        }
        
        static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation: UIInterfaceOrientation) {
            lockOrientation(orientation)
            UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
        }
    }
}

func changePresenceStatusForAllUsers() {
    reference(.status).getDocuments { snapshot, _ in
        
        let docs = snapshot?.documents
        
        for doc in docs! {
            reference(.status).document(doc[kUSERID] as! String).updateData(["state": "Offline"])
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
            if substr == " " || substr == "" {
                continue
            }
            allKeywords.insert(substr)
        }
    }
    
    return allKeywords
}
