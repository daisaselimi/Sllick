//
//  InitialViewController.swift
//  Sllick
//
//  Created by Isa  Selimi on 15.11.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import UIKit

class InitialViewController: UIViewController {
    
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var signupButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.overrideUserInterfaceStyle = .dark
        self.view.window?.overrideUserInterfaceStyle = .dark
        // self.view.window?.overrideUserInterfaceStyle = .dark
        self.loginButton.backgroundColor = UIColor.getAppColor(.light)
        self.signupButton.backgroundColor = UIColor.getAppColor(.dark)
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        // self.view.window?.overrideUserInterfaceStyle = .dark
        self.navigationController?.isNavigationBarHidden = true
    }

    @IBAction func loginPressed(_ sender: Any) {
//      print("Pressed")
//        let viewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "loginView") as! LoginViewController
//        self.navigationController?.pushViewController(viewController
//            , animated: true)
    }
}
