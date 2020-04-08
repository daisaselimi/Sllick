//
//  CallViewController.swift
//  xChat
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
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var muteButtonOutlet: UIButton!
    @IBOutlet weak var speakerButtonOutlet: UIButton!
    @IBOutlet weak var answerCallButtonOutlet: UIButton!
    @IBOutlet weak var endCallButtonOutlet: UIButton!
    @IBOutlet weak var declineCallButtonOutlet: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        fullNameLabel.text = "Unknown"
        let id =  _call.remoteUserId
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

    
    override func viewDidLayoutSubviews() {
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _call.delegate = self
        if _call.direction == SINCallDirection.incoming {
        
            //show buttons
            showButtons()
            audioController()?.startPlayingSoundFile(pathForSOund(sound: "incoming"), loop: true)
            
        } else {
            callAnswered = true
            //show buttons
            setCallTime(text: "Calling...")
            showButtons()
            
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
    
    func setCallTime(text: String) {
        timeLabel.text = text
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
            muteButtonOutlet.setImage(UIImage(named: "mute"), for: .normal)
        } else {
            muted = true
            audioController()!.mute()
            muteButtonOutlet.setImage(UIImage(named: "muteSelected"), for: .normal)
        }
    }
    
    @IBAction func speakerButtonPressed(_ sender: Any) {
        
        if !speaker {
            speaker = true
            audioController()!.enableSpeaker()
            speakerButtonOutlet.setImage(UIImage(named: "speakerSelected"), for: .normal)
        } else {
            speaker = false
            audioController()!.disableSpeaker()
            speakerButtonOutlet.setImage(UIImage(named: "speaker"), for: .normal)
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
        
        setCallTime(text: "Ringing...")
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
        setCallTime(text: "\(min) : \(sec)")
        
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
