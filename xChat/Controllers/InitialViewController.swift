//
//  InitialViewController.swift
//  Sllick
//
//  Created by Isa  Selimi on 15.11.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import UIKit

class InitialViewController: UIViewController {

    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        loginButton.backgroundColor = UIColor.getAppColor(.light)
        signupButton.backgroundColor = UIColor.getAppColor(.dark)
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.navigationController?.isNavigationBarHidden = true
    }
    
    @IBAction func loginPressed(_ sender: Any) {
//      print("Pressed")
//        let viewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "loginView") as! LoginViewController
//        self.navigationController?.pushViewController(viewController
//            , animated: true)
    }
    

}
