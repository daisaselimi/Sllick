//
//  SceneDelegate.swift
//  Sllick
//
//  Created by Isa  Selimi on 15.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import UIKit
import Firebase
import ProgressHUD
import FirebaseAuth
import FirebaseFirestore
import PushKit
import OneSignal

class SceneDelegate: UIResponder, UIWindowSceneDelegate, SINClientDelegate, SINCallClientDelegate, SINManagedPushDelegate, PKPushRegistryDelegate   {
    
    var window: UIWindow?
    var authListener: AuthStateDidChangeListenerHandle?
    
    var _client: SINClient!
    var push: SINManagedPush!
    
    var callKitProvider: SINCallKitProvider!
    
    
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions:
        UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        self.window?.backgroundColor = .systemBackground
        guard let _ = (scene as? UIWindowScene) else { return }
        let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
        
        if !launchedBefore
        {
            UserDefaults.standard.set(true, forKey: kDARKMODESTATUS)
            UserDefaults.standard.set(true, forKey: kSHOWAVATAR)
            UserDefaults.standard.set(true, forKey: "launchedBefore")
        }
        loadUserDefaults()
        authListener = Auth.auth().addStateDidChangeListener({ (auth, user) in
            
            Auth.auth().removeStateDidChangeListener(self.authListener!)
            
            if Auth.auth().currentUser == nil {

                self.window!.showMessage("Transaction limit exceeded. Please try again later.", type: .error)
          
                      
            }
            if user != nil && UserDefaults.standard.object(forKey: kCURRENTUSER) != nil  {
                customizeNavigationBar(colorName: "bwBackground")
                DispatchQueue.main.async {
                    print("App")
                    ProgressHUD.hudColor(.clear)
                    ProgressHUD.statusColor(.label)
                    OneSignal.sendTag("userId", value: FUser.currentId())
                    self.goToView(named: kMAINAPPLICATION)
                }
            } else {
                customizeNavigationBar(colorName: "bcg")
                print("Welcome")
                ProgressHUD.hudColor(.clear)
                ProgressHUD.statusColor(.label)
                self.goToView(named: "navInit")
            }
        })
        
        //        let userId = FUser.currentId()
        //
        //        var userStatusDatabaseReference = Database.database().reference(withPath: "/status/" + userId)
        //
        //        var isOfflineForDatabase = (state: "offline", last_changed: Firebase.ServerValue.timestamp())
        //
        //        var isOnlineForDatabase = (state: "online", last_changed: Firebase.ServerValue.timestamp())
        //
        //
        //
        //        Database.database().reference(withPath: ".info/connected").observe(.value, with: {
        //            snapshot in
        //            if snapshot.value as? Bool ?? false {
        //                userStatusDatabaseReference.onDisconnectSetValue(isOfflineForDatabase)
        //
        //            } else {
        //                userStatusDatabaseReference.setValue(isOnlineForDatabase)
        //                userStatusDatabaseReference.onDisconnectSetValue(isOfflineForDatabase)
        //            }
        //        })
        //
        //
        
        self.voipRegistration()
        
        self.push = Sinch.managedPush(with: .production)
        self.push.delegate = self
        self.push.setDesiredPushTypeAutomatically()
        
        func userDidLogin(userId: String) {
            self.push.registerUserNotificationSettings()
            self.initSinchWithUserId(userId: userId)
            self.startOneSignal()
            
        }
        
        
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, queue: nil) { (notification) in
            
            let userId = notification.userInfo![kUSERID] as! String
            UserDefaults.standard.set(userId, forKey: kUSERID)
            UserDefaults.standard.synchronize()
            userDidLogin(userId: userId)
            
        }
        
        
        
        
    }
    
    func startOneSignal() {
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        
        let userID = status.subscriptionStatus.userId
        let pushToken = status.subscriptionStatus.pushToken
        
        if pushToken != nil {
            if let playerID = userID {
                UserDefaults.standard.set(playerID, forKey: kPUSHID)
            } else {
                UserDefaults.standard.removeObject(forKey: kPUSHID)
            }
            UserDefaults.standard.synchronize()
        }
        
        updateOneSignalId()
    }
    
    func loadUserDefaults() {
        
        let darkModeStatus = userDefaults.bool(forKey: kDARKMODESTATUS)
        
        if darkModeStatus{
            UIApplication.shared.windows.forEach { (window) in
                window.overrideUserInterfaceStyle = .dark
            }
        } else {
            UIApplication.shared.windows.forEach { (window) in
                window.overrideUserInterfaceStyle = .light
            }
        }
        
    }
    
    func goToView(named name: String) {
        
        if name == kMAINAPPLICATION {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo:  [kUSERID : FUser.currentId()])
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let initialViewController = storyboard.instantiateViewController(withIdentifier: name)
        self.window?.rootViewController = initialViewController
        self.window?.makeKeyAndVisible()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        updateCurrentUserInFirestore(withValues: [kISONLINE : false]) { (error) in
            
        }
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        
       // UIApplication.shared.applicationIconBadgeNumber = 0
        var top = self.window?.rootViewController
        
        while top?.presentedViewController != nil {
            top = top?.presentedViewController
        }
        
        if top! is UITabBarController {
            setBadges(controller: top as! UITabBarController)
        }
        
        updateCurrentUserInFirestore(withValues: [kISONLINE : true]) { (error) in
            
        }
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    public func startSinch(userId: String) {
        self.push.registerUserNotificationSettings()
        self.initSinchWithUserId(userId: userId)
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        updateCurrentUserInFirestore(withValues: [kISONLINE : false]) { (error) in
            
        }
        if callKitProvider != nil {
            let call = callKitProvider.currentEstablishedCall()
            
            if call != nil {
                var top = self.window?.rootViewController
                
                while (top?.presentedViewController != nil) {
                    top = top?.presentedViewController
                }
                
                
                if !(top! is CallViewController) {
                    let callVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CallVC") as! CallViewController
                    
                    callVC._call = call
                    
                    top?.present(callVC, animated: true, completion: nil)
                }
            }
        }
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        if let rctBadgeHangler = recentBadgeHandler {
            rctBadgeHangler.remove()
        }
        
        updateCurrentUserInFirestore(withValues: [kISONLINE : false]) { (error) in
            
        }
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    //MARK: Sinch
    
    func initSinchWithUserId(userId: String) {
        if _client == nil {
            _client = Sinch.client(withApplicationKey: kSINCHKEY, applicationSecret: kSINCHSECRET, environmentHost: "sandbox.sinch.com", userId: userId)
            _client.delegate = self
            _client.call()?.delegate = self
            _client.setSupportCalling(true)
            _client.enableManagedPushNotifications()
            _client.start()
            _client.startListeningOnActiveConnection()
            callKitProvider = SINCallKitProvider(withClient: _client)        }
    }
    
    //MARK: SinchManagedPushDelegate
    
    func managedPush(_ managedPush: SINManagedPush!, didReceiveIncomingPushWithPayload payload: [AnyHashable : Any]!, forType pushType: String!) {
        
        print("managed push")
        if pushType == "PKPushTypeVoIP" {
            self.handleRemoteNotification(userInfo: payload as NSDictionary)
        }
    }
    
    func handleRemoteNotification(userInfo: NSDictionary) {
        print("got rem not")
        if _client == nil {
            if let userId = UserDefaults.standard.object(forKey: kUSERID) {
                self.initSinchWithUserId(userId: userId as! String)
            }
        }
        
        let result = self._client.relayRemotePushNotification((userInfo as! [AnyHashable : Any]))
        
        if result!.isCall() {
            print("handle call notification")
        }
        
        if result!.isCall() && result!.call()!.isCallCanceled {
            self.presentMissedCallNotificationWithRemoteUserId(userId: result!.call()!.callId)
        }
    }
    
    func presentMissedCallNotificationWithRemoteUserId(userId: String) {
        if UIApplication.shared.applicationState == .background {
            
            let center = UNUserNotificationCenter.current()
            getUsersFromFirestore(withIds: [userId]) { (users) in
                let content = UNMutableNotificationContent()
                content.title = "Missed Call"
                content.body = "From \(users[0].fullname)"
                content.sound = UNNotificationSound.default
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                
                let request = UNNotificationRequest(identifier: "ContentIdentifier", content: content, trigger: trigger)
                
                center.add(request) { (error) in
                    
                    if error != nil {
                        print("error on notification", error!.localizedDescription)
                    }
                }
            }
            
        }
    }
    
    //MARK: SinchCallClientDelegate
    
    func client(_ client: SINCallClient!, willReceiveIncomingCall call: SINCall!) {
        print("will receive incoming call")
        callKitProvider.reportNewIncomingCall(call: call)
    }
    
    func client(_ client: SINCallClient!, didReceiveIncomingCall call: SINCall!) {
        print("........did receive call")
        
        //present call view
        var top = self.window?.rootViewController
        
        while (top?.presentedViewController != nil) {
            top = top?.presentedViewController
        }
        
        let callVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CallVC") as! CallViewController
        let id =  call.remoteUserId
      
        getUsersFromFirestore(withIds: [id!]) { (allUsers) in
            if allUsers.count > 0 {
                let user = allUsers.first!
                callVC.callingName = user.fullname
                imageFromData(pictureData: user.avatar) { (image) in
                    if image != nil {
                        callVC.callingImage = image!.circleMasked
                    } else {
                        callVC.callingImage = UIImage(named: "avatarph")
                    }
                    callVC._call = call
                    top?.present(callVC, animated: true, completion: nil)
                }
            }
        }
      
        
        
    }
    
    func clientDidStop(_ client: SINClient!) {
        print("sinch did stop")
    }
    
    func clientDidStart(_ client: SINClient!) {
        print("sinch did start")
    }
    
    func clientDidFail(_ client: SINClient!, error: Error!) {
        print("dinch did fail")
    }
    
    func voipRegistration() {
        let voipRegistry: PKPushRegistry = PKPushRegistry(queue: DispatchQueue.main)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [PKPushType.voIP]
    }
    
    
    //MARK: PHPushDelegate
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        print("did get incoming push")
        self.handleRemoteNotification(userInfo: payload.dictionaryPayload as NSDictionary)
    }
    
    //MARK: PushNotification functions
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        //self.push.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        Auth.auth().setAPNSToken(deviceToken, type:AuthAPNSTokenType.sandbox)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        let firebaseAuth = Auth.auth()
        if firebaseAuth.canHandleNotification(userInfo) {
            return
        } else {
            //self.push.application(application, didReceiveRemoteNotification: userInfo)
        }
    }
    
    func setRootViewController(_ vc: UIViewController, animated: Bool = true) {
        guard animated, let window = self.window else {
            self.window?.rootViewController = vc
            self.window?.makeKeyAndVisible()
            return
        }

        window.rootViewController = vc
        window.makeKeyAndVisible()
        UIView.transition(with: window,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: nil,
                          completion: nil)
    }
    
}
