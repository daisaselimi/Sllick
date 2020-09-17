//
//  ChangeEmailTableViewController.swift
//  Sllick
//
//  Created by Isa  Selimi on 26.4.20.
//  Copyright © 2020 com.isaselimi. All rights reserved.
//

import Firebase
import GradientLoadingBar
import ProgressHUD
import UIKit

class ChangeEmailTableViewController: UITableViewController {
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    private let gradientLoadingBar = GradientLoadingBar()
    override func viewDidLoad() {
        super.viewDidLoad()
        gradientLoadingBar.gradientColors = [.systemGray, .systemGray2, .systemGray3, .systemGray4, .systemGray5, .systemGray6]
        emailTextField.text = FUser.currentUser()?.email
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    // MARK: - Table view data source
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        if emailTextField.text!.removeExtraSpaces().isEmpty || passwordTextField.text!.isEmpty {
            showMessage(kEMPTYFIELDS, type: .error)
        } else if emailTextField.text!.removeExtraSpaces() == FUser.currentUser()?.email {
            showMessage("Enter a different email", type: .error)
        } else {
            if passwordTextField.text!.removeExtraSpaces().isEmpty {
                showMessage("Enter your current password", type: .error)
                return
            }
            //  let user = Auth.auth().currentUser
            gradientLoadingBar.fadeIn()
            print(emailTextField.text!)
            let credential = EmailAuthProvider.credential(withEmail: FUser.currentUser()!.email, password: passwordTextField.text!)
            if let user = Auth.auth().currentUser {
                // re authenticate the user
                user.reauthenticate(with: credential, completion: { _, error in
                    
                    if let error = error {
                        self.gradientLoadingBar.fadeOut()
                        if let errCode = AuthErrorCode(rawValue: error._code) {
                            switch errCode {
                            case .userNotFound:
                                self.showMessage(kUSERNOTFOUND, type: .error)
                            case .wrongPassword:
                                self.showMessage(kWRONGPASSWORD, type: .error)
                            case .tooManyRequests:
                                self.showMessage("Please wait before you try again", type: .error)
                                
                            default:
                                self.showMessage(kSOMETHINGWENTWRONG, type: .error)
                            }
                        }
                    } else {
                        // User re-authenticated.
                        user.updateEmail(to: self.emailTextField.text!, completion: { error in
                            
                            if error != nil {
                                self.gradientLoadingBar.fadeOut()
                                if let errCode = AuthErrorCode(rawValue: error!._code) {
                                    switch errCode {
                                    case .invalidEmail: self.showMessage(kEMAILNOTVALID, type: .error)
                                    case .emailAlreadyInUse: self.showMessage(kEMAILALREADYINUSE, type: .error)
                                    case .tooManyRequests: self.showMessage("Please wait before you try again", type: .error)
                                    default: self.showMessage(kSOMETHINGWENTWRONG, type: .error)
                                    }
                                }
                            } else {
                                updateCurrentUserInFirestore(withValues: [kEMAIL: self.emailTextField.text!]) { error in
                                    self.gradientLoadingBar.fadeOut()
                                    if error == nil {
                                        ProgressHUD.showSuccess("Successfully changed")
                                    } else {
                                        self.showMessage(kSOMETHINGWENTWRONG, type: .error)
                                    }
                                }
                            }
                        })
                    }
                    
                })
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    /*
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
     let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
     
     // Configure the cell...
     
     return cell
     }
     */
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
}
