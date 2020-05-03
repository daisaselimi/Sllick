//
//  LoginViewController.swift
//  Sllick
//
//  Created by Isa  Selimi on 15.11.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import UIKit
import ProgressHUD
import TextFieldEffects
import Firebase
import NVActivityIndicatorView
import FirebaseFirestore
import GradientLoadingBar
import OneSignal

class LoginViewController: UIViewController {

    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginLabel: UILabel!
    @IBOutlet weak var loginButton: MyButton!
    var viewTapGestureRecognizer = UITapGestureRecognizer()
    private let gradientLoadingBar = GradientLoadingBar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //To apply padding
        gradientLoadingBar.gradientColors =  [UIColor.getAppColor(.light), UIColor.getAppColor(.dark), UIColor.getAppColor(.light), UIColor.getAppColor(.dark)]
        loginLabel.textColor = UIColor.getAppColor(.light)
        loginButton.backgroundColor = UIColor.getAppColor(.light)
        let paddingView : UIView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: emailTextField.frame.height))
        emailTextField.leftView = paddingView
        emailTextField.layer.masksToBounds = false
        viewTapGestureRecognizer.addTarget(self, action: #selector(viewTap))
        self.view.addGestureRecognizer(viewTapGestureRecognizer)
 
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
            self.showMessage(kEMPTYFIELDS, type: .error)
             }
    }
    
    @IBAction func forgotPasswordButtonPressed(_ sender: Any) {
        
        self.showInputDialogWith(title: "Enter your email",
                                  subtitle: "You will recieve an email to reset your password",
                                  actionTitle: "Submit",
                                  cancelTitle: "Cancel",
                                  inputPlaceholder: "Email",
                                  inputInitialText: emailTextField.text,
                                  inputKeyboardType: .default)
                  { (input:String?) in

                    if input?.removeExtraSpaces() != "" {
                        Auth.auth().sendPasswordReset(withEmail: input!) { (error) in
                            if error == nil {
                                self.showMessage("Email with password resetting intructions has been sent. Please check your email.", type: .info, options: [.height(100), .textAlignment(.center), .textNumberOfLines(10)])
                                return
                            }

                                                   if let errorCode = AuthErrorCode(rawValue: error!._code) {
                                                       switch errorCode  {
                                                       case .invalidEmail: self.showMessage(kEMAILNOTVALID, type: .error)
                                                       case .userNotFound :self.showMessage(kUSERNOTFOUND, type: .error)
                                                       default: self.showMessage(kSOMETHINGWENTWRONG, type: .error)
                                                       }
                                                   }
                                           }
                    } else {
                        self.view.shake()
                    }

                  }
//
//
//        let alert = UIAlertController(title: "Enter your email", message: "You will receive an email to reset your password", preferredStyle: .alert)
//            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 270, height:18))
//            label.textAlignment = .center
//            label.textColor = .systemRed
//            label.font = label.font.withSize(12)
//            alert.view.addSubview(label)
//            label.isHidden = true
//            alert.addTextField { (textField:UITextField) in
//                textField.placeholder = "Enter email"
//                textField.keyboardType = .default
//                textField.text = self.emailTextField.text?.removeExtraSpaces() == "" ? "" : self.emailTextField.text?.removeExtraSpaces()
//
//            }
//
//
//            alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { (action:UIAlertAction) in
//                guard let textField =  alert.textFields?.first else {
//                    return
//                }
//                self.gradientLoadingBar.fadeIn()
//                if textField.text!.removeExtraSpaces() != "" {
//                    Auth.auth().sendPasswordReset(withEmail: textField.text!) { (error) in
//                        if error == nil {
//                             self.gradientLoadingBar.fadeOut()
//                            ProgressHUD.showSuccess("Email has been sent")
//                            return
//                        }
//
//                        if let errorCode = AuthErrorCode(rawValue: error!._code) {
//                            self.gradientLoadingBar.fadeOut()
//                            switch errorCode  {
//                            case .invalidEmail:
//                                label.text = "Invalid email"
//                                label.isHidden = false
//                                self.present(alert, animated: true, completion: nil)
//                            case .userNotFound :
//                                label.text = "Email doesn't exist"
//                                label.isHidden = false
//                                self.present(alert, animated: true, completion: nil)
//                            default:
//                                label.text = "An error occurred"
//                                label.isHidden = false
//                                self.present(alert, animated: true, completion: nil)
//                            }
//                        }
//                    }
//                } else {
//                     self.gradientLoadingBar.fadeOut()
//                     label.text = "Provide an email"
//                                                  label.isHidden = false
//                                                  self.present(alert, animated: true, completion: nil)
//                                 }
//            }))
//            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
//
//            self.present(alert, animated: true, completion: nil)
    }
    
    func showInputDialogWith(title:String? = nil,
                         subtitle:String? = nil,
                         actionTitle:String? = "Add",
                         cancelTitle:String? = "Cancel",
                         inputPlaceholder:String? = nil,
                         inputInitialText:String? = "",
                         inputKeyboardType:UIKeyboardType = UIKeyboardType.default,
                         cancelHandler: ((UIAlertAction) -> Swift.Void)? = nil,
                         actionHandler: ((_ text: String?) -> Void)? = nil) {

        let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
        let label = UILabel(frame: CGRect(x: 0, y: 40, width: 270, height:18))
        label.textAlignment = .center
        label.textColor = .systemRed
        label.font = label.font.withSize(12)
        alert.view.addSubview(label)
        label.isHidden = true
        alert.addTextField { (textField:UITextField) in
            textField.placeholder = inputPlaceholder
            textField.keyboardType = inputKeyboardType
            textField.text = inputInitialText
        }
        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { (action:UIAlertAction) in
            guard let textField =  alert.textFields?.first else {
                actionHandler?(nil)
                return
            }
            actionHandler?(textField.text)
        }))
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: cancelHandler))

        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func signInPressed(_ sender: Any) {
        if emailTextField.text != "" && passwordTextField.text != "" {
                   loginUser()
               }
               else {
                self.showMessage(kEMPTYFIELDS, type: .error)
               }
    }
    
    @objc func viewTap() {
        dismissKeyboard()
    }
    
    func loginUser() {
        self.gradientLoadingBar.fadeIn()
          FUser.loginUserWith(email: emailTextField.text!, password: passwordTextField.text!) { (error) in
            self.gradientLoadingBar.fadeOut()
              if error != nil {
                     if let errCode = AuthErrorCode(rawValue: error!._code) {
                        switch errCode {
                        case .invalidEmail: self.showMessage(kEMAILNOTVALID, type: .error)
                        case .userNotFound: self.showMessage(kUSERNOTFOUND, type: .error)
                        case .wrongPassword: self.showMessage(kWRONGPASSWORD, type: .error)
                        case .tooManyRequests: self.showMessage(kTOOMANYLOGINATTEMPTS, type: .error)
                        default: self.showMessage(kSOMETHINGWENTWRONG, type: .error)
                        }
                }
                 // ProgressHUD.showError(error!.localizedDescription)
                  //return
              }
              else {
                  self.goToApp()
                    
              }
          }
      }
    
    func goToApp() {
        clearTextFields()
        dismissKeyboard()
        customizeNavigationBar(colorName: "bwBackground")
             let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "mainApplication") as! UITabBarController
           let scene = UIApplication.shared.connectedScenes.first
                if let sd : SceneDelegate = (scene?.delegate as? SceneDelegate) {
                       OneSignal.sendTag("userId", value: FUser.currentId())
                           sd.setRootViewController(mainView)
                   sd.window!.makeKeyAndVisible()
                }
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
        bottomLine.frame = CGRect(x: 0.0, y: self.frame.height - 1, width: self.frame.width - 2, height: 0.7)
        bottomLine.backgroundColor = UIColor.lightGray.cgColor
        self.borderStyle = UITextField.BorderStyle.none
        
        //self.layer.masksToBounds = true
    }
}

extension UIViewController: NVActivityIndicatorViewable {
    func startAnimatingActivityIndicator() {
        let width = 50
        let height = 50
        let size = CGSize(width: width, height: height)
        startAnimating(size, type: NVActivityIndicatorType.ballClipRotateMultiple, color: .label)
    }

    func stopAnimatingActivityIndicator() {
        self.stopAnimating()
    }
}
