//
//  EMRecordingPreviewVC.swift
//  emu
//
//  Created by Aviv Wolf on 11/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

import UIKit
import AVKit

class EMRecordingPreviewVC: AVPlayerViewController {
    var latestPreviewUUID : String? = nil
    var info : [NSObject:AnyObject]? = nil
    
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
        if self.latestPreviewUUID == nil {return}
        let info = notification.userInfo!
        
        if let uuid = info[emkUUID] as? String {
            
            // Ignore old renders
            if uuid != self.latestPreviewUUID {return}
            
            // Store info
            self.info = info
            
            // Check for render errors
            if notification.isReportingError {
                self.epicFail()
                return
            }
            
            // Successful preview render. Show it!
            if let url = info[emkURL] as? NSURL {
                let fm = NSFileManager.defaultManager()
                let exists = fm.fileExistsAtPath(url.path!)
                if exists == false {
                    self.epicFail()
                    return
                }
                
                self.setVideoURL(url)
                if let d = self.previewDelegate {
                    d.previewIsShownWithInfo(self.info)
                }
            } else {
                self.epicFail()
            }
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
    func renderEmuDef(emuDefOID: String, captureInfo: [NSObject:AnyObject]) {
        if let emuDef = EmuticonDef.findWithID(emuDefOID, context: EMDB.sh().context) {
            if emuDef.allResourcesAvailable() {
                // Render a preview for this capture
                self.startRenderingUI()
                let rm = EMRenderManager3.sharedInstance
                self.latestPreviewUUID = rm.renderPreviewForEmuDefOID(emuDefOID, captureInfo: captureInfo)
            } else {
                // Download resources first, before rendering
//                self.startDownloadingUI()
            }
        } else {
            self.epicFail()
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