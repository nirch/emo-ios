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
    var previewForEmuDefOID: String? = nil
    var captureInfo: [NSObject:AnyObject]? = nil
    var alreadyFailed: Bool = false
    private var latestPlayedURL: NSURL? = nil
    
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
            selector: #selector(EMVideoVC.onPlayerItemDidReachEnd(_:)),
            name: AVPlayerItemDidPlayToEndTimeNotification,
            object: nil)
        
        // Rendered previews
        nc.addUniqueObserver(
            self,
            selector: #selector(EMVideoVC.onPreviewRenderUpdate(_:)),
            name: hmkRenderingFinishedPreview,
            object: nil)
        
        // Video player errors
        nc.addUniqueObserver(
            self,
            selector: #selector(EMVideoVC.onPlayerError(_:)),
            name: AVPlayerItemFailedToPlayToEndTimeNotification,
            object: nil)
        
        // Downloads
        nc.addUniqueObserver(
            self,
            selector: #selector(EMVideoVC.onResourceDownload(_:)),
            name: hmkDownloadResourceFinished,
            object: nil)
    }
    
    func removeObservers() {
        let nc = NSNotificationCenter.defaultCenter()
        nc.removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
        nc.removeObserver(self, name: hmkRenderingFinishedPreview, object: nil)
        nc.removeObserver(self, name: AVPlayerItemNewErrorLogEntryNotification, object: nil)
        nc.removeObserver(self, name: hmkDownloadResourceFinished, object: nil)
    }
    
    // MARK: - Observers handlers
    func onResourceDownload(notification: NSNotification) {
        guard let info = notification.userInfo else {return}
        guard let dlTaskType = info[emkDLTaskType] as? String else {return}
        guard dlTaskType == "download for preview" else {return}
        guard let emuDefOID = info[emkEmuticonDefOID] as? String else {return}
        guard emuDefOID == self.previewForEmuDefOID else {return}
        guard let emuDef = EmuticonDef.findWithID(emuDefOID, context: EMDB.sh().context) else {
            self.epicFail()
            return
        }

        // On error, epic fail.
        if notification.isReportingError {
            self.epicFail()
            return
        }
        
        if emuDef.isNewStyleLongRender() && emuDef.allFullRenderResourcesAvailable() {
            self.retryLastPreviewRender()
            return
        }
        
        if !emuDef.isNewStyleLongRender() && emuDef.allResourcesAvailable() {
            self.retryLastPreviewRender()
            return
        }
    }
    
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
        self.latestPlayedURL = url
        self.player = AVPlayer.init(URL: url)
        self.player?.actionAtItemEnd = AVPlayerActionAtItemEnd.None
        self.player?.seekToTime(kCMTimeZero)
        self.player?.play()
    }
    
    func latestVideoURL() -> NSURL? {
        return self.latestPlayedURL
    }
    
    // MARK: - Rendering UI
    func startRenderingUI() {
        let bundle = NSBundle.mainBundle()
        let url = bundle.URLForResource("rendering", withExtension: "mp4")
        self.setVideoURL(url!)
    }
    
    func startDownloadingUI() {
        let bundle = NSBundle.mainBundle()
        let url = bundle.URLForResource("downloading", withExtension: "mp4")
        self.setVideoURL(url!)
    }
    
    // MARK: - Rendering preview
    func retryLastPreviewRender() {
        guard let emuDefOID = self.previewForEmuDefOID else {return}
        guard let captureInfo = self.captureInfo else {return}
        self.renderEmuDef(emuDefOID, captureInfo: captureInfo)
    }
    
    func renderEmuDef(emuDefOID: String, captureInfo: [NSObject:AnyObject], slotIndex: Int = 0) {
        guard let emuDef = EmuticonDef.findWithID(emuDefOID, context: EMDB.sh().context) else {
            self.epicFail()
            return
        }
        
        self.previewForEmuDefOID = emuDefOID
        self.captureInfo = captureInfo
        self.alreadyFailed = false
        
        // First make sure resources available locally.
        if emuDef.isNewStyleLongRender() {
            guard emuDef.allFullRenderResourcesAvailable() else {
                self.startDownloadingUI()
                let info = [emkDLTaskType:"download for preview",emkEmuticonDefOID:emuDefOID]
                let enqueued = emuDef.enqueueIfMissingFullRenderResourcesWithInfo(info)
                if (enqueued) {
                    EMDownloadsManager2.sh().manageQueue()
                } else {
                    self.epicFail()
                }
                return
            }
        } else {
            guard emuDef.allResourcesAvailable() else {
                self.startDownloadingUI()
                let info = [emkDLTaskType:"download for preview",emkEmuticonDefOID:emuDefOID]
                let enqueued = emuDef.enqueueIfMissingResourcesWithInfo(info)
                if (enqueued) {
                    EMDownloadsManager2.sh().manageQueue()
                } else {
                    self.epicFail()
                }
                return
            }
        }
        
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
    }
    
    func epicFail() {
        if self.alreadyFailed {return}
        
        if let d = self.previewDelegate {
            self.alreadyFailed = true
            d.previewDidFailWithInfo(self.info)
        }
    }
    
    func stop() {
        if let player = self.player {
            player.pause()
        }
    }
}