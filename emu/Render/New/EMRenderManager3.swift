/*
=============================================================================

██████╗ ███████╗███╗   ██╗██████╗ ███████╗██████╗
██╔══██╗██╔════╝████╗  ██║██╔══██╗██╔════╝██╔══██╗
██████╔╝█████╗  ██╔██╗ ██║██║  ██║█████╗  ██████╔╝
██╔══██╗██╔══╝  ██║╚██╗██║██║  ██║██╔══╝  ██╔══██╗
██║  ██║███████╗██║ ╚████║██████╔╝███████╗██║  ██║
╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═╝

███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗
████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗
██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝
██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗
██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║
╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝

3!

=============================================================================
EMRenderManager3

Emu's render manager version 3 - Using Homage SDK Core HCRender for rendering

Created by Aviv Wolf on 1/13/2016.
Copyright (c) 2015 Homage. All rights reserved.
=============================================================================
*/

//
//  EMRenderManager3.swift
//  emu
//
//  Created by Aviv Wolf on 13/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

import Foundation

class EMRenderManager3 : NSObject
{
    static let sharedInstance = EMRenderManager3()
    
    private var MAX_CONCURENT_RENDERS_SLOW = 1
    private var MAX_CONCURENT_RENDERS = 2
    
    private var maxConcurrentRender : Int
    
    // States
    private var paused = false
    private var renderingPOOL: Dictionary<String, AnyObject>
    private var readyPool: Dictionary<String, AnyObject>
    private var userInfo: Dictionary<String, AnyObject>
    
    /// The rendering queue
    var renderingQueue : dispatch_queue_t
    
    override init() {
        // Defaults
        self.maxConcurrentRender = MAX_CONCURENT_RENDERS
        
        // Data structures
        self.renderingPOOL = Dictionary<String, AnyObject>()
        self.readyPool = Dictionary<String, AnyObject>()
        self.userInfo = Dictionary<String, AnyObject>()
        
        // Rendering Queue
        self.renderingQueue = dispatch_queue_create("rendering Queue", DISPATCH_QUEUE_CONCURRENT);

        // Super
        super.init()
    }
    
    
    //
    // MARK: - Rendering
    
    /**
    Will send emu def for rendering a preview (usually used in recorders or footage selection to display recording results)
    Will not use the rendering queue - will dispatch the work on the global queue in high priority
    
    - parameter emuDefOID:   The oid of the emu definition
    - parameter captureInfo: Dictionary with info about the captured user
    */
    func renderPreviewForEmuDefOID(emuDefOID : String, captureInfo : [NSObject:AnyObject]) -> String? {
        // Must have an emu definition and all resources must exist on local storage
        let emuDef = EmuticonDef.findWithID(emuDefOID, context: EMDB.sh().context)
        if emuDef == nil {return nil}
        if !emuDef.allResourcesAvailable() {return nil}
        
        // Create CFG for renderer
        let uuid = NSUUID().UUIDString
        let cfg = emuDef.hcRenderCFGWithUserLayerInfo(captureInfo, inHD: false, fps: 24)
        cfg[hcrOutputsInfo] = [[hcrOutputType:hcrVideo, hcrRelativePath:"tmp_preview_\(uuid).mov"]]
        
        // Render
        var renderInfo = [
            emkUUID:uuid,
            emkEmuticonDefOID:emuDefOID,
            emkCaptureInfo:captureInfo
        ] as [NSObject:AnyObject]
        let renderer = HCRender(configurationInfo: cfg as [NSObject:AnyObject], userInfo: [emkEmuticonDefOID:emuDefOID,"uuid":uuid])

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            renderer.setup()
            if (renderer.error == nil) {
                // Render
                renderer.process()
                
                // Finished render
                renderInfo[emkURL] = renderer.outputURL()
            } else {
                // Configuration error for render
                renderInfo[emkError] = renderer.error
            }
            
            // Notify main thread about render success/failure 
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let nc = NSNotificationCenter.defaultCenter()
                nc.postNotificationName(
                    hmkRenderingFinishedPreview,
                    object: nil,
                    userInfo: renderInfo
                )
            })
        }
        
        return uuid
    }
    
}

/**
if emuDef.allResourcesAvailable() {
let cfg = emuDef.hcRenderCFGWithUserLayerInfo(info, inHD: false, fps: 12)
let uuid = NSUUID().UUIDString
cfg[hcrOutputsInfo] = [
[
hcrOutputType:hcrVideo,
hcrRelativePath:"preview_\(uuid).mov"
]
]
dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
let renderer = HCRender(configurationInfo: cfg as [NSObject:AnyObject], userInfo: nil)
renderer.setup()
if renderer.error != nil {
self.epicFail()
return
}
renderer.process()
if let url = renderer.outputURL() {

} else {
self.epicFail()
return
}
})
*/