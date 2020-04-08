//
//  FinishRegistrationViewController.swift
//  xChat
//
//  Created by Isa  Selimi on 17.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import UIKit
import ProgressHUD
import ImagePicker
import FlagPhoneNumber

class FinishRegistrationViewController: UIViewController, ImagePickerDelegate, FPNTextFieldDelegate  {
    
    

    var email: String!
    var password: String!
    var avatarImage: UIImage?
    var viewTapGestureRecognizer = UITapGestureRecognizer()
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var surnameTextField: UITextField!
    @IBOutlet weak var countryTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var phoneTextField: FPNTextField!
    
    @IBOutlet weak var topView: UIView!
    
    var phoneNumber: String = ""
    var countryCode: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewTapGestureRecognizer.addTarget(self, action: #selector(viewTap))
        view.isUserInteractionEnabled = true
        topView.addBottomBorderWithColor(color: .opaqueSeparator, width: 0.5)
        self.view.addGestureRecognizer(viewTapGestureRecognizer)
        avatarImageView.maskCircle()
        avatarImageView.isUserInteractionEnabled = true
        phoneTextField.displayMode = .list
        phoneTextField.delegate = self
       // phoneTextField.setCountries(including: [.KS])
        print(email!, password!)
    }
    
    func fpnDisplayCountryList() {
        let listController: FPNCountryListViewController = FPNCountryListViewController(style: .insetGrouped)
       let navigationViewController = UINavigationController(rootViewController: listController)

       listController.title = "Countries"
        listController.setup(repository: phoneTextField.countryRepository)
        listController.didSelect = { [weak self] country in
            self?.phoneTextField.setFlag(countryCode: country.code)
            self?.countryCode = country.code.rawValue
        }
            self.present(navigationViewController, animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        
        topView.addBottomBorderWithColor(color: .opaqueSeparator, width: 0.5)
    }
    
    //MARK: IBActions
    @IBAction func cancelButtonPressed(_ sender: Any) {
        clearTextFields()
        dismissKeyboard()
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func viewTap() {
        dismissKeyboard()
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        dismissKeyboard()
        ProgressHUD.show("Registering...")
        
        if allFieldsAreFilled() {
            
            if phoneNumber == "Not Valid" {
                ProgressHUD.showError("Phone number is not valid")
                return
            }
            FUser.registerUserWith(email: email, password: password, firstName: nameTextField.text!, lastName: surnameTextField.text!) { (error) in
                
                if error != nil {
                    ProgressHUD.dismiss()
                    ProgressHUD.showError(error!.localizedDescription)
                }
                else {
                    self.registerUser()
                }
            }
        }
        else {
            ProgressHUD.showError("All fields are required")
        }
        
    }
    
    func registerUser() {
        
        let fullName = nameTextField.text! + " " + surnameTextField.text!
        
        var tempDictionary: Dictionary = [
            kFIRSTNAME : nameTextField.text!, kLASTNAME : surnameTextField.text!,
            kFULLNAME : fullName, kCOUNTRY : countryTextField.text!, kCITY : cityTextField.text!,
            kPHONE : phoneNumber, kCOUNTRYCODE : countryCode] as [String : Any]
        
        if avatarImage == nil {
                
                tempDictionary[kAVATAR] = ""
        }
        else {
            let avatarIMG = avatarImage?.jpegData(compressionQuality: 0.7)
            let avatar = avatarIMG?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            tempDictionary[kAVATAR] = avatar
        }
        
        //finishRegistration
        self.finishRegistration(withValues: tempDictionary)
    }
    
    func finishRegistration(withValues: [String : Any]) {
        
        updateCurrentUserInFirestore(withValues: withValues) { (error) in
            
            if error != nil {
                ProgressHUD.showError(error!.localizedDescription)
                
                return
            }
            self.goToApp()
            print(FUser.currentUser()!.fullname.lowercased())
            let keywords = Array(createKeywords(word: FUser.currentUser()!.fullname.lowercased()))
            reference(.UserKeywords).addDocument(data: ["userId" : FUser.currentUser()!.objectId, "keywords" : keywords])
            ProgressHUD.dismiss()
        }
    }
    
    func goToApp() {
        
        clearTextFields()
        dismissKeyboard()
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo:  [kUSERID : FUser.currentId()])
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "mainApplication") as! UITabBarController
        
        self.present(mainView, animated: true, completion: nil)
    }
    
    func allFieldsAreFilled() -> Bool {
        return nameTextField.text != "" &&
            surnameTextField.text != "" &&
            countryTextField.text != "" &&
            cityTextField.text != "" &&
            phoneTextField.text != ""
    }
   
    
    func dismissKeyboard() {
        self.view.endEditing(false)
    }
    
    func clearTextFields() {
        nameTextField.text = ""
        surnameTextField.text = ""
        countryTextField.text = ""
        cityTextField.text = ""
        phoneTextField.text = ""
    }
    
    //MARK: ImagePickerDelegate
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        if images.count > 0 {
            self.avatarImage = images.first!
            self.avatarImageView.image = self.avatarImage
            self.avatarImageView.maskCircle()
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
         self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func avatarTapp(_ sender: Any) {
        let imagePickerController = ImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.imageLimit = 1
        
        present(imagePickerController, animated: true, completion: nil)
        dismissKeyboard()
    }
    
    //MARK: FlagPhoneNumber delegate
    
    func fpnDidSelectCountry(name: String, dialCode: String, code: String) {
    }
    
    func fpnDidValidatePhoneNumber(textField: FPNTextField, isValid: Bool) {
        if isValid {
            phoneNumber = textField.getFormattedPhoneNumber(format: .International)!
            phoneTextField.tintColor = .green
            
        } else {
            phoneNumber = "Not Valid"
            phoneTextField.tintColor = .red
        }
    }
    
}
