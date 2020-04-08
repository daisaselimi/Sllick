//
//  T_CViewController.swift
//  xChat
//
//  Created by Isa  Selimi on 5.11.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import UIKit

class T_CViewController: UIViewController {

    @IBOutlet weak var t_c_textView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.largeTitleDisplayMode = .never
        let url = Bundle.main.url(forResource: "terms_and_conditions", withExtension: "rtf")!
             let opts : [NSAttributedString.DocumentReadingOptionKey : Any] =
                 [.documentType : NSAttributedString.DocumentType.rtf]
             let t_c_text = try! NSAttributedString(url: url, options: opts, documentAttributes: nil)
        self.t_c_textView.attributedText = t_c_text
        self.t_c_textView.textColor = .label
        self.t_c_textView.scrollRangeToVisible(NSRange(location: 0, length: 0))
        // Do any additional setup after loading the view.
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
