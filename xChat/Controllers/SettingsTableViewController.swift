//
//  SettingsTableViewController.swift
//  Sllick
//
//  Created by Isa  Selimi on 18.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import Firebase
import GSMessages
import OneSignal
import ProgressHUD
import UIKit

class SettingsTableViewController: UITableViewController {
    
    @IBOutlet var avatarImageView: UIImageView!
    @IBOutlet var fullNameLabel: UILabel!
    @IBOutlet var showAvatarStatusSwitch: UISwitch!
    @IBOutlet var deleteButtonOutlet: UIButton!
    @IBOutlet var versionLabel: UILabel!
    @IBOutlet var darkModeSwitch: UISwitch!
    
    var avatarSwitchStatus = false
    var darkModeStatus = false
    let userDefaults = UserDefaults.standard
    var firstLoad: Bool?
    
    override func viewWillAppear(_ animated: Bool) {
        let scene = UIApplication.shared.connectedScenes.first
        if let sd: SceneDelegate = (scene?.delegate as? SceneDelegate) {
            sd.window!.backgroundColor = .black
        }
    }
    
    override func viewDidLayoutSubviews() {
        if FUser.currentUser() != nil {
            setupUI()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if FUser.currentUser() != nil {
            loadUserDefaults()
        }
        
        // tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        showAvatarStatusSwitch.onTintColor = UIColor.getAppColor(.light)
        darkModeSwitch.onTintColor = UIColor.getAppColor(.light)
        // navigationController?.navigationBar.prefersLargeTitles = true
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 49, bottom: 0, right: 0)
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = UIColor(named: "bwBackground")
        
//         self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
//                       self.navigationController?.navigationBar.shadowImage = UIImage()
//        self.navigationController?.navigationBar.backgroundColor = UIColor(named: "bwBackground")?.withAlphaComponent(0.9)
//        self.navigationController?.navigationBar.isTranslucent = true
        //        self.navigationController?.navigationBar.tintColor = UIColor(named: "bwBackground")
//        self.navigationController?.navigationBar.alpha = 0.0
//        self.navigationController?.navigationBar.isTranslucent = true
        // self.navigationController?.navigationBar.alpha = 0.7
        
        tableView.separatorColor = .separator
        setupUI()
        //        avatarImageView.addShadow()
        //                tableView.layoutMargins = UIEdgeInsets.zero
        //                tableView.separatorInset = UIEdgeInsets.zero
        //                tableView.separatorInset = UIEdgeInsets(top: 0, left: 39, bottom: 0, right: 0)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 4
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 0 {
            return 1
        }
        if section == 1 {
            return 7
        }
        return 2
    }
    
    // table view delegate
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return 30
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor(named: "secondaryBwBackground")
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            switch indexPath.row {
            case 0: performSegue(withIdentifier: "goToAccount", sender: self)
            case 6: performSegue(withIdentifier: "goToBlockedUsersView", sender: self)
            case 2: performSegue(withIdentifier: "goToBackgroundsView", sender: self)
            case 3: clearCache()
            case 4: tellAFriend()
                
            default:
                print("")
            }
            
        } else if indexPath.section == 2 {
            switch indexPath.row {
            case 0: performSegue(withIdentifier: "goToTermnsAndConditions", sender: self)
            default:
                print("")
            }
        } else if indexPath.section == 3 {
            switch indexPath.row {
            case 0: logOutUser()
            case 1: deleteAccountPressed()
            default:
                print("")
            }
        }
    }
    
    func presentWelcomeView() {
        let mainView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "navInit")
        let scene = UIApplication.shared.connectedScenes.first
        if let sd: SceneDelegate = (scene?.delegate as? SceneDelegate) {
            customizeNavigationBar(colorName: "bcg")
            sd.setRootViewController(mainView)
            sd.window!.makeKeyAndVisible()
        }
    }
    
    @IBAction func showAvatarSwitchValueChanged(_ sender: UISwitch) {
        avatarSwitchStatus = sender.isOn
        saveUserDefaults()
    }
    
    @IBAction func darkModeSwitchValueChanged(_ sender: UISwitch) {
        if sender.isOn {
            switchUIStyle(.dark)
            
        } else {
            switchUIStyle(.light)
        }
        darkModeStatus = sender.isOn
        userDefaults.set(darkModeStatus, forKey: kDARKMODESTATUS)
        userDefaults.synchronize()
    }
    
    @IBAction func donePressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func switchUIStyle(_ style: UIUserInterfaceStyle) {
        UIView.transition(with: UIApplication.shared.windows.first { $0.isKeyWindow }!, duration: 0.2, options: .transitionCrossDissolve, animations: { UIApplication.shared.windows.forEach { window in
            window.overrideUserInterfaceStyle = style
            } }, completion: nil)
    }
    
    func clearCache() {
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: getDocumentsURL().path)
            
            for file in files {
                try FileManager.default.removeItem(atPath: "\(getDocumentsURL().path)/\(file)")
                showMessage("Cache cleared", type: .success)
            }
        } catch {
            showMessage("Could not clear cache", type: .error)
        }
    }
    
    func tellAFriend() {
        let text = "Hey! Let's chat on Sllick: \(kAPPURL)"
        
        let objectsToShare: [Any] = [text]
        
        let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        
        // for iPad
        activityViewController.popoverPresentationController?.sourceView = view
        
        activityViewController.setValue("Let's chat on Sllick", forKey: "subject")
        
        present(activityViewController, animated: true, completion: nil)
    }
    
    func deleteAccountPressed() {
        let optionMenu = UIAlertController(title: "Deleting Account", message: "Are you sure you want to delete the account? You can not undo this action.", preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            
            self.showInputDialog(title: "Confirm with password",
                                 subtitle: "Enter password to proceed with account deletion",
                                 actionTitle: "Proceed",
                                 cancelTitle: "Cancel",
                                 inputPlaceholder: "Password",
                                 inputKeyboardType: .default)
            { (input: String?) in
                let eMail = EmailAuthProvider.credential(withEmail: FUser.currentUser()!.email, password: input!)
                
                Auth.auth().currentUser?.reauthenticate(with: eMail, completion: {
                    // [weak self]
                    _, error in
                    
                    if error == nil {
                        self.deleteUser()
                    } else {
                        if let errCode = AuthErrorCode(rawValue: error!._code) {
                            switch errCode {
                            case .wrongPassword:
                                self.showMessage(kWRONGPASSWORD, type: .error)
                            case .tooManyRequests:
                                self.showMessage(kWAITBEFOREYOUTRYAGAIN, type: .error)
                            default:
                                self.showMessage(kSOMETHINGWENTWRONG, type: .error)
                            }
                        }
                    }
                    
                })
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
        }
        
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(cancelAction)
        if UIDevice().userInterfaceIdiom == .pad {
            if let currentPopoverpresentioncontroller = optionMenu.popoverPresentationController {
                currentPopoverpresentioncontroller.sourceView = deleteButtonOutlet
                currentPopoverpresentioncontroller.sourceRect = deleteButtonOutlet.bounds
                
                currentPopoverpresentioncontroller.permittedArrowDirections = .up
                present(optionMenu, animated: true, completion: nil)
            }
        } else {
            present(optionMenu, animated: true, completion: nil)
        }
    }
    
    func logOutUser() {
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let loUser: String = FUser.currentId()
        let logOutAction = UIAlertAction(title: "Log Out", style: .destructive) { _ in
            updateUserInFirestore(userId: loUser, withValues: [kPUSHID: ""]) { _ in
            }
            FUser.logOutCurrentUser { success in
                
                if success {
                    UIApplication.shared.applicationIconBadgeNumber = 0
                    OneSignal.deleteTag("userId")
                    self.presentWelcomeView()
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
        }
        
        optionMenu.addAction(logOutAction)
        optionMenu.addAction(cancelAction)
        present(optionMenu, animated: true, completion: nil)
    }
    
    // MARK: SetupUI
    
    func setupUI() {
        let currentUser = FUser.currentUser()!
        
        fullNameLabel.text = currentUser.fullname
        
        if currentUser.avatar != "" {
            imageFromData(pictureData: currentUser.avatar) { avatarImage in
                
                if avatarImage != nil {
                    self.avatarImageView.image = avatarImage
                    self.avatarImageView.maskCircle()
                }
            }
        } else {
            avatarImageView.image = UIImage(named: "avatarph")
            
            avatarImageView.maskCircle()
        }
        
        // set app version
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionLabel.text = version
        }
    }
    
    // MARK: DeleteUser
    
    func deleteUser() {
        // delete from authentication section on firebase
        let currentUserId = FUser.currentId()
        FUser.deleteUser { error in
            
            if error != nil {
                DispatchQueue.main.async {
                    self.showMessage("Could not delete account", type: .error)
                }
                
            } else {
                // delete locally
                self.userDefaults.removeObject(forKey: kPUSHID)
                self.userDefaults.removeObject(forKey: kCURRENTUSER)
                self.userDefaults.synchronize()
                // delete from firebaseZ
                
                reference(.User).document(currentUserId).delete()
                updateRecent(thatContainsID: currentUserId, withValues: [kWITHUSERACCOUNTSTATUS: kDELETED, kAVATAR: "", kWITHUSERFULLNAME: "Sllick User"])
                UIApplication.shared.applicationIconBadgeNumber = 0
                OneSignal.deleteTag("userId")
                self.presentWelcomeView()
            }
        }
    }
    
    // MARK: UserDefauilt
    
    func saveUserDefaults() {
        userDefaults.set(avatarSwitchStatus, forKey: kSHOWAVATAR)
        userDefaults.synchronize()
    }
    
    func loadUserDefaults() {
        //        firstLoad = userDefaults.bool(forKey: kFIRSTRUN)
        //
        //        if !firstLoad! {
        //            userDefaults.set(true, forKey: kFIRSTRUN)
        //            userDefaults.set(avatarSwitchStatus, forKey: kSHOWAVATAR)
        //            userDefaults.set(darkModeStatus, forKey: kDARKMODESTATUS)
        //            userDefaults.synchronize()
        //        }
        //
        avatarSwitchStatus = userDefaults.bool(forKey: kSHOWAVATAR)
        darkModeStatus = userDefaults.bool(forKey: kDARKMODESTATUS)
        darkModeSwitch.isOn = darkModeStatus
        showAvatarStatusSwitch.isOn = avatarSwitchStatus
    }
}
