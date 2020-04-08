//
//  WelcomeViewController.swift
//  xChat
//
//  Created by Isa  Selimi on 15.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import UIKit
import ProgressHUD
import FirebaseAuth

class WelcomeViewController: UIViewController {

    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var signUpButton: MyButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var repeatPasswordTextField: UITextField!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        welcomeLabel.textColor = UIColor.getAppColor(.dark)
        signUpButton.backgroundColor = UIColor.getAppColor(.light)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    override func viewDidLayoutSubviews() {
        emailTextField.addBottomBorder()
        passwordTextField.addBottomBorder()
        repeatPasswordTextField.addBottomBorder()
    }
    
  
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
    //MARK: IBActions
    @IBAction func loginPressed(_ sender: Any) {
       
        if emailTextField.text != "" && passwordTextField.text != "" {
            loginUser()
        }
        else {
            ProgressHUD.showError("Email/Password is missing")
        }
    }
    
    @IBAction func registerPressed(_ sender: Any) {
        
        if emailTextField.text != "" && passwordTextField.text != "" && repeatPasswordTextField.text != "" {
            
      
            if passwordTextField.text == repeatPasswordTextField.text! {
                if passwordTextField.text!.count < 6 {
                    ProgressHUD.showError("Password should contain at least 6 characters")
                    return
                }
                
                if !isValidEmail(emailStr: (emailTextField.text!).trimmingCharacters(in: .whitespacesAndNewlines)) {
                    ProgressHUD.showError("Email is not valid")
                    return
                }
                ProgressHUD.show()
                Auth.auth().fetchSignInMethods(forEmail: emailTextField.text!) { (providers, error) in
                
                    if error != nil {
                        ProgressHUD.showError("Something went wrong!")
                        return
                    }
                    
                    if providers != nil {
                        ProgressHUD.showError("Email already in use")
            
                    } else {
                        ProgressHUD.dismiss()
                        self.registerUser()
                        self.clearTextFields()
                    }
                }
                
                
            } else {
                ProgressHUD.showError("Passwords don't match")
            }
        }
        else {
             ProgressHUD.showError("All fields are required")
        }
        
    }
    
    @IBAction func signUpPressed(_ sender: Any) {
        if emailTextField.text != "" && passwordTextField.text != "" && repeatPasswordTextField.text != "" {
               
         
               if passwordTextField.text == repeatPasswordTextField.text! {
                   if passwordTextField.text!.count < 6 {
                       ProgressHUD.showError("Password should contain at least 6 characters")
                       return
                   }
                   
                   if !isValidEmail(emailStr: (emailTextField.text!).trimmingCharacters(in: .whitespacesAndNewlines)) {
                       ProgressHUD.showError("Email is not valid")
                       return
                   }
                   ProgressHUD.show()
                   Auth.auth().fetchSignInMethods(forEmail: emailTextField.text!) { (providers, error) in
                   
                       if error != nil {
                           ProgressHUD.showError("Something went wrong!")
                           return
                       }
                       
                       if providers != nil {
                           ProgressHUD.showError("Email already in use")
               
                       } else {
                           ProgressHUD.dismiss()
                           self.registerUser()
                           self.clearTextFields()
                       }
                   }
                   
                   
               } else {
                   ProgressHUD.showError("Passwords don't match")
               }
           }
           else {
                ProgressHUD.showError("All fields are required")
           }
           
        
    }
    
    func isValidEmail(emailStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: emailStr)
    }
    
    @IBAction func backgroundTapped(_ sender: Any) {
        dismissKeyboard()
    }
    
    
    //MARK: HelperFunctions
    
    func loginUser() {
        ProgressHUD.show()
        FUser.loginUserWith(email: emailTextField.text!, password: passwordTextField.text!) { (error) in
            
            if error != nil {
                ProgressHUD.showError(error!.localizedDescription)
                return
            }
            else {
                self.goToApp()
                ProgressHUD.dismiss()
            }
        }
    }
    
    func registerUser() {
        performSegue(withIdentifier: "goToFinishRegistration", sender: self)
         
        clearTextFields()
        dismissKeyboard()
    }
    
    func dismissKeyboard() {
        self.view.endEditing(false)
    }
    
    func clearTextFields() {
        emailTextField.text = ""
        passwordTextField.text = ""
        repeatPasswordTextField.text = ""
    }
    
    //MARK: GoToApp
    func goToApp() {
        clearTextFields()
        dismissKeyboard()
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "mainApplication") as! UITabBarController
        
        self.present(mainView, animated: true, completion: nil)
    }
    
    //MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "goToFinishRegistration" {
            let destinationViewController = segue.destination as! FinishRegistrationViewController
            destinationViewController.email = (emailTextField.text!).trimmingCharacters(in: .whitespacesAndNewlines)
            destinationViewController.password = passwordTextField.text!        }
    }
    
}
