import Firebase
import FlagPhoneNumber
import GradientLoadingBar
import ProgressHUD
import UIKit

class FinishRegistrationTableViewController: UITableViewController, FPNTextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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
    @IBOutlet var doneButton: UIBarButtonItem!
    
    var phoneNumber: String = ""
    var countryCode: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gradientLoadingBar.gradientColors = [UIColor.getAppColor(.light), UIColor.getAppColor(.dark), UIColor.getAppColor(.light), UIColor.getAppColor(.dark)]
        
        phoneTextField.attributedPlaceholder = NSAttributedString(string: phoneTextField.placeholder ?? "",
                                                                  attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        // self.gradientLoadingBar.fadeIn()
        
        phoneTextField.textColor = .white
        viewTapGestureRecognizer.addTarget(self, action: #selector(viewTap))
        
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 107, bottom: 0, right: 0)
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(viewTapGestureRecognizer)
        phoneTextField.layer.borderWidth = 1.0
        phoneTextField.layer.borderColor = UIColor.clear.cgColor
        phoneTextField.backgroundColor = UIColor(named: "bcg")
        avatarImageView.maskCircle()
        avatarImageView.isUserInteractionEnabled = true
        phoneTextField.displayMode = .list
        phoneTextField.delegate = self
        countryCode = (phoneTextField.selectedCountry?.code)!.rawValue
        // phoneTextField.setCountries(including: [.KS])
        print(email!, password!)
    }
    
    override func viewWillLayoutSubviews() {}
    
    func fpnDisplayCountryList() {
        let listController: FPNCountryListViewController = FPNCountryListViewController(style: .insetGrouped)
        
        let navigationViewControllerx = UINavigationController(rootViewController: listController)
        navigationViewControllerx.navigationBar.tintColor = UIColor.getAppColor(.light)
        listController.title = "Countries"
        listController.searchController.searchBar.keyboardAppearance = .light
        listController.overrideUserInterfaceStyle = .light
        listController.setup(repository: phoneTextField.countryRepository)
        listController.didSelect = { [weak self] country in
            self?.phoneTextField.setFlag(countryCode: country.code)
            self?.countryCode = country.code.rawValue
        }
        present(navigationViewControllerx, animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        clearTextFields()
        dismissKeyboard()
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: IBAction
    
    @objc func viewTap() {
        dismissKeyboard()
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        dismissKeyboard()
        gradientLoadingBar.fadeIn()
        doneButton.title = "Signing up..."
        doneButton.isEnabled = false
        if allFieldsAreFilled() {
            if phoneNumber == "Not Valid" {
                gradientLoadingBar.fadeOut()
                showMessage(kPHONENUMBERNOTVALID, type: .error)
                doneButton.isEnabled = true
                doneButton.title = "Done"
                return
            }
            FUser.registerUserWith(email: email, password: password, firstName: nameTextField.text!.removeExtraSpaces(), lastName: surnameTextField.text!.removeExtraSpaces()) { error in
                
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
                    self.doneButton.isEnabled = true
                    self.doneButton.title = "Done"
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
            doneButton.isEnabled = true
            doneButton.title = "Done"
        }
    }
    
    func registerUser() {
        var fullName = nameTextField.text! + " " + surnameTextField.text!
        fullName = fullName.removeExtraSpaces()
        var tempDictionary: Dictionary = [
            kFIRSTNAME: nameTextField.text!.removeExtraSpaces(), kLASTNAME: surnameTextField.text!.removeExtraSpaces(),
            kFULLNAME: fullName, kCOUNTRY: countryTextField.text!.removeExtraSpaces(), kCITY: cityTextField.text!.removeExtraSpaces(),
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
            self.doneButton.isEnabled = true
            if error != nil {
                self.showMessage("An error occurred", type: .error)
                
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
            sd.setRootViewController(mainView)
            sd.window!.makeKeyAndVisible()
        }
    }
    
    func allFieldsAreFilled() -> Bool {
        return !nameTextField.text!.isEmptyWithSpaces() &&
            !surnameTextField.text!.isEmptyWithSpaces() &&
            !countryTextField.text!.isEmptyWithSpaces() &&
            !cityTextField.text!.isEmptyWithSpaces() &&
            !phoneTextField.text!.isEmptyWithSpaces()
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
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let selectedImage = info[.editedImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        let chosenImage = selectedImage.resizeTo(MB: 1) // 2
        avatarImage = chosenImage
        avatarImageView.image = avatarImage!
        avatarImageView.maskCircle()
        
        dismiss(animated: true, completion: nil) // 5
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func showAlert() {
        let alert = UIAlertController(title: nil, message: "Set your profile picture", preferredStyle: .actionSheet)
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
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func avatarTapp(_ sender: Any) {
        showAlert()
    }
    
    @IBAction func choosePicturePressed(_ sender: Any) {
        showAlert()
    }
    
    func getImage(fromSourceType sourceType: UIImagePickerController.SourceType) {
        // Check is source type available
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.allowsEditing = true
            imagePickerController.sourceType = sourceType
            imagePickerController.overrideUserInterfaceStyle = .light
            present(imagePickerController, animated: true, completion: nil)
        }
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
