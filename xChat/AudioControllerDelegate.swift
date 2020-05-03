//
//  AudioControllerDelegate.swift
//  Sllick
//
//  Created by Isa  Selimi on 15.10.19.
//  Copyright © 2019 com.isaselimi. All rights reserved.
//

import Foundation

class AudioContollerDelegate: NSObject, SINAudioControllerDelegate {
    
    var muted: Bool!
    var speaker: Bool!//not needed
    
    func audioControllerMuted(_ audioController: SINAudioController!) {
        self.muted = true
    }
    
    func audioControllerUnmuted(_ audioController: SINAudioController) {
        self.muted = false
    }
    
    //not needed
    func audioControllerSpeakerEnabled(_ audioController: SINAudioController!) {
        self.speaker = true
    }
    
    func audioControllerSpeakerDisabled(_ audioController: SINAudioController!) {
        self.speaker = false
    }
    
}
