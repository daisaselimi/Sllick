//
//  EditProfileTableViewController.swift
//  Sllick
//
//  Created by Isa  Selimi on 5.11.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import FlagPhoneNumber
import ProgressHUD
import UIKit

class EditProfileTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, FPNTextFieldDelegate {
    
    var phoneNumber: String = ""
    var countryCode: String = ""
    
    @IBOutlet var saveButtonOutlet: UIBarButtonItem!
    @IBOutlet var avatarImageView: UIImageView!
    @IBOutlet var firstNameTextField: UITextField!
    @IBOutlet var lastNameTextField: UITextField!
    @IBOutlet var avagtarTapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet var phoneNumberTextFld: FPNTextField!
    var viewTapGestureRecognizer = UITapGestureRecognizer()
    
    func fpnDidSelectCountry(name: String, dialCode: String, code: String) {}
    
    func fpnDidValidatePhoneNumber(textField: FPNTextField, isValid: Bool) {
        if isValid {
            phoneNumber = textField.getFormattedPhoneNumber(format: .International)!
            phoneNumberTextFld.tintColor = .green
            
        } else {
            phoneNumber = "Not Valid"
            phoneNumberTextFld.tintColor = .red
        }
    }
    
    func fpnDisplayCountryList() {
        let listController: FPNCountryListViewController = FPNCountryListViewController(style: .insetGrouped)
        let navigationViewControllerx = UINavigationController(rootViewController: listController)
        navigationViewControllerx.navigationBar.tintColor = UIColor.getAppColor(.light)
        phoneNumberTextFld.flagButtonSize = CGSize(width: 25, height: 25)
        listController.title = "Countries"
        listController.setup(repository: phoneNumberTextFld.countryRepository)
        listController.didSelect = { [weak self] country in
            self?.phoneNumberTextFld.setFlag(countryCode: country.code)
            self?.countryCode = country.code.rawValue
        }
        present(navigationViewControllerx, animated: true, completion: nil)
    }
    
    var avatarImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 124, bottom: 0, right: 0)
        tableView.backgroundColor = UIColor(named: "bwBackground")
        viewTapGestureRecognizer.addTarget(self, action: #selector(viewTap))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(viewTapGestureRecognizer)
        phoneNumberTextFld.displayMode = .list
        
        phoneNumberTextFld.delegate = self
        phoneNumber = FUser.currentUser()!.phoneNumber
        navigationItem.largeTitleDisplayMode = .never
        tableView.tableFooterView = UIView()
        
        setupUI()
    }
    
    @objc func viewTap() {
        view.endEditing(false)
    }
    
    //    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    //        return ""
    //    }
    //
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor(named: "secondaryBwBackground")
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 2
        case 2: return 1
        default:
            return 0
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    @IBAction func avatarTapped(_ sender: Any) {
        showAlert()
    }
    
    @IBAction func changeProfilePicturePressed(_ sender: Any) {
        showAlert()
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        if !firstNameTextField.text!.isEmptyWithSpaces(), !lastNameTextField.text!.isEmptyWithSpaces(), !phoneNumberTextFld.text!.isEmptyWithSpaces() {
            if phoneNumber == "Not Valid" {
                showMessage("Phone number is not valid", type: .error)
                return
            }
            ProgressHUD.show("Saving...")
            
            // block save button
            saveButtonOutlet.isEnabled = false
            
            var fullName = firstNameTextField.text! + " " + lastNameTextField.text!
            fullName = fullName.removeExtraSpaces()
            
            var withValues = [kFIRSTNAME: firstNameTextField.text!.removeExtraSpaces(), kLASTNAME: lastNameTextField.text!.removeExtraSpaces(), kFULLNAME: fullName, kPHONE: phoneNumber, kCOUNTRYCODE: countryCode]
            
            var avatarData: Data?
            if avatarImage == nil {
                avatarData = nil
                
            } else {
                avatarData = avatarImage!.jpegData(compressionQuality: 0.5)
            }
            
            let avatarString = avatarData?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
            
            withValues[kAVATAR] = avatarString
            
            updateCurrentUserInFirestore(withValues: withValues) { error in
                
                if error != nil {
                    DispatchQueue.main.async {
                        // ProgressHUD.showError(error!.localizedDescription)
                        self.showMessage("Could not update profile", type: .error)
                        print("could not update user \(error!.localizedDescription)")
                        ProgressHUD.dismiss()
                    }
                    return
                }
                
                ProgressHUD.showSuccess("Saved")
                self.saveButtonOutlet.isEnabled = true
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdatedProfilePicture"), object: self, userInfo: ["picture": self.avatarImage ?? UIImage(named: "avatarph")!]) // post notification to view controller
                self.navigationController?.popViewController(animated: true)
                
                let withUserFullName = self.firstNameTextField.text! + " " + self.lastNameTextField.text!
                let withValuesForRecent = [kAVATAR: avatarString, kWITHUSERFULLNAME: withUserFullName]
                updateRecent(thatContainsID: FUser.currentId(), withValues: withValuesForRecent)
                
                let keywords = Array(createKeywords(word: fullName.lowercased().removeExtraSpaces()))
                
                reference(.UserKeywords).whereField("userId", isEqualTo: FUser.currentUser()!.objectId).getDocuments { snapshot, _ in
                    
                    guard let snapshot = snapshot else { return }
                    
                    if !snapshot.isEmpty {
                        snapshot.documents.first!.reference.updateData(["keywords": keywords])
                    }
                }
            }
            
        } else {
            showMessage(kEMPTYFIELDS, type: .error)
        }
    }
    
    // MARK: SetupUI
    
    func setupUI() {
        let currentUser = FUser.currentUser()!
        
        avatarImageView.isUserInteractionEnabled = true
        
        firstNameTextField.text = currentUser.firstname
        lastNameTextField.text = currentUser.lastname
        phoneNumberTextFld.text = currentUser.phoneNumber
        print(currentUser.phoneNumber.removingWhitespaces())
        phoneNumberTextFld.setFlag(countryCode: FPNCountryCode(rawValue: currentUser.countryCode)!)
        let countryCode = currentUser.phoneNumber.components(separatedBy: " ").first!
        self.phoneNumber = currentUser.phoneNumber
        self.countryCode = currentUser.countryCode
        phoneNumberTextFld.tintColor = .green
        let phoneNumber = currentUser.phoneNumber.components(separatedBy: " ").filter { $0 != countryCode }
        phoneNumberTextFld.text = phoneNumber.joined(separator: " ")
        
        // phoneNumberTextFld.set(phoneNumber: phoneNumber.joined())
        
        if currentUser.avatar != "" {
            imageFromData(pictureData: currentUser.avatar) { avatarImage in
                
                if avatarImage != nil {
                    self.avatarImage = avatarImage
                    self.avatarImageView.image = avatarImage
                }
            }
        } else {
            avatarImageView.image = UIImage(named: "avatarph")
        }
        avatarImageView.maskCircle()
    }
    
    //    //MARK: ImagePickerDelegate
    //
    //    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
    //        self.dismiss(animated: true, completion: nil)
    //    }
    //
    //    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
    //        if images.count > 0 {
    //            self.avatarImage = images.first!
    //            self.avatarImageView.image = self.avatarImage?.circleMasked
    //        }
    //        self.dismiss(animated: true, completion: nil)
    //    }
    //
    //    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
    //        self.dismiss(animated: true, completion: nil)
    //    }
    //
    //
    
    // MARK: UIImagePickerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let selectedImage = info[.editedImage] as? UIImage else {
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
            alert.view.superview?.isUserInteractionEnabled = true
            alert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.dismissOnTapOutside)))
        })
    }
    
    @objc func dismissOnTapOutside() {
        dismiss(animated: true, completion: nil)
    }
    
    func getImage(fromSourceType sourceType: UIImagePickerController.SourceType) {
        // Check is source type available
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.allowsEditing = true
            imagePickerController.sourceType = sourceType
            present(imagePickerController, animated: true, completion: nil)
        }
    }
}
