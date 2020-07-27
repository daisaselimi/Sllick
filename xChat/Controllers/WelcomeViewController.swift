//
//  WelcomeViewController.swift
//  Sllick
//
//  Created by Isa  Selimi on 15.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import FirebaseAuth
import GradientLoadingBar
import ProgressHUD
import UIKit

class WelcomeViewController: UIViewController {
    
    @IBOutlet var welcomeLabel: UILabel!
    @IBOutlet var signUpButton: MyButton!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var repeatPasswordTextField: UITextField!
    private let gradientLoadingBar = GradientLoadingBar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gradientLoadingBar.gradientColors = [UIColor.getAppColor(.light), UIColor.getAppColor(.dark), UIColor.getAppColor(.light), UIColor.getAppColor(.dark)]
        welcomeLabel.textColor = UIColor.getAppColor(.dark)
        signUpButton.backgroundColor = UIColor.getAppColor(.light)
    }
    
    override func viewDidLayoutSubviews() {
        emailTextField.addBottomBorder()
        passwordTextField.addBottomBorder()
        repeatPasswordTextField.addBottomBorder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        passwordTextField.text = ""
        repeatPasswordTextField.text = ""
        navigationController?.isNavigationBarHidden = false
    }
    
    // MARK: IBActions
    
    @IBAction func loginPressed(_ sender: Any) {
        if emailTextField.text != "", passwordTextField.text != "" {
            loginUser()
        } else {
            // ProgressHUD.showError("Email/Password is missing")
            showMessage(kEMPTYFIELDS, type: .error)
        }
    }
    
    @IBAction func registerPressed(_ sender: Any) {
        if emailTextField.text != "", passwordTextField.text != "", repeatPasswordTextField.text != "" {
            if passwordTextField.text == repeatPasswordTextField.text! {
                if passwordTextField.text!.count < 6 {
                    showMessage(kPASSWORDLENGTH6CHARS, type: .error)
                    return
                }
                
                if !isValidEmail(emailStr: (emailTextField.text!).trimmingCharacters(in: .whitespacesAndNewlines)) {
                    showMessage(kEMAILNOTVALID, type: .error)
                    return
                }
                ProgressHUD.show()
                Auth.auth().fetchSignInMethods(forEmail: emailTextField.text!) { providers, error in
                    
                    if error != nil {
                        self.showMessage(kSOMETHINGWENTWRONG, type: .error)
                        return
                    }
                    
                    if providers != nil {
                        self.showMessage(kEMAILALREADYINUSE, type: .error)
                        
                    } else {
                        ProgressHUD.dismiss()
                        self.registerUser()
                        self.clearTextFields()
                    }
                }
                
            } else {
                showMessage(kPASSWORDSDONTMATCH, type: .error)
            }
        } else {
            showMessage(kEMPTYFIELDS, type: .error)
        }
    }
    
    @IBAction func signUpPressed(_ sender: Any) {
        if emailTextField.text != "", passwordTextField.text != "", repeatPasswordTextField.text != "" {
            if passwordTextField.text == repeatPasswordTextField.text! {
                if passwordTextField.text!.count < 6 {
                    showMessage(kPASSWORDLENGTH6CHARS, type: .error)
                    return
                }
                
                if !isValidEmail(emailStr: (emailTextField.text!).trimmingCharacters(in: .whitespacesAndNewlines)) {
                    showMessage(kEMAILNOTVALID, type: .error)
                    return
                }
                // ProgressHUD.show()
                gradientLoadingBar.fadeIn()
                Auth.auth().fetchSignInMethods(forEmail: emailTextField.text!) { providers, error in
                    
                    if error != nil {
                        self.gradientLoadingBar.fadeOut()
                        self.showMessage(kSOMETHINGWENTWRONG, type: .error)
                        return
                    }
                    
                    if providers != nil {
                        self.gradientLoadingBar.fadeOut()
                        self.showMessage(kEMAILALREADYINUSE, type: .error)
                        
                    } else {
                        self.gradientLoadingBar.fadeOut()
                        self.registerUser()
                        // self.clearTextFields()
                    }
                }
                
            } else {
                showMessage(kPASSWORDSDONTMATCH, type: .error)
            }
        } else {
            showMessage(kEMPTYFIELDS, type: .error)
        }
    }
    
    func isValidEmail(emailStr: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: emailStr)
    }
    
    @IBAction func backgroundTapped(_ sender: Any) {
        dismissKeyboard()
    }
    
    // MARK: HelperFunctions
    
    func loginUser() {
        gradientLoadingBar.fadeIn()
        FUser.loginUserWith(email: emailTextField.text!, password: passwordTextField.text!) { error in
            
            if error != nil {
                // ProgressHUD.showError(error!.localizedDescription)
                self.showMessage(kSOMETHINGWENTWRONG, type: .error)
            } else {
                self.goToApp()
                self.gradientLoadingBar.fadeOut()
            }
        }
    }
    
    func registerUser() {
        performSegue(withIdentifier: "goToFinishRegistration", sender: self)
        
        // clearTextFields()
//        passwordTextField.text = ""
//        repeatPasswordTextField.text = ""
        dismissKeyboard()
    }
    
    func dismissKeyboard() {
        view.endEditing(false)
    }
    
    func clearTextFields() {
        emailTextField.text = ""
        passwordTextField.text = ""
        repeatPasswordTextField.text = ""
    }
    
    // MARK: GoToApp
    
    func goToApp() {
        clearTextFields()
        dismissKeyboard()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID: FUser.currentId()])
        
        let mainView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "mainApplication") as! UITabBarController
        
        present(mainView, animated: true, completion: nil)
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToFinishRegistration" {
            let navController = segue.destination as! UINavigationController
            let destinationViewController = navController.viewControllers.first as! FinishRegistrationTableViewController
            destinationViewController.email = (emailTextField.text!).trimmingCharacters(in: .whitespacesAndNewlines)
            destinationViewController.password = passwordTextField.text!
        }
    }
}
