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
import OneSignal
import ProgressHUD
import UIKit

class FinishRegistrationViewController: UIViewController, FPNTextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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
    
//    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
//        dismiss(animated: true, completion: nil)
//    }
//
//    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
//        if images.count > 0 {
//            avatarImage = images.first!
//            avatarImageView.image = avatarImage
//            avatarImageView.maskCircle()
//        }
//        dismiss(animated: true, completion: nil)
//    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                                  didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
           guard let selectedImage = info[.originalImage] as? UIImage else {
               fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
           }
           let chosenImage = selectedImage.resizeTo(MB: 1) // 2
           avatarImage = chosenImage // 4
           //        let screenWidth = UIScreen.main.bounds
           //        print("*** * * * * * * * * *                  * **** ** **---------- * * * * ** * *:::::::::: \(screenWidth.size.width)")
           //        avatarImage = resizeImage(image: avatarImage!, targetSize: CGSize(width: screenWidth.size.width, height: screenWidth.size.width))
           avatarImageView.image = avatarImage!
           avatarImageView.maskCircle()
           
           dismiss(animated: true, completion: nil) // 5
       }
       
       func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
           picker.dismiss(animated: true, completion: nil)
       }
    
    
    @IBAction func avatarTapp(_ sender: Any) {
       showAlert()
    }
    
    func showAlert() {
        let alert = UIAlertController(title: nil, message: "Change profile photo", preferredStyle: .actionSheet)
        if !(avatarImage == nil) {
            let resetAction = UIAlertAction(title: "Remove Current Photo", style: .destructive) { _ in
                
                self.avatarImage = nil
                self.avatarImageView.image = UIImage(named: "avatarph")
            }
            alert.addAction(resetAction)
        }
        
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { (_: UIAlertAction) in
            self.getImage(fromSourceType: .camera)
        }))
        alert.addAction(UIAlertAction(title: "Choose From Library", style: .default, handler: { (_: UIAlertAction) in
            self.getImage(fromSourceType: .photoLibrary)
        }))
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            _ in
            
        })
        alert.addAction(cancelAction)
        
        alert.preferredAction = cancelAction
        present(alert, animated: true, completion: {
//            alert.view.superview?.isUserInteractionEnabled = true
//            alert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.dismissOnTapOutside)))
        })
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
    
    func getImage(fromSourceType sourceType: UIImagePickerController.SourceType) {
           // Check is source type available
           if UIImagePickerController.isSourceTypeAvailable(sourceType) {
               let imagePickerController = UIImagePickerController()
               imagePickerController.delegate = self
               imagePickerController.allowsEditing = false
               imagePickerController.sourceType = sourceType
               present(imagePickerController, animated: true, completion: nil)
           }
       }
}
