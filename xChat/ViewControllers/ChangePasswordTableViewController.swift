//
//  ChangePasswordTableViewController.swift
//  Sllick
//
//  Created by Isa  Selimi on 26.4.20.
//  Copyright © 2020 com.isaselimi. All rights reserved.
//

import Firebase
import GradientLoadingBar
import ProgressHUD
import UIKit

class ChangePasswordTableViewController: UITableViewController {
    
    @IBOutlet var currentPasswordTextField: UITextField!
    @IBOutlet var newPasswordTextField: UITextField!
    @IBOutlet var repeatNewPasswordTextField: UITextField!
    private let gradientLoadingBar = GradientLoadingBar()

    override func viewDidLoad() {
        super.viewDidLoad()
        gradientLoadingBar.gradientColors = [.systemGray, .systemGray2, .systemGray3, .systemGray4, .systemGray5, .systemGray6]
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    @IBAction func saveButtonPressed(_ sender: Any) {
        if currentPasswordTextField.text!.removeExtraSpaces().isEmpty || repeatNewPasswordTextField.text!.removeExtraSpaces().isEmpty || newPasswordTextField.text!.removeExtraSpaces().isEmpty {
            showMessage(kEMPTYFIELDS, type: .error)
        } else if newPasswordTextField.text! != repeatNewPasswordTextField.text {
            showMessage(kPASSWORDSDONTMATCH, type: .error)
        } else {
            let credential = EmailAuthProvider.credential(withEmail: FUser.currentUser()!.email, password: currentPasswordTextField.text!)
            if let user = Auth.auth().currentUser {
                gradientLoadingBar.fadeIn()
                // re authenticate the user
                user.reauthenticate(with: credential, completion: { _, error in
                    if let error = error {
                        self.gradientLoadingBar.fadeOut()
                        if let errCode = AuthErrorCode(rawValue: error._code) {
                            switch errCode {
                            case .userNotFound:
                                self.showMessage(kUSERNOTFOUND, type: .error)
                            case .wrongPassword:
                                self.showMessage("Current password is wrong", type: .error)
                            case .tooManyRequests:
                                self.showMessage("Please wait before you try again", type: .error)

                            default:
                                self.showMessage(kSOMETHINGWENTWRONG, type: .error)
                            }
                        }
                    } else {
                        user.updatePassword(to: self.newPasswordTextField.text!) { error in
                            self.gradientLoadingBar.fadeOut()
                            if let error = error {
                                if let errCode = AuthErrorCode(rawValue: error._code) {
                                    switch errCode {
                                    case .weakPassword: self.showMessage("Provide a stronger password", type: .error)
                                    case .tooManyRequests: self.showMessage("Please wait before you try again", type: .error)
                                    default: self.showMessage(kSOMETHINGWENTWRONG, type: .error)
                                    }
                                }
                            } else {
                                ProgressHUD.showSuccess("Password successfully changed")
                            }
                        }
                    }
                })
            }
        }
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
