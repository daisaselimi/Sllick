//
//  FinishRegistrationViewController.swift
//  Sllick
//
//  Created by Isa  Selimi on 17.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import Firebase
import FlagPhoneNumber
import GradientLoadingBar
import ImagePicker
import OneSignal
import ProgressHUD
import UIKit

class FinishRegistrationViewController: UIViewController, ImagePickerDelegate, FPNTextFieldDelegate {
    
    var email: String!
    var password: String!
    var avatarImage: UIImage?
    var viewTapGestureRecognizer = UITapGestureRecognizer()
    private let gradientLoadingBar = GradientLoadingBar()
    
    @IBOutlet var avatarImageView: UIImageView!
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var surnameTextField: UITextField!
    @IBOutlet var countryTextField: UITextField!
    @IBOutlet var cityTextField: UITextField!
    @IBOutlet var phoneTextField: FPNTextField!
    
    @IBOutlet var topView: UIView!
    
    var phoneNumber: String = ""
    var countryCode: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewTapGestureRecognizer.addTarget(self, action: #selector(viewTap))
        overrideUserInterfaceStyle = .light
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        gradientLoadingBar.gradientColors = [UIColor.getAppColor(.light), UIColor.getAppColor(.dark), UIColor.getAppColor(.light), UIColor.getAppColor(.dark)]
        view.isUserInteractionEnabled = true
//      topView.addBottomBorderWithColor(color: .opaqueSeparator, width: 0.5)
        view.addGestureRecognizer(viewTapGestureRecognizer)
        avatarImageView.maskCircle()
        avatarImageView.isUserInteractionEnabled = true
        phoneTextField.displayMode = .list
        phoneTextField.delegate = self
        countryCode = (phoneTextField.selectedCountry?.code)!.rawValue
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
        present(navigationViewController, animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        topView.addBottomBorderWithColor(color: .opaqueSeparator, width: 0.5)
    }
    
    // MARK: IBActions
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        clearTextFields()
        dismissKeyboard()
        dismiss(animated: true, completion: nil)
    }
    
    @objc func viewTap() {
        dismissKeyboard()
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        dismissKeyboard()
        gradientLoadingBar.fadeIn()
        
        if allFieldsAreFilled() {
            if phoneNumber == "Not Valid" {
                gradientLoadingBar.fadeOut()
                showMessage(kPHONENUMBERNOTVALID, type: .error)
                return
            }
            FUser.registerUserWith(email: email, password: password, firstName: nameTextField.text!, lastName: surnameTextField.text!) { error in
                
                if error != nil {
                    self.gradientLoadingBar.fadeOut()
                    ProgressHUD.dismiss()
                    if let errCode = AuthErrorCode(rawValue: error!._code) {
                        switch errCode {
                        case .emailAlreadyInUse: self.showMessage(kEMAILALREADYINUSE, type: .error)
                        case .invalidEmail: self.showMessage(kEMAILNOTVALID, type: .error)
                        default: self.showMessage(kSOMETHINGWENTWRONG, type: .error)
                        }
                    }
                }
                else {
                    self.gradientLoadingBar.fadeOut()
                    self.registerUser()
                }
            }
        }
        else {
            gradientLoadingBar.fadeOut()
            showMessage(kEMPTYFIELDS, type: .error)
        }
    }
    
    func registerUser() {
        let fullName = nameTextField.text! + " " + surnameTextField.text!
        
        var tempDictionary: Dictionary = [
            kFIRSTNAME: nameTextField.text!, kLASTNAME: surnameTextField.text!,
            kFULLNAME: fullName, kCOUNTRY: countryTextField.text!, kCITY: cityTextField.text!,
            kPHONE: phoneNumber, kCOUNTRYCODE: countryCode,
        ] as [String: Any]
        
        if avatarImage == nil {
            tempDictionary[kAVATAR] = ""
        }
        else {
            let avatarIMG = avatarImage?.jpegData(compressionQuality: 0.7)
            let avatar = avatarIMG?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            tempDictionary[kAVATAR] = avatar
        }
        
        // finishRegistration
        finishRegistration(withValues: tempDictionary)
    }
    
    func finishRegistration(withValues: [String: Any]) {
        updateCurrentUserInFirestore(withValues: withValues) { error in
            
            if error != nil {
                self.showMessage(kSOMETHINGWENTWRONG, type: .error)
                
                return
            }
            self.goToApp()
            print(FUser.currentUser()!.fullname.lowercased())
            let keywords = Array(createKeywords(word: FUser.currentUser()!.fullname.lowercased()))
            reference(.UserKeywords).addDocument(data: ["userId": FUser.currentUser()!.objectId, "keywords": keywords])
            ProgressHUD.dismiss()
        }
    }
    
    func goToApp() {
        clearTextFields()
        dismissKeyboard()
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID: FUser.currentId()])
        customizeNavigationBar(colorName: "bwBackground")
        let mainView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "mainApplication") as! UITabBarController
        let scene = UIApplication.shared.connectedScenes.first
        if let sd: SceneDelegate = (scene?.delegate as? SceneDelegate) {
            OneSignal.sendTag("userId", value: FUser.currentId())
            sd.setRootViewController(mainView)
            sd.window!.makeKeyAndVisible()
        }
    }
    
    func allFieldsAreFilled() -> Bool {
        return nameTextField.text != "" &&
            surnameTextField.text != "" &&
            countryTextField.text != "" &&
            cityTextField.text != "" &&
            phoneTextField.text != ""
    }
    
    func dismissKeyboard() {
        view.endEditing(false)
    }
    
    func clearTextFields() {
        nameTextField.text = ""
        surnameTextField.text = ""
        countryTextField.text = ""
        cityTextField.text = ""
        phoneTextField.text = ""
    }
    
    // MARK: ImagePickerDelegate
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        dismiss(animated: true, completion: nil)
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        if images.count > 0 {
            avatarImage = images.first!
            avatarImageView.image = avatarImage
            avatarImageView.maskCircle()
        }
        dismiss(animated: true, completion: nil)
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func avatarTapp(_ sender: Any) {
        let imagePickerController = ImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.imageLimit = 1
        
        present(imagePickerController, animated: true, completion: nil)
        dismissKeyboard()
    }
    
    // MARK: FlagPhoneNumber delegate
    
    func fpnDidSelectCountry(name: String, dialCode: String, code: String) {}
    
    func fpnDidValidatePhoneNumber(textField: FPNTextField, isValid: Bool) {
        if isValid {
            phoneNumber = textField.getFormattedPhoneNumber(format: .International)!
            phoneTextField.tintColor = .green
        }
        else {
            phoneNumber = "Not Valid"
            phoneTextField.tintColor = .red
        }
    }
}
