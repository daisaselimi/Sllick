//
//  HelperFunctions.swift
//  Sllick
//
//  Created by Isa  Selimi on 15.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import AVFoundation
import Contacts
import FirebaseFirestore
import Foundation
import UIKit

// MARK: GLOBAL FUNCTIONS

private let dateFormat = "yyyyMMddHHmmss"

func dateFormatter() -> DateFormatter {
    let dateFormatter = DateFormatter()
    
    dateFormatter.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
    
    dateFormatter.dateFormat = dateFormat
    
    return dateFormatter
}

func imageFromInitials(firstName: String?, lastName: String?, withBlock: @escaping (_ image: UIImage) -> Void) {
    var string: String!
    var size = 36
    
    if firstName != nil, lastName != nil {
        string = String(firstName!.first!).uppercased() + String(lastName!.first!).uppercased()
    } else {
        string = String(firstName!.first!).uppercased()
        size = 72
    }
    
    let lblNameInitialize = UILabel()
    lblNameInitialize.frame.size = CGSize(width: 100, height: 100)
    lblNameInitialize.textColor = .white
    lblNameInitialize.font = UIFont(name: lblNameInitialize.font.fontName, size: CGFloat(size))
    lblNameInitialize.text = string
    lblNameInitialize.textAlignment = NSTextAlignment.center
    lblNameInitialize.backgroundColor = #colorLiteral(red: 0.2962848195, green: 0.8613975254, blue: 0.8074396465, alpha: 1)
    lblNameInitialize.layer.cornerRadius = 25
    
    UIGraphicsBeginImageContext(lblNameInitialize.frame.size)
    lblNameInitialize.layer.render(in: UIGraphicsGetCurrentContext()!)
    
    let img = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    withBlock(img!)
}

func imageFromData(pictureData: String, withBlock: (_ image: UIImage?) -> Void) {
    var image: UIImage?
    
    let decodedData = NSData(base64Encoded: pictureData, options: NSData.Base64DecodingOptions(rawValue: 0))
    
    image = UIImage(data: decodedData! as Data)
    
    withBlock(image)
}

// func timeElapsed(date: Date) -> String {
//
//    let seconds = NSDate().timeIntervalSince(date)
//
//    var elapsed: String?
//
//
//    if (seconds < 60) {
//        elapsed = "Now"
//    } else if (seconds < 60 * 60) {
//        let minutes = Int(seconds / 60)
//
//        var minText = "min"
//        if minutes > 1 {
//            minText = "mins"
//        }
//        elapsed = "\(minutes) \(minText)"
//
//    } else if (seconds < 24 * 60 * 60) {
//        let hours = Int(seconds / (60 * 60))
//        var hourText = "hour"
//        if hours > 1 {
//            hourText = "hours"
//        }
//        elapsed = "\(hours) \(hourText)"
//    } else {
//        let currentDateFormater = dateFormatter()
//        currentDateFormater.dateFormat = "dd/MM/YYYY"
//
//        elapsed = "\(currentDateFormater.string(from: date))"
//    }
//
//    return elapsed!
// }

func timeElapsed(seconds: Int) -> String {
    var elapsed: String!
    
    if seconds < 60 {
        elapsed = "just now"
    } else if seconds < 60 * 60 {
        let minutes = Int(seconds / 60)
        
        let minText = "m"
        elapsed = "\(minutes)\(minText)"
        
    } else if seconds < 24 * 60 * 60 {
        let hours = Int(seconds / (60 * 60))
        let hourText = "h"
        elapsed = "\(hours)\(hourText)"
    } else {
        let currentDateFormater = dateFormatter()
        currentDateFormater.dateFormat = "dd/MM/YYYY"
        
        elapsed = "more than a day ago)"
    }
    
    return elapsed
}

func timeElapsed(date: Date) -> String {
    let seconds = NSDate().timeIntervalSince(date)
    
    var elapsed: String?
    
//
//    if (seconds < 60) {
//        elapsed = "Now"
//    } else if (seconds < 60 * 60) {
//        let minutes = Int(seconds / 60)
//
//        let minText = "m"
//        elapsed = "\(minutes)\(minText)"
//
//    } else if (seconds < 24 * 60 * 60) {
//        let hours = Int(seconds / (60 * 60))
//        let hourText = "h"
//        elapsed = "\(hours)\(hourText)"
//    } else {
//        let currentDateFormater = dateFormatter()
//        currentDateFormater.dateFormat = "dd/MM/YYYY"
//
//        elapsed = "\(currentDateFormater.string(from: date))"
//    }
    
    if seconds < 24 * 60 * 60 {
        let currentDateFormater = dateFormatter()
        currentDateFormater.dateFormat = "HH:mm"
        elapsed = "\(currentDateFormater.string(from: date))"
    } else if seconds < 24 * 60 * 60 * 7 {
        let currentDateFormater = dateFormatter()
        currentDateFormater.dateFormat = "E"
        elapsed = "\(currentDateFormater.string(from: date))"
    } else if seconds < 24 * 60 * 60 * 365 {
        let currentDateFormater = dateFormatter()
        currentDateFormater.dateFormat = "d MMM"
        elapsed = "\(currentDateFormater.string(from: date))"
    } else {
        let currentDateFormater = dateFormatter()
        currentDateFormater.dateFormat = "dd/MM/YYYY"
        
        elapsed = "\(currentDateFormater.string(from: date))"
    }
    
    return elapsed!
}

// for avatars
func dataImageFromString(pictureString: String, withBlock: (_ image: Data?) -> Void) {
    let imageData = NSData(base64Encoded: pictureString, options: NSData.Base64DecodingOptions(rawValue: 0))
    
    withBlock(imageData as Data?)
}

// for calls and chats
func dictionaryFromSnapshots(snapshots: [DocumentSnapshot]) -> [NSDictionary] {
    var allMessages: [NSDictionary] = []
//    for snapshot in snapshots{
//        allMessages.append(snapshot.data() as! NSDictionary)
//    }
    allMessages = snapshots.map { $0.data()! as NSDictionary }
    return allMessages
}

func dictionaryFromSnapshots(snapshots: [DocumentSnapshot], endIndex: Int) -> [NSDictionary] {
    var allMessages: [NSDictionary] = []
    for snapshot in snapshots.prefix(endIndex) {
        allMessages.append(snapshot.data() as! NSDictionary)
    }
    return allMessages
}

func formatCallTime(date: Date) -> String {
    let seconds = NSDate().timeIntervalSince(date)
    
    var elapsed: String?
    
    if seconds < 60 {
        elapsed = "Just now"
    } else if seconds < 24 * 60 * 60 {
        let currentDateFormater = dateFormatter()
        currentDateFormater.dateFormat = "HH:mm"
        
        elapsed = "\(currentDateFormater.string(from: date))"
    } else {
        let currentDateFormater = dateFormatter()
        currentDateFormater.dateFormat = "dd/MM/YYYY"
        
        elapsed = "\(currentDateFormater.string(from: date))"
    }
    
    return elapsed!
}

func resize(image: UIImage) -> Data? {
    if let imageData = image.pngData() { // if there is an image start the checks and possible compression
        let size = imageData.count / 1024
        if size > 1024 { // if the image data size is > 1024
            let compressionValue = CGFloat(1024 / Double(size)) // get the compression value needed in order to bring the image down to 1024
            return image.jpegData(compressionQuality: compressionValue) // return the compressed image data
        } else { // if your image <= 1024 nothing needs to be done and return it as is
            return imageData
        }
    } else { // if it cant get image data return nothing
        return nil
    }
}

// MARK: UIImageExtension

extension UIImage {
    var isPortrait: Bool { return size.height > size.width }
    var isLandscape: Bool { return size.width > size.height }
    var breadth: CGFloat { return min(size.width, size.height) }
    var breadthSize: CGSize { return CGSize(width: self.breadth, height: self.breadth) }
    var breadthRect: CGRect { return CGRect(origin: .zero, size: self.breadthSize) }
    
    var circleMasked: UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.breadthSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        guard let cgImage = cgImage?.cropping(to: CGRect(origin: CGPoint(x: isLandscape ? floor((size.width - size.height) / 2) : 0, y: isPortrait ? floor((size.height - size.width) / 2) : 0), size: breadthSize)) else { return nil }
        UIBezierPath(ovalIn: self.breadthRect).addClip()
        UIImage(cgImage: cgImage).draw(in: self.breadthRect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func scaleImageToSize(newSize: CGSize) -> UIImage {
        var scaledImageRect = CGRect.zero
        
        let aspectWidth = newSize.width / size.width
        let aspectheight = newSize.height / size.height
        
        let aspectRatio = max(aspectWidth, aspectheight)
        
        scaledImageRect.size.width = size.width * aspectRatio
        scaledImageRect.size.height = size.height * aspectRatio
        scaledImageRect.origin.x = (newSize.width - scaledImageRect.size.width) / 2.0
        scaledImageRect.origin.y = (newSize.height - scaledImageRect.size.height) / 2.0
        
        UIGraphicsBeginImageContext(newSize)
        draw(in: scaledImageRect)
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
    
    func correctlyOrientedImage() -> UIImage {
        if self.imageOrientation == .up {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? self
    }
}

extension UIImageView {
    public func maskCircle() {
        self.contentMode = UIView.ContentMode.scaleAspectFill
        self.layer.cornerRadius = self.frame.height / 2
        self.layer.masksToBounds = false
        self.clipsToBounds = true
    }
}

extension UIImage {
    func cropsToSquare() -> UIImage {
        let refWidth = CGFloat(self.cgImage!.width)
        let refHeight = CGFloat(self.cgImage!.height)
        let cropSize = refWidth > refHeight ? refHeight : refWidth
        
        let x = (refWidth - cropSize) / 2.0
        let y = (refHeight - cropSize) / 2.0
        
        let cropRect = CGRect(x: x, y: y, width: cropSize, height: cropSize)
        let imageRef = self.cgImage!.cropping(to: cropRect)!
        let cropped = UIImage(cgImage: imageRef, scale: 0.0, orientation: self.imageOrientation)
        
        return cropped
    }
    
    func imageWithColor(color1: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        color1.setFill()
        
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: 0, y: self.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(CGBlendMode.normal)
        
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height) as CGRect
        context.clip(to: rect, mask: self.cgImage!)
        context.fill(rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // Move origin to middle
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

extension UINavigationController {
    func popViewController(animated: Bool = true, completion: @escaping () -> Void) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        self.popViewController(animated: animated)
        CATransaction.commit()
    }
}

extension UIView {
    @IBInspectable var cornerRadiusV: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    func addTopBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: width)
        self.layer.addSublayer(border)
    }
    
    func addRightBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: self.frame.size.width - width, y: 0, width: width, height: self.frame.size.height)
        self.layer.addSublayer(border)
    }
    
    func addBottomBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: self.frame.size.height - width, width: self.frame.size.width, height: width)
        self.layer.addSublayer(border)
    }
    
    func addLeftBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: 0, width: width, height: self.frame.size.height)
        self.layer.addSublayer(border)
    }
    
    func shake() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: self.center.x - 5, y: self.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: self.center.x + 5, y: self.center.y))
        self.layer.add(animation, forKey: "position")
    }
    
    func shakeDeletingCell() {
        let transformAnim = CAKeyframeAnimation(keyPath: "transform")
        transformAnim.values = [NSValue(caTransform3D: CATransform3DMakeRotation(0.04, 0.0, 0.0, 1.0)), NSValue(caTransform3D: CATransform3DMakeRotation(-0.04, 0, 0, 1))]
        transformAnim.autoreverses = true
        transformAnim.duration = 0.1
        transformAnim.repeatCount = Float.infinity
        self.layer.add(transformAnim, forKey: "transform")
    }
    
    func stopShaking() {
        self.layer.removeAllAnimations()
    }
}

extension UICollectionView {
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width - 10, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .systemGray3
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont(name: "TrebuchetMS", size: 15)
        messageLabel.sizeToFit()
        
        self.backgroundView = messageLabel
    }
    
    func restore() {
        self.backgroundView = nil
    }
}

extension UITableView {
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width - 10, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .systemGray3
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont(name: "TrebuchetMS", size: 15)
        messageLabel.sizeToFit()
        
        self.backgroundView = messageLabel
        self.separatorStyle = .none
    }
    
    func restore() {
        self.backgroundView = nil
        // self.separatorStyle = .singleLine
    }
}

extension Array where Element: Equatable {
    public mutating func mergeElements<C: Collection>(newElements: C) where C.Iterator.Element == Element {
        let filteredList = newElements.filter { !self.contains($0) }
        self.append(contentsOf: filteredList)
    }
}

@IBDesignable class MyButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.updateCornerRadius()
    }
    
    @IBInspectable var rounded: Bool = false {
        didSet {
            self.updateCornerRadius()
        }
    }
    
    func updateCornerRadius() {
        layer.cornerRadius = self.rounded ? frame.size.height / 2 : 0
    }
}

extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
    
    enum Brightness {
        case light
        case dark
    }
    
    class func getAppColor(_ withBrightness: Brightness) -> UIColor {
        switch withBrightness {
        case .dark:
            return UIColor(hexString: kAPPLIGHTCOLORSTRING)
        case .light:
            // return UIColor(hexString: kAPPDARKCOLORSTRING)
            return UIColor(named: "outgoingBubbleColor")!
        }
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + self.lowercased().dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}

extension UIImage {
    func resize(withPercentage percentage: CGFloat) -> UIImage? {
        var newRect = CGRect(origin: .zero, size: CGSize(width: size.width * percentage, height: size.height * percentage))
        UIGraphicsBeginImageContextWithOptions(newRect.size, true, 1)
        self.draw(in: newRect)
        defer { UIGraphicsEndImageContext() }
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func resizeTo(MB: Double) -> UIImage? {
        guard let fileSize = self.pngData()?.count else { return nil }
        let fileSizeInMB = CGFloat(fileSize) / (1024.0 * 1024.0) // form bytes to MB
        let percentage = 1 / fileSizeInMB
        return self.resize(withPercentage: percentage)
    }
    
    func resizeTo(MB: Double, completion: @escaping (UIImage) -> Void) {
        guard let fileSize = self.pngData()?.count else { return }
        let fileSizeInMB = CGFloat(fileSize) / (1024.0 * 1024.0) // form bytes to MB
        let percentage = 1 / fileSizeInMB
        completion(self.resize(withPercentage: percentage)!)
    }
}

extension UIFont {
    var bold: UIFont {
        return self.with(.traitBold)
    }
    
    var italic: UIFont {
        return self.with(.traitItalic)
    }
    
    var boldItalic: UIFont {
        return self.with([.traitBold, .traitItalic])
    }
    
    func with(_ traits: UIFontDescriptor.SymbolicTraits...) -> UIFont {
        guard let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits).union(self.fontDescriptor.symbolicTraits)) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: 0)
    }
    
    func without(_ traits: UIFontDescriptor.SymbolicTraits...) -> UIFont {
        guard let descriptor = self.fontDescriptor.withSymbolicTraits(self.fontDescriptor.symbolicTraits.subtracting(UIFontDescriptor.SymbolicTraits(traits))) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: 0)
    }
}

extension UINavigationController {
    override open var shouldAutorotate: Bool {
        return true
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return (visibleViewController?.supportedInterfaceOrientations) ?? .allButUpsideDown
    }
}

extension UITabBarController {
    override open var shouldAutorotate: Bool {
        return true
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return (selectedViewController?.supportedInterfaceOrientations) ?? .allButUpsideDown
    }
}

extension UIApplication {
    class func getTopViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return self.getTopViewController(base: nav.visibleViewController)
            
        } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return self.getTopViewController(base: selected)
            
        } else if let presented = base?.presentedViewController {
            return self.getTopViewController(base: presented)
        }
        return base
    }
}

extension UIBarButtonItem {
    static func menuButton(_ target: Any?, action: Selector, image: UIImage) -> UIBarButtonItem {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(image, for: .normal)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.imageView?.contentMode = .scaleAspectFill
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.clipsToBounds = true
        
        let menuBarItem = UIBarButtonItem(customView: button)
        menuBarItem.customView?.translatesAutoresizingMaskIntoConstraints = false
        menuBarItem.customView?.heightAnchor.constraint(equalToConstant: 30).isActive = true
        menuBarItem.customView?.widthAnchor.constraint(equalToConstant: 30).isActive = true
        
        return menuBarItem
    }
}

func customizeNavigationBar(color: UIColor = .systemBackground, colorName: String = "bwBackground", alpha: Double = 0.9) {
    let navBarAppearance = UINavigationBarAppearance()
    navBarAppearance.configureWithOpaqueBackground()
    navBarAppearance.backgroundColor = UIColor(named: colorName)?.withAlphaComponent(CGFloat(alpha))
    navBarAppearance.backgroundImage = UIImage()
    navBarAppearance.shadowImage = nil
    navBarAppearance.shadowColor = nil
    UINavigationBar.appearance(whenContainedInInstancesOf: [UINavigationController.self]).standardAppearance = navBarAppearance
    UINavigationBar.appearance(whenContainedInInstancesOf: [UINavigationController.self]).scrollEdgeAppearance = navBarAppearance
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

func checkCameraAccess(viewController: UIViewController, completion: @escaping (CNAuthorizationStatus) -> Void) {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .denied:
        print("Denied, request permission from settings")
        presentSettings(viewController: viewController, titleText: "Camera and media access denied")
        completion(.denied)
    case .restricted:
        print("Restricted, device owner must approve")
        completion(.denied)
    case .authorized:
        print("Authorized, proceed")
        completion(.authorized)
    case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { success in
            if success {
                print("Permission granted, proceed")
                completion(.authorized)
            } else {
                print("Permission denied")
                completion(.denied)
            }
        }
    }
}

func checkMicPermission(viewController: UIViewController, whenSomeoneIsCalling receivedCall: Bool = false, completion: @escaping (CNAuthorizationStatus) -> Void) {
    switch AVAudioSession.sharedInstance().recordPermission {
    case AVAudioSessionRecordPermission.granted:
        UserDefaults.standard.set(false, forKey: "Don't ask for mic permission")
        completion(.authorized)
    case AVAudioSessionRecordPermission.denied:
        !receivedCall ? presentSettings(viewController: viewController, titleText: "Microphone access denied") : !UserDefaults.standard.bool(forKey: "Don't ask for mic permission") ? showReceivedCallDialog(viewController: viewController) : completion(.denied)
    // completion(.denied)
    case AVAudioSessionRecordPermission.undetermined:
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                UserDefaults.standard.set(false, forKey: "Don't ask for mic permission")
                completion(.authorized)
            } else {
                completion(.denied)
            }
        }
    default:
        break
    }
}

func showReceivedCallDialog(viewController: UIViewController) {
    let alertController = UIAlertController(title: "Someone is trying to call you",
                                            message: "Microphone access is currently denied. Open settings to change permission",
                                            preferredStyle: .alert)
    
    alertController.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: { _ in
                // Handle
            })
        }
    })
    
    alertController.addAction(UIAlertAction(title: "Don't ask again", style: .destructive, handler: { _ in
        UserDefaults.standard.set(true, forKey: "Don't ask for mic permission")
     }))
    
    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    
    viewController.present(alertController, animated: true)
}

func presentSettings(viewController: UIViewController, titleText: String) {
    let alertController = UIAlertController(title: titleText,
                                            message: "Open settings to change permission",
                                            preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "Cancel", style: .destructive))
    alertController.addAction(UIAlertAction(title: "Settings", style: .cancel) { _ in
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: { _ in
                // Handle
            })
        }
    })
    
    viewController.present(alertController, animated: true)
}

func checkContactsAccess(viewController: UIViewController, completion: @escaping (CNAuthorizationStatus) -> Void) {
    switch CNContactStore.authorizationStatus(for: .contacts) {
    case .authorized:
        print("Authorized, proceed")
        completion(.authorized)
    case .denied:
        presentSettings(viewController: viewController, titleText: "Contacts access denied")
        completion(.denied)
    case .restricted, .notDetermined:
        CNContactStore().requestAccess(for: .contacts) { granted, _ in
            if granted {
                print("Permission granted, proceed")
                completion(.authorized)
            } else {
                DispatchQueue.main.async {
                    print("Permission denied")
                    completion(.denied)
                }
            }
        }
    }
    completion(.denied)
}

struct MyVariables {
    static var globalContactsVariable: [String] = [] {
        didSet {
            NotificationCenter.default.post(name: .globalContactsVariable, object: nil)
        }
    }
    
    static var internetConnectionState: Bool = true {
        didSet {
            NotificationCenter.default.post(name: .internetConnectionState, object: nil)
        }
    }
    
    static var wasShowingVariableInChat = false
    
    static var isSyncingContacts = false
    
    static var usersOnline: [String] = [] {
        didSet {
            NotificationCenter.default.post(name: .onlineUsersNotification, object: nil)
        }
    }
}

extension Date {
    func stripTime() -> Date {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        let date = Calendar.current.date(from: components)
        return date!
    }
}

extension DispatchQueue {
    static func background(delay: Double = 0.0, background: (() -> Void)? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            background?()
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    completion()
                }
            }
        }
    }
}

extension UITableView {
    func hideTableHeaderView() {
        self.beginUpdates()
        UIView.animate(withDuration: 0.2, animations: {
            self.tableHeaderView = nil
        })
        self.endUpdates()
    }
    
    func showTableHeaderView(header: UIView) {
        let headerView = header
        self.beginUpdates()
        let headerFrame = headerView.frame
        headerView.frame = CGRect()
        self.tableHeaderView = headerView
        UIView.animate(withDuration: 0.2, animations: {
            self.tableHeaderView?.frame = headerFrame
            self.tableHeaderView?.alpha = 0
            self.endUpdates()
        }, completion: { _ in
            self.tableHeaderView?.alpha = 1
        })
    }
}

extension String {
    subscript(bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }
    
    subscript(bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
    
    func removeExtraSpaces() -> String {
        return self.replacingOccurrences(of: "[\\s\n]+", with: " ", options: .regularExpression, range: nil)
    }
}

extension UIViewController {
    func showInputDialog(title: String? = nil,
                         subtitle: String? = nil,
                         actionTitle: String? = "Add",
                         cancelTitle: String? = "Cancel",
                         inputPlaceholder: String? = nil,
                         inputKeyboardType: UIKeyboardType = UIKeyboardType.default,
                         cancelHandler: ((UIAlertAction) -> Swift.Void)? = nil,
                         actionHandler: ((_ text: String?) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
        alert.addTextField { (textField: UITextField) in
            textField.placeholder = inputPlaceholder
            textField.keyboardType = inputKeyboardType
            textField.isSecureTextEntry = true
        }
        alert.addAction(UIAlertAction(title: actionTitle, style: .destructive, handler: { (_: UIAlertAction) in
            guard let textField = alert.textFields?.first else {
                actionHandler?(nil)
                return
            }
            actionHandler?(textField.text)
        }))
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: cancelHandler))
        
        self.present(alert, animated: true, completion: nil)
    }
}

extension Date {
    func timeAgoSinceDate() -> String {
        // From Time
        let fromDate = self
        
        // To Time
        let toDate = Date()
        
        // Estimation
        // Year
        if let interval = Calendar.current.dateComponents([.year], from: fromDate, to: toDate).year, interval > 0 {
            return interval == 1 ? "\(interval)" + " " + "year ago" : "\(interval)" + " " + "years ago"
        }
        
        // Month
        if let interval = Calendar.current.dateComponents([.month], from: fromDate, to: toDate).month, interval > 0 {
            return interval == 1 ? "\(interval)" + " " + "month ago" : "\(interval)" + " " + "months ago"
        }
        
        // Day
        if let interval = Calendar.current.dateComponents([.day], from: fromDate, to: toDate).day, interval > 0 {
            return interval == 1 ? "\(interval)" + " " + "day ago" : "\(interval)" + " " + "days ago"
        }
        
        // Hours
        if let interval = Calendar.current.dateComponents([.hour], from: fromDate, to: toDate).hour, interval > 0 {
            return interval == 1 ? "\(interval)" + " " + "hour ago" : "\(interval)" + " " + "hours ago"
        }
        
        // Minute
        if let interval = Calendar.current.dateComponents([.minute], from: fromDate, to: toDate).minute, interval > 0 {
            return interval == 1 ? "\(interval)" + " " + "minute ago" : "\(interval)" + " " + "minutes ago"
        }
        
        return "just now"
    }
    
    func timeAgoInMessages(fullTimeAgo: Bool = false) -> String {
        // From Time
        let fromDate = self
        
        // To Time
        let toDate = Date()
        
        let dateFormatter = DateFormatter()
        // Estimation
        // Year
        
        if fullTimeAgo {
            if Calendar.current.isDateInToday(fromDate) {
                return "・Today・"
            }
            else if Calendar.current.isDateInYesterday(fromDate) {
                return "Yesterday"
            }
            else if let interval = Calendar.current.dateComponents([.year], from: fromDate, to: toDate).year, interval > 0 {
                dateFormatter.dateFormat = "MMMM d, yyy"
                return dateFormatter.string(from: fromDate)
            } else {
                dateFormatter.dateFormat = "EEEE, d MMMM"
                return dateFormatter.string(from: fromDate)
            }
        } else {
            dateFormatter.dateFormat = "HH:mm"
            return dateFormatter.string(from: fromDate)
        }
//        
//        if fullTimeAgo {
//            if Calendar.current.isDateInToday(fromDate) {
//                return "・Today・"
//            }
//            
//            if Calendar.current.isDateInYesterday(fromDate) {
//                return "Yesterday"
//            }
//            
//            if let interval = Calendar.current.dateComponents([.year], from: fromDate, to: toDate).year, interval > 0 {
//                dateFormatter.dateFormat = "MMMM d, yyy"
//                return dateFormatter.string(from: fromDate)
//            }
//            
//            // Month
//            if let interval = Calendar.current.dateComponents([.month], from: fromDate, to: toDate).month, interval > 0 {
//                dateFormatter.dateFormat = "EEEE, d MMMM"
//                return dateFormatter.string(from: fromDate)
//            }
//            
//            // Day
//            if let interval = Calendar.current.dateComponents([.day], from: fromDate, to: toDate).day, interval > 0 {
//                if interval >= 7 {
//                    dateFormatter.dateFormat = "EEEE, d MMMM"
//                    return dateFormatter.string(from: fromDate)
//                }
//                dateFormatter.dateFormat = "EEEE"
//                return dateFormatter.string(from: fromDate)
//            }
//            
//        } else {
//            dateFormatter.dateFormat = "HH:mm"
//            return dateFormatter.string(from: fromDate)
//        }
//        return ""
    }
}

extension UIImage {
    func isEqualToImage(image: UIImage) -> Bool {
        let data1: NSData = self.pngData()! as NSData
        let data2: NSData = image.pngData()! as NSData
        return data1.isEqual(data2)
    }
}

extension String {
    func removingWhitespaces() -> String {
        return components(separatedBy: .whitespaces).joined()
    }
}

extension UICollectionView {
    func reloadData(_ completion: @escaping () -> Void) {
        self.reloadData()
        DispatchQueue.main.async { completion() }
    }
}

extension UIAlertController {
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.tintColor = .label
    }
}

extension UICollectionView {
    
    func reloadDataAndScrollToPreviousPosition() {
        let oldOffset = self.contentOffset.y
        let oldHeight = self.contentSize.height
        let reverseOffset = oldHeight - oldOffset
        
        self.reloadData()
        
        self.layoutIfNeeded()
        self.contentOffset = CGPoint(x: 0.0, y: self.contentSize.height - reverseOffset)
    }
}
