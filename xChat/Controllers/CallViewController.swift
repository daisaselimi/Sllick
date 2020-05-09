//
//  CallViewController.swift
//  Sllick
//
//  Created by Isa  Selimi on 21.3.20.
//  Copyright © 2020 com.isaselimi. All rights reserved.
//

import UIKit

class CallViewController: UIViewController, SINCallDelegate {
    
    
    var speaker = false
    var muted = false
    var durationTimer: Timer! = nil
    var _call: SINCall!
    var callAnswered = false
    var callingName: String?
    var callingImage: UIImage?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var justOpened = true
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
       return .portrait
     }
    
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var muteButtonOutlet: UIButton!
    @IBOutlet weak var speakerButtonOutlet: UIButton!
    @IBOutlet weak var answerCallButtonOutlet: UIButton!
    @IBOutlet weak var endCallButtonOutlet: UIButton!
    @IBOutlet weak var declineCallButtonOutlet: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
      
        let id =  _call.remoteUserId
        if let callingName = self.callingName {
            fullNameLabel.text = callingName
        }
        if let callingImage = self.callingImage {
            self.avatarImageView.image = callingImage
        }
        getUsersFromFirestore(withIds: [id!]) { (allUsers) in
            if allUsers.count > 0 {
                let user = allUsers.first!
                self.fullNameLabel.text = user.fullname
                imageFromData(pictureData: user.avatar) { (image) in
                    if image != nil {
                        self.avatarImageView.image = image!.circleMasked
                    }
                }
            }
        }
    }
    
    func setupBackground() {
        if !UIAccessibility.isReduceTransparencyEnabled {
            self.view.backgroundColor = .clear

            let blurEffect = UIBlurEffect(style: .dark)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            //always fill the view
            blurEffectView.frame = self.view.bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            self.view.insertSubview(blurEffectView, at: 0)
        //if you have more UIViews, use an insertSubview API to place it where needed
        } else {
            self.view.backgroundColor = .systemBackground
        }
    }

    
    override func viewDidLayoutSubviews() {
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
          timeLabel.isHidden = false
          self.avatarImageView.maskCircle()
        _call.delegate = self
        if _call.direction == SINCallDirection.incoming {
        
            //show buttons
            showButtons()
            audioController()?.startPlayingSoundFile(pathForSOund(sound: "incoming"), loop: true)
            
        } else {
            callAnswered = true
               showButtons()
            //show buttons
            setCallTime(text: "Calling...", animation: true)
         
            
        }
    }
    
    func audioController() -> SINAudioController? {
       let scene = UIApplication.shared.connectedScenes.first
        if let sd : SceneDelegate = (scene?.delegate as? SceneDelegate) {
            return sd._client.audioController()
        }
        return nil
    }
    
    func setCall(call: SINCall) {
      _call = call
        _call.delegate = self
    }
    
    //MARK: Update UI
    
    func setCallTime(text: String, animation: Bool) {
        
        if animation {
            UIView.transition(with: self.timeLabel, duration: 0.3, options: .transitionFlipFromTop, animations: {
                 self.timeLabel.text = text
                  }, completion: nil)
        } else {
             self.timeLabel.text = text
        }
 
       
    
    }
    
    func showButtons() {
        if callAnswered {
            declineCallButtonOutlet.isHidden = true
            endCallButtonOutlet.isHidden = false
            answerCallButtonOutlet.isHidden = true
            muteButtonOutlet.isHidden = false
            speakerButtonOutlet.isHidden = false
        } else {
            declineCallButtonOutlet.isHidden = false
            endCallButtonOutlet.isHidden = true
            answerCallButtonOutlet.isHidden = false
            muteButtonOutlet.isHidden = true
            speakerButtonOutlet.isHidden = true
        }
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    //MARK: IBActions
    
    @IBAction func muteButtonPressed(_ sender: Any) {
        if muted {
            muted = false
            audioController()!.unmute()
            UIView.transition(with: self.muteButtonOutlet, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.muteButtonOutlet.setImage(UIImage(named: "mute"), for: .normal)
            }, completion: nil)
            
        } else {
            muted = true
            audioController()!.mute()
            
            UIView.transition(with: self.muteButtonOutlet, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.muteButtonOutlet.setImage(UIImage(named: "muteSelected"), for: .normal)
            }, completion: nil)
        }
    }
    
    @IBAction func speakerButtonPressed(_ sender: Any) {
        
        if !speaker {
            speaker = true
            audioController()!.enableSpeaker()
            UIView.transition(with: self.speakerButtonOutlet, duration: 0.2, options: .transitionCrossDissolve, animations: {
                 self.speakerButtonOutlet.setImage(UIImage(named: "speakerSelected"), for: .normal)
            }, completion: nil)
            
        } else {
            speaker = false
            audioController()!.disableSpeaker()
            UIView.transition(with: self.speakerButtonOutlet, duration: 0.2, options: .transitionCrossDissolve, animations: {
                           self.speakerButtonOutlet.setImage(UIImage(named: "speaker"), for: .normal)
                       }, completion: nil)
          
        }
    }
    
    @IBAction func answerButtonPressed(_ sender: Any) {
        callAnswered = true
        showButtons()
        audioController()?.stopPlayingSoundFile()
        _call.answer()
    }
    
    @IBAction func endCallButtonPressed(_ sender: Any) {
        _call.hangup()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func declineButtonPressed(_ sender: Any) {
        _call.hangup()
         self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: SINCallDelegates
    
    func callDidProgress(_ call: SINCall!) {
        
        setCallTime(text: "Ringing...", animation: true)
        audioController()!.startPlayingSoundFile(pathForSOund(sound: "ringback"), loop: true)
    }
    
    func callDidEstablish(_ call: SINCall!) {
        startCallDurationTimer()
        showButtons()
        audioController()?.stopPlayingSoundFile()
    }
    
    func callDidEnd(_ call: SINCall!) {
        stopCallDurationTimer()
        audioController()?.stopPlayingSoundFile()
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: Timer
    
    @objc func onDuration() {
        let duration = Date().timeIntervalSince(_call.details.establishedTime)
        //update timer label
        updateTimerLabel(seconds: Int(duration))
    }
    
    func updateTimerLabel(seconds: Int) {
        
        let min = String(format: "%02d", (seconds/60))
        let sec = String(format: "%02d", (seconds % 60))
        setCallTime(text: "\(min) : \(sec)", animation: justOpened ? true : false)
        justOpened = false
        
    }
    
    func startCallDurationTimer() {
        self.durationTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.onDuration), userInfo: nil, repeats: true)
    }
    
    func stopCallDurationTimer() {
        if durationTimer != nil {
            durationTimer.invalidate()
            durationTimer = nil
        }
    }
    
    //MARK: Helpers
    
    func pathForSOund(sound: String) -> String {
        return Bundle.main.path(forResource: sound, ofType: "wav")!
    }
    
    
}
