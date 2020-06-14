import Firebase
import FlagPhoneNumber
import GradientLoadingBar
import ImagePicker
import ProgressHUD
import UIKit

class FinishRegistrationTableViewController: UITableViewController, ImagePickerDelegate, FPNTextFieldDelegate {
    
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
    
    var phoneNumber: String = ""
    var countryCode: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gradientLoadingBar.gradientColors = [.systemGray, .systemGray2, .systemGray3, .systemGray4, .systemGray5, .systemGray6]
        phoneTextField.attributedPlaceholder = NSAttributedString(string: phoneTextField.placeholder ?? "",
                                                                  attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        phoneTextField.textColor = .white
        viewTapGestureRecognizer.addTarget(self, action: #selector(viewTap))
        
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 107, bottom: 0, right: 0)
        view.isUserInteractionEnabled = true
        //      topView.addBottomBorderWithColor(color: .opaqueSeparator, width: 0.5)
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
        let navigationViewController = UINavigationController(rootViewController: listController)
        
        listController.title = "Countries"
        listController.setup(repository: phoneTextField.countryRepository)
        listController.didSelect = { [weak self] country in
            self?.phoneTextField.setFlag(countryCode: country.code)
            self?.countryCode = country.code.rawValue
        }
        present(navigationViewController, animated: true, completion: nil)
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
        
        if allFieldsAreFilled() {
            if phoneNumber == "Not Valid" {
                gradientLoadingBar.fadeOut()
                showMessage("Phone number is not valid", type: .error)
                return
            }
            FUser.registerUserWith(email: email, password: password, firstName: nameTextField.text!, lastName: surnameTextField.text!) { error in
                
                if error != nil {
                    self.gradientLoadingBar.fadeOut()
                    ProgressHUD.dismiss()
                    if let errCode = AuthErrorCode(rawValue: error!._code) {
                        switch errCode {
                        case .emailAlreadyInUse: self.showMessage("Email already in use", type: .error)
                        case .invalidEmail: self.showMessage("Invalid email", type: .error)
                        default: self.showMessage("An error occurred", type: .error)
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
            showMessage("All fields are required", type: .error)
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
    
    @IBAction func choosePicturePressed(_ sender: Any) {
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
