//
//  EMVideoVC.swift
//  emu
//
//  Created by Aviv Wolf on 11/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

import UIKit
import AVKit

class EMVideoVC: AVPlayerViewController {
    var renderer: HCRender? = nil
    var info: [NSObject:AnyObject]? = nil
    
    weak var previewDelegate : EMPreviewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showsPlaybackControls = false
        self.view.backgroundColor = UIColor.whiteColor()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.initObservers()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.removeObservers()
    }
    
    // MARK: - Observers
    func initObservers() {
        let nc = NSNotificationCenter.defaultCenter()
        
        // Looping video
        nc.addUniqueObserver(
            self,
            selector: "onPlayerItemDidReachEnd:",
            name: AVPlayerItemDidPlayToEndTimeNotification,
            object: nil)
        
        // Rendered previews
        nc.addUniqueObserver(
            self,
            selector: "onPreviewRenderUpdate:",
            name: hmkRenderingFinishedPreview,
            object: nil)
        
        // Video player errors
        nc.addUniqueObserver(
            self,
            selector: "onPlayerError:",
            name: AVPlayerItemFailedToPlayToEndTimeNotification,
            object: nil)
    }
    
    func removeObservers() {
        let nc = NSNotificationCenter.defaultCenter()
        nc.removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
        nc.removeObserver(self, name: hmkRenderingFinishedPreview, object: nil)
        nc.removeObserver(self, name: AVPlayerItemNewErrorLogEntryNotification, object: nil)
    }
    
    // MARK: - Observers handlers
    func onPlayerItemDidReachEnd(notification: NSNotification) {
        if let p = notification.object as? AVPlayerItem {
            p.seekToTime(kCMTimeZero)
        }
    }
    
    func onPreviewRenderUpdate(notification: NSNotification) {
        guard self.renderer != nil else {return}
        guard let info = notification.userInfo else {return}
        guard let uuid = info[emkUUID] as? String where uuid == self.renderer?.uuid else {return}
        
        // Store info
        self.info = info
        
        // Check for render errors
        if notification.isReportingError {
            // Something went wrong during rendering :-(
            self.epicFail()
            return
        }
            
        guard let url = info[emkURL] as? NSURL else {
            // No output url of the result?
            self.epicFail()
            return
        }
        
        // Successful preview render.
        let fm = NSFileManager.defaultManager()
        let outputExists = fm.fileExistsAtPath(url.path!)
        guard outputExists else {
            // Output file not found on local storage?
            // Something went horribly wrong.
            self.epicFail()
            return
        }
        
        // Shot it.
        self.setVideoURL(url)
        if let d = self.previewDelegate {
            d.previewIsShownWithInfo(self.info)
        }
    }
    
    func onPlayerError(notification: NSNotification) {
        
    }
    
    // MARK: - Playing video
    func setVideoURL(url: NSURL) {
        if let player = self.player {
            player.pause()
        }
        self.player = AVPlayer.init(URL: url)
        self.player?.actionAtItemEnd = AVPlayerActionAtItemEnd.None
        self.player?.seekToTime(kCMTimeZero)
        self.player?.play()
    }
    
    // MARK: - Rendering UI
    func startRenderingUI() {
        let bundle = NSBundle.mainBundle()
        let url = bundle.URLForResource("rendering", withExtension: "mp4")
        self.setVideoURL(url!)
    }
    
    // MARK: - Rendering preview
    func renderEmuDef(emuDefOID: String, captureInfo: [NSObject:AnyObject], slotIndex: Int = 0) {
        guard let emuDef = EmuticonDef.findWithID(emuDefOID, context: EMDB.sh().context) else {
            self.epicFail()
            return
        }
        
        if emuDef.allResourcesAvailable() {
            // Render a preview for this capture
            self.startRenderingUI()
            let rm = EMRenderManager3.sharedInstance
            let tempUserFootage = UserTempFootage(info: captureInfo)
            let footagesForPreview = rm.footagesForPreviewWithTempUserFootage(tempUserFootage, emuDef: emuDef, slotIndex: slotIndex)
            self.renderer = rm.renderPreviewForEmuDefOID(
                emuDefOID,
                footagesForPreview: footagesForPreview,
                slotIndex: slotIndex
            )
        } else {
            NSLog("@@@@")
        }
    }
    
    func epicFail() {
        if let d = self.previewDelegate {
            d.previewDidFailWithInfo(self.info)
        }
    }
    
    func stop() {
        if let player = self.player {
            player.pause()
        }
    }
}