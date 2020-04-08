//
//  LoginViewController.swift
//  xChat
//
//  Created by Isa  Selimi on 15.11.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import UIKit
import ProgressHUD
import TextFieldEffects
class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginLabel: UILabel!
    @IBOutlet weak var loginButton: MyButton!
    var viewTapGestureRecognizer = UITapGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //To apply padding
    
        loginLabel.textColor = UIColor.getAppColor(.light)
        loginButton.backgroundColor = UIColor.getAppColor(.light)
        let paddingView : UIView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: emailTextField.frame.height))
        emailTextField.leftView = paddingView
        emailTextField.layer.masksToBounds = false
        viewTapGestureRecognizer.addTarget(self, action: #selector(viewTap))
        self.view.addGestureRecognizer(viewTapGestureRecognizer)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        // Do any additional setup after loading the view.
    }
    
    
    override func viewDidLayoutSubviews() {
            emailTextField.addBottomBorder()
            passwordTextField.addBottomBorder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.navigationController?.isNavigationBarHidden = false
    }
    

    @IBAction func loginPressed(_ sender: Any) {
        if emailTextField.text != "" && passwordTextField.text != "" {
                 loginUser()
             }
             else {
                 ProgressHUD.showError("Email/Password is missing")
             }
    }
    
    
    @IBAction func signInPressed(_ sender: Any) {
        if emailTextField.text != "" && passwordTextField.text != "" {
                   loginUser()
               }
               else {
                   ProgressHUD.showError("Email/Password is missing")
               }
    }
    
    @objc func viewTap() {
        dismissKeyboard()
    }
    
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
    
    func goToApp() {
        clearTextFields()
        dismissKeyboard()
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "mainApplication") as! UITabBarController
        
        self.present(mainView, animated: true, completion: nil)
    }

    func dismissKeyboard() {
         self.view.endEditing(false)
     }
     
     func clearTextFields() {
         emailTextField.text = ""
         passwordTextField.text = ""
     }
}

extension UITextField {
    func addBottomBorder(){
        let bottomLine = CALayer()
        self.layer.addSublayer(bottomLine)
        bottomLine.frame = CGRect(x: 0.0, y: self.frame.height - 1, width: self.frame.width, height: 1.0)
        bottomLine.backgroundColor = UIColor.label.cgColor
        self.borderStyle = UITextField.BorderStyle.none
        
        //self.layer.masksToBounds = true
    }
}
