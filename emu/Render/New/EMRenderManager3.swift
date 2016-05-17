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
    internal static let sharedInstance = EMRenderManager3()
    
//    static private let FPS_CAPTURE_PREVIEW = 25
//    static private let FPS_LD_SHORT_PREVIEW = 6
    
    private var MAX_CONCURENT_RENDERS_SLOW = 1
    private var MAX_CONCURENT_RENDERS = 2
    
    private var maxConcurrentRenders : Int
    
    // States
    private var paused = false
    
    // Rendering pool (in rendering)
    private var renderingPOOL: [String:AnyObject]
    
    // Ready pool (ready to be rendered)
    private var readyPool: [String:AnyObject]
    
    // More info by oid.
    private var userInfo: [String:AnyObject]
    
    /// The rendering queue
    var renderingQueue: dispatch_queue_t
    var renderingManagementQueue: dispatch_queue_t
    
    override init() {
        // Defaults
        self.maxConcurrentRenders = MAX_CONCURENT_RENDERS
        
        // Data structures
        self.renderingPOOL = Dictionary<String, AnyObject>()
        self.readyPool = Dictionary<String, AnyObject>()
        self.userInfo = Dictionary<String, AnyObject>()
        
        // Rendering Queue
        self.renderingQueue = dispatch_queue_create("rendering Queue", DISPATCH_QUEUE_CONCURRENT);
        
        // Rendering management queue
        let attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_BACKGROUND, 0)
        self.renderingManagementQueue = dispatch_queue_create("rendering Management Queue", attr)
        
        // Super
        super.init()
    }
    
    class func sh() -> EMRenderManager3 {
        return EMRenderManager3.sharedInstance
    }
    
    //
    // MARK: - Rendering
    //
    func renderFromEmuGif(emu: Emuticon,
                          outputMediaType: EMMediaDataType = .Video,
                          loopsCount: Int = 5,
                          addWaterMark: Bool = false ) -> HCRender? {
        
        guard emu.wasRendered?.boolValue == true else {return nil}
        guard let emuDef = emu.emuDef else {return nil}
        guard let gifPath = emu.animatedGifPath() else {return nil}

        // Make sure gif file exists on disk
        let fm = NSFileManager.defaultManager()
        guard fm.fileExistsAtPath(gifPath) else {return nil}
        
        // Delete output video path if exists
        do {try fm.removeItemAtPath(emu.videoPath())} catch {}
        
        let duration = emuDef.duration!.doubleValue
        let loopedDuration = duration * Double(loopsCount)
        
        var renderCFG = [String: AnyObject]()
        renderCFG[hcrWidth] = emuDef.emuWidth != nil ? Int(emuDef.emuWidth!):240
        renderCFG[hcrHeight] = emuDef.emuHeight != nil ? Int(emuDef.emuHeight!):240
        renderCFG[hcrDuration] = loopedDuration
        renderCFG[hcrFPS] = emuDef.fps()
        
        // layers info
        var layersInfo = [
            [
                hcrSourceType:hcrGIF,
                hcrPath:gifPath,
                hcrDuration: duration
            ]
        ] as [[String:AnyObject]]

        // Add watermark if required
        if (addWaterMark) {
            layersInfo.append([
                hcrSourceType:hcrPNG,
                hcrResourceName:"emu_watermark",
                hcrEffects:[
                    [
                        hcrEffectType:"transform",
                        hcrPositionUnits:hcrPositionUnitsPoints,
                        hcrTransformValue:[hcrPosition:[34,9]]
                    ]
                ]
            ])
        }
        renderCFG[hcrSourceLayersInfo] = layersInfo
        
        
        if outputMediaType == .Video {
            renderCFG[hcrOutputsInfo] = [
                [
                    hcrOutputType:hcrVideo,
                    hcrPath:emu.videoPath()
                ]
            ]
        } else {
            renderCFG[hcrOutputsInfo] = [
                [
                    hcrOutputType:hcrGIF,
                    hcrPath:emu.animatedGifPathInHD(false, forSharing: true)
                ]
            ]
        }
        
        // Init the renderer with render CFG and check for setup errors.
        let uuid = NSUUID().UUIDString
        let info = [
            emkEmuticonOID:emu.oid!,
            emkEmuticonDefOID:emuDef.oid!,
            emkEmuticonDefName:emuDef.name!,
            hcrUUID:uuid
        ] as [NSObject:AnyObject]

        let renderer = HCRender(configurationInfo: renderCFG, userInfo: info)
        renderer.uuid = uuid
        renderer.outputProgressNotifications = true
        renderer.setup()
        if renderer.error != nil {
            return nil
        }
        
        // Send for rendering
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) { () -> Void in
            renderer.process()
        }
        
        return renderer
    }
    
    /**
    Will send emu def for rendering a preview (usually used in recorders or footage selection to display recording results)
    Will not use the rendering queue - will dispatch the work on the global queue in high priority
    
    - parameter emuDefOID:   The oid of the emu definition
    - parameter captureInfo: Dictionary with info about the captured user
    */
    func renderPreviewForEmuDefOID(
        emuDefOID : String,
        footagesForPreview: [FootageProtocol],
        slotIndex: Int = 0,
        keepResultAtPath: String? = nil
        ) -> HCRender? {
        
        // Must have an emu definition and all resources must exist on local storage
        let emuDef = EmuticonDef.findWithID(emuDefOID, context: EMDB.sh().context)
        if emuDef == nil {return nil}
        let previewAsFullRender = emuDef.fullRenderCFG != nil
        if previewAsFullRender {
            // All full render resources must be available.
            guard emuDef.allFullRenderResourcesAvailable() else {return nil}
        } else {
            // All old style emu resources must be available.
            guard emuDef.allResourcesAvailable() else {return nil}
        }

        
        // Create CFG for renderer
        let uuid = NSUUID().UUIDString
        let fps = self.fpsForEmuDef(emuDef, renderType: EMRenderType.CapturePreview)
        
        let cfg = emuDef.hcRenderCFGWithFootages(
            footagesForPreview,
            oldStyle: !previewAsFullRender,
            inHD: false,
            fps: fps
        )
        
        // Video output
        var videoOutputInfo = [
            hcrOutputType:hcrVideo,
            hcrRelativePath:"tmp_preview_\(uuid).mov"
            ] as [NSObject:AnyObject]
        
        // Stitch audio to the output if required
        if let fullRenderCFG = emuDef.fullRenderCFG as? [NSObject:AnyObject] {
            if let stitchAudioNamed = fullRenderCFG["stitched_audio_named"] as? String {
                videoOutputInfo[hcrAudioNamed] = stitchAudioNamed
            }
            if let stichedAudioRelativePath = fullRenderCFG["stitched_audio"] as? String {
                if let audioURL = emuDef.stichedAudioURLForRelativePath(stichedAudioRelativePath) {
                    videoOutputInfo[hcrAudioURL] = audioURL
                }
            }
        }
        
        // Set the output
        cfg[hcrOutputsInfo] = [videoOutputInfo]
        AppManagement.sh().debugDict(cfg as [NSObject:AnyObject])
        
        // Render creation
        var previewInfo = [emkUUID:uuid, emkEmuticonDefOID:emuDefOID] as [NSObject:AnyObject]
        let renderer = HCRender(configurationInfo: cfg as [NSObject:AnyObject], userInfo: [emkEmuticonDefOID:emuDefOID,"uuid":uuid])
        renderer.uuid = uuid
        renderer.outputProgressNotifications = true
        
        // Dispatch the async work.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            renderer.setup()
            if (renderer.error == nil) {
                // Render
                renderer.process()
                var url = renderer.outputURL()
                
                // If requested to keep the result, copy the file to the emus video path.
                if keepResultAtPath != nil {
                    let fm = NSFileManager.defaultManager()
                    do {try fm.removeItemAtPath(keepResultAtPath!)} catch {}
                    do {
                        try fm.moveItemAtPath(url.path!, toPath: keepResultAtPath!)
                        url = NSURL(fileURLWithPath: keepResultAtPath!)
                    } catch {}
                }
                
                // Finished render
                previewInfo[emkURL] = url

            } else {
                // Configuration error for render
                previewInfo[emkError] = renderer.error
            }
            
            // Notify main thread about render success/failure
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let nc = NSNotificationCenter.defaultCenter()
                nc.postNotificationName(
                    hmkRenderingFinishedPreview,
                    object: nil,
                    userInfo: previewInfo
                )
            })
        }
        return renderer
    }
    
    func footagesForPreviewWithTempUserFootage(tempUserFootage: UserTempFootage, emuDef: EmuticonDef, slotIndex: Int = 0) -> [FootageProtocol] {
        var footages = [FootageProtocol]()
        if slotIndex > 0 && emuDef.isJointEmu() {

            for i in 1...emuDef.jointEmuDefSlotsCount() {
                if i == slotIndex {
                    // Show the temp footage in this slot index
                    footages.append(tempUserFootage)
                } else {
                    footages.append(PlaceHolderFootage())
                }
            }
            
        } else {
            footages = [tempUserFootage]
        }
        return footages;
    }
    
    func oidForEmu(emu:Emuticon, renderType:EMRenderType) -> String {
        switch renderType {
        case EMRenderType.ShortLowDefPreview:
            return emu.oid!
        case EMRenderType.CapturePreview:
            return "\(emu.oid)_cp"
        case EMRenderType.FullLowDef:
            return "\(emu.oid)_fld"
        case EMRenderType.FullHighDef:
            return "\(emu.oid)_fhd"
        }
    }
    
    func inHDForRenderType(renderType:EMRenderType) -> Bool {
        return renderType == EMRenderType.FullHighDef
    }
    
    func fpsForEmuDef(emuDef:EmuticonDef, renderType:EMRenderType) -> Int {
        let fps = emuDef.fps()
        return fps
        
        // -----------------------------------------------------------
        // Render preview in lower fps NOT IMPLEMENTED
        // -----------------------------------------------------------
        // Animations in emu are stored in db based on frames and not time
        // The SDK supports rendering the same content in different FPS
        // only when animation data is provided based on some time units.
        // So only when emu's data will be converted to be time based, it will be possible
        // to render preview gifs in the main feed with lower FPS and render the full result in the 
        // details screen.
        
        //        switch renderType {
        //            case EMRenderType.ShortLowDefPreview:
        //                return EMRenderManager3.FPS_LD_SHORT_PREVIEW
        //            case EMRenderType.CapturePreview:
        //                return EMRenderManager3.FPS_CAPTURE_PREVIEW
        //            case EMRenderType.FullLowDef:
        //                return fps!
        //            case EMRenderType.FullHighDef:
        //                return fps!
        //        }
    }
    
    
    //
    // MARK: - Managing rendering queues
    //
    
    /**
    Enqueue an emu render of a specific render type.
    
    - parameter emu:        Emuticon - The emu to render
    - parameter renderType: EMRenderType - The render type
    - parameter userInfo:   Dictionary with extra optional info about this render
    */
    func enqueueEmu(
        emu: Emuticon,
        renderType: EMRenderType,
        mediaType: EMMediaDataType,
        fullRender: Bool,
        userInfo: [NSObject:AnyObject],
        oldStyle: Bool = true) {
            if let emuDef = emu.emuDef {
                #if DEBUG
                    NSAssert(NSThread.isMainThread(), "%s should be called on the main thread", __PRETTY_FUNCTION__);
                #endif
                if !emuDef.allResourcesAvailable() {return}
                
                //
                // If already rendering or enqueued, ignore.
                //
                if emu.oid == nil {return}
                let oid = self.oidForEmu(emu, renderType: renderType)
                if self.renderingPOOL[oid] != nil || self.readyPool[oid] != nil {
                    return
                }
                
                // HD or LD?
                let inHD = false // for now HD is turned off. self.inHDForRenderType(renderType)
                
                // fps
                let fps = self.fpsForEmuDef(emuDef, renderType: renderType)
                
                // Info
                let emuDefOID = emuDef.oid!
                let emuOID = emu.oid!
                
                // Preffered footage
                let footages = emu.relatedFootages() as [AnyObject]
                
                //
                // If not all resources available, we can't render.
                // It is not the responsibility of the render manager
                // to manage fetching these resources.
                // Just ignore this enqueue request.
                if !emuDef.allResourcesAvailableInHD(inHD) {return}
                
                //
                // We should and can render this emu.
                // Enqueue it for rendering with all required information.
                
                // Source CFG
                var renderCFG = emuDef.hcRenderCFGWithFootages(
                    footages,
                    oldStyle: true,
                    inHD: false,
                    fps: fps) as [NSObject:AnyObject]
                
                // Output CFG
                var outputsInfo = [NSObject]()
                if (mediaType == EMMediaDataType.Video) {
                    // Output Video
                    outputsInfo.append([
                        hcrOutputType:hcrVideo,
                        hcrPath:emu.videoPath()])
                } else {
                    // Output GIF
                    var gifOutputCFG = [
                        hcrOutputType:hcrGIF,
                        hcrPath:emu.animatedGifPathInHD(inHD)
                    ]
                    if let palette = emuDef.palette {
                        gifOutputCFG[hcrPalette] = palette
                    }
                    outputsInfo.append(gifOutputCFG)
                }
                
                if (renderType == EMRenderType.ShortLowDefPreview) {
                    // Thumb images
                    outputsInfo.append([
                        hcrOutputType:hcrPNG,
                        hcrPath:emu.thumbPath(),
                        hcrFrame:0])
                }
                renderCFG[hcrOutputsInfo] = outputsInfo
                
                // Add extra meta info to the render CFG
                renderCFG[emkEmuticonDefOID] = emuDefOID
                renderCFG[emkEmuticonOID] = emuOID
                
                dispatch_async(self.renderingManagementQueue, {
                    self.readyPool[oid] = renderCFG
                    self.userInfo[oid] = userInfo
                    self._manageQueue()
                })
            }
    }
    
    //
    // MARK: Rendering queue management and comitting rendering jobs
    //
    func _manageQueue() {
        //
        // Check if have something to render and can render it now.
        //
        if self.readyPool.count == 0 ||
            self.renderingPOOL.count > self.maxConcurrentRenders {
                return
        }
        
        //
        // Pick next thing to render.
        //
        let chosenOID = self._chooseOID()
        if chosenOID == nil {return}
        let oid = chosenOID!
        
        // Get render info from the ready pool and start rendering in the background
        guard let renderInfo = self.readyPool[oid] as? [NSObject:AnyObject] else {
            // Handle no render info available.
            return
        }
        
        let userInfo = self.userInfo[oid] as? [NSObject:AnyObject]
        
//        guard let userInfo = self.userInfo[oid] as? [NSObject:AnyObject] else {
//            // Handle no user info available.
//            return
//        }
        
        self.renderingPOOL[oid] = renderInfo;
        self.readyPool.removeValueForKey(oid)
            
        //
        // Render it async on render queue.
        //
        dispatch_async(self.renderingQueue, {
            //
            // Rendering
            //
            AppManagement.sh().debugDict(renderInfo)
            let renderer = HCRender(configurationInfo: renderInfo, userInfo: userInfo)
            renderer.setup()
            if renderer.error != nil {
                //
                // Rendering setup error
                //
                
                // TODO: Handle errors
                NSLog("Error on renderer setup \(renderer.error.description)")
            }
            renderer.processWithInfo(userInfo)
            
            //
            // Finishing rendering
            //
            
            // Rendering management queue
            dispatch_async(self.renderingManagementQueue, {
                self.renderingPOOL.removeValueForKey(oid)
                self.userInfo.removeValueForKey(oid)
                self._manageQueue()
                
                // App level operations and notifications on the main thread
                dispatch_async(dispatch_get_main_queue(), {
                    self.handleFinishedRenderOnMainThread(oid, renderInfo: renderInfo, userInfo: userInfo)
                })
            })
        })
    }
    
    func _chooseOID() -> String? {
        // If nothing is waiting for rendering, ignore.
        if self.readyPool.isEmpty {return nil}
        
        // Iterate and choose the first oid.
        // but skip oids that are already rendering.
        // (don't send same emu for rendering more than once in parallel)
        for oid in self.readyPool.keys {
            if self.renderingPOOL[oid] == nil {return oid}
        }
        
        // Nothing found that can be sent for rendering.
        return nil
    }
    
    func handleFinishedRenderOnMainThread(oid: String, renderInfo: [NSObject: AnyObject], userInfo: [NSObject: AnyObject]?) {
        #if DEBUG
            NSAssert(NSThread.isMainThread(), "%s should be called on the main thread", __PRETTY_FUNCTION__);
        #endif
        
        let emuOID = renderInfo[emkEmuticonOID] as! String
        if let emu = Emuticon.findWithID(emuOID, context: EMDB.sh().context) {
            let inHD = renderInfo[emkRenderInHD]?.boolValue
            let renderType = renderInfo[emkRenderType]?.integerValue
            if inHD == true {
                emu.wasRenderedInHD = true
            } else {
                emu.wasRendered = true
                
                // Count previews
                if renderType == EMRenderType.ShortLowDefPreview.rawValue {
                    if let count = emu.rendersCount?.integerValue {
                        emu.rendersCount = count + 1
                    } else {
                        emu.rendersCount = 1
                    }
                }
            }
            EMDB.sh().save()
            
            // Post notification to the UI
            let nc = NSNotificationCenter.defaultCenter()
            nc.postNotificationName(hmkRenderingFinished, object: self, userInfo: userInfo)
        }
        
    }
    
    
    func renderGifForFootage(footage:UserFootage, onFinish:(success: Bool)->()) {
        let width = footage.isHD() ? 480:240
        let height = footage.isHD() ? 480:240
        let gifPath = footage.pathToUserGif()
        let thumbPath = footage.pathToUserThumb()
        let oid = footage.oid
        let duration = footage.duration!.doubleValue
        
        // The cfg for converting video sequence to gif.
        // 12 FPS and max 4 seconds
        // Also creates a thumb image.
        let cfg = [
            hcrWidth:width,
            hcrHeight:height,
            hcrFPS:12,
            hcrDuration:min(duration, 4.0),
            hcrSourceLayersInfo:[
                [
                    hcrSourceType:hcrVideo,
                    hcrPath:footage.pathToUserVideo(),
                    hcrDynamicMaskPath:footage.pathToUserDMaskVideo()
                ]
            ],
            hcrOutputsInfo:[
                [
                    hcrOutputType:hcrGIF,
                    hcrPath:gifPath
                ],
                [
                    hcrOutputType:hcrPNG,
                    hcrPath:thumbPath
                ]
            ]
            ] as [NSObject:AnyObject]
        
        let renderer = HCRender(configurationInfo: cfg, userInfo: nil)
        renderer.setup()
        if (renderer.error != nil) {
            onFinish(success: false)
            return
        }
        
        // Render one by one serially in the background
        dispatch_async(self.renderingQueue) {
            // Render the gif
            renderer.process()
            dispatch_async(dispatch_get_main_queue(), {
                // Update footage object that gif exists.
                let footage = UserFootage.findWithID(oid, context: EMDB.sh().context)
                footage.gifAvailable = true
                footage.framesCount = 24
                EMDB.sh().save()
                onFinish(success: true)
            })
        }
    }
}


