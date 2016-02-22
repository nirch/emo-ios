//
//  EMSharingOptionsVC.swift
//  emu
//
//  Created by Aviv Wolf on 21/02/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

class EMSharingOptionsVC:
    UIViewController,
    iCarouselDataSource,
    iCarouselDelegate,
    EMShareDelegate,
    EMShareInputDelegate {

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    //
    // Constants
    //
    static let emkUIActionShareMethodChanged = "emk ui action share method changed"
    static let emkUIActionShare = "emk ui action share"
    static let emkUIActionShareDone = "emk ui action share done"
    static let emkShareMethod = "emk share method"
    static let emkShareButtonTitle = "emk share button title"
    static let emkShareButtonColor = "emk share button color"
    
    //
    // Outlets
    //
    @IBOutlet weak var guiCarousel: iCarousel!

    // Delegate
    weak var delegate: EMInterfaceDelegate?
    
    // Share options
    var shareNames: [EMKShareMethod: String] = [EMKShareMethod: String]()
    var shareMethods: [EMKShareMethod] = [EMKShareMethod]()
    var colorsByShareMethod: [EMKShareMethod: UIColor] = [EMKShareMethod: UIColor]()
    var buttonFrame: CGRect = CGRectMake(0, 0, 130, 130)

    var currentShareMethod: EMKShareMethod = EMKShareMethod.emkShareMethodFacebookMessanger
    var prefferedMediaType: EMKShareOption = EMKShareOption.emkShareOptionAnimatedGif
    
    // Sharer
    var sharer: EMShare?
    
    // Emu to share
    var emuToShare: Emuticon?
    
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //
    // MARK: - Lifecycle
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideCarousel()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.initData()
        self.initGUI()
        self.update()
    }

    //
    // MARK: - GUI Initializations
    //
    func initGUI() {
        self.guiCarousel.type = iCarouselType.Rotary
        self.guiCarousel.dataSource = self
        self.guiCarousel.delegate = self
    }

    //
    // MARK: - Data
    //
    func initData() {
        self.shareNames = [
            .emkShareMethodFacebookMessanger:     "facebookm",
            .emkShareMethodTwitter:               "twitter",
            .emkShareMethodFacebook:              "facebook",
            .emkShareMethodAppleMessages:         "iMessage",
            .emkShareMethodWhatsapp:              "whatsapp",
            .emkShareMethodMail:                  "mail",
            .emkShareMethodSaveToCameraRoll:      "savetocm",
            .emkShareMethodCopy:                  "copy",
            .emkShareMethodDocumentInteraction:   "sharemisc",
            .emkShareMethodInstagram:             "instagram"
        ]
        
        self.colorsByShareMethod = [
            .emkShareMethodFacebookMessanger:     EmuStyle.colorShareFBMBG(),
            .emkShareMethodTwitter:               EmuStyle.colorShareTwitterBG(),
            .emkShareMethodFacebook:              EmuStyle.colorShareFBBG(),
            .emkShareMethodAppleMessages:         EmuStyle.colorShareAPMBG(),
            .emkShareMethodWhatsapp:              EmuStyle.colorShareWhatsAppBG(),
            .emkShareMethodMail:                  EmuStyle.colorShareMailBG(),
            .emkShareMethodSaveToCameraRoll:      EmuStyle.colorShareSaveBG(),
            .emkShareMethodCopy:                  EmuStyle.colorShareCopyBG(),
            .emkShareMethodDocumentInteraction:   EmuStyle.colorShareMiscBG(),
            .emkShareMethodInstagram:             EmuStyle.colorShareInstagramBG()
        ]
        
        if self.prefferedMediaType == EMKShareOption.emkShareOptionAnimatedGif {
            self.shareMethods = [
                .emkShareMethodFacebookMessanger,
                .emkShareMethodAppleMessages,
                .emkShareMethodFacebook,
                .emkShareMethodTwitter,
                .emkShareMethodMail,
                .emkShareMethodSaveToCameraRoll,
                .emkShareMethodCopy
            ]
        } else {
            self.shareMethods = [
                .emkShareMethodFacebookMessanger,
                .emkShareMethodAppleMessages,
                .emkShareMethodDocumentInteraction,
                .emkShareMethodInstagram,
                .emkShareMethodMail,
                .emkShareMethodSaveToCameraRoll,
                .emkShareMethodCopy,
            ]
        }
        
    }
    
    func update() {
        let appCFG = AppCFG.cfgInContext(EMDB.sh().context)
        self.prefferedMediaType = appCFG.userPrefferedShareType == 1 ? EMKShareOption.emkShareOptionVideo : EMKShareOption.emkShareOptionAnimatedGif
        self.initData()
        self.guiCarousel.reloadData()
        self.updateToShareMethod(self.currentShareMethod, forcedUpdate: true)
        self.showCarousel(animated: true)
    }
    
    func showCarousel(animated animated: Bool = false) {
        if animated {
            UIView.animateWithDuration(0.3, animations: {
                self.showCarousel()
            })
            return
        }
        self.guiCarousel.alpha = 1
        self.guiCarousel.userInteractionEnabled = true
    }
    
    func hideCarousel(animated animated: Bool = false) {
        if animated {
            UIView.animateWithDuration(0.3, animations: {
                self.hideCarousel()
            })
            return
        }
        self.guiCarousel.alpha = 0
    }
    
    //
    // MARK: - iCarouselDataSource
    //
    func numberOfItemsInCarousel(carousel: iCarousel) -> Int {
        return self.shareMethods.count
    }
    
    func carousel(carousel: iCarousel, viewForItemAtIndex index: Int, var reusingView view: UIView?) -> UIView {
        if view == nil {
            let optionButton = ShareOption(frame: self.buttonFrame)
            view = optionButton
        }
        
        if let sb = view as? ShareOption {
            let shareMethod = self.shareMethods[index % self.shareMethods.count]
            sb.shareMethod = shareMethod
            sb.shareName = self.shareNames[shareMethod]
            sb.updateGUI()
        }
        
        return view!
    }
    
    
    //
    // MARK: - iCarouselDelegate (Layer types carousel)
    //
    func carousel(carousel: iCarousel, valueForOption option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        switch option {
        case iCarouselOption.Spacing:
            return 2.5
        case iCarouselOption.FadeMax:
            return 0.5
        case iCarouselOption.FadeMin:
            return -0.5
        case iCarouselOption.FadeRange:
            return 3.14
        case iCarouselOption.ShowBackfaces:
            return 1
            
        default:
            return value
        }
    }
    
    func carouselCurrentItemIndexDidChange(carousel: iCarousel) {
        let shareMethod = self.shareMethods[carousel.currentItemIndex]
        self.updateToShareMethod(shareMethod)
    }
    
    func carousel(carousel: iCarousel, didSelectItemAtIndex index: Int) {
        guard carousel.currentItemIndex == index else {return}
        guard let view = carousel.itemViewAtIndex(index) else {return}

        EMUISound.sh().playSoundNamed(SND_POP)
        carousel.userInteractionEnabled = false
        view.animateQuickPopIn()
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            self.delegate?.controlSentActionNamed(EMSharingOptionsVC.emkUIActionShare, info: nil)
        }
    }
    
    //
    // MARK: - Share types
    //
    func updateToShareMethod(updateToShareMethod: EMKShareMethod, forcedUpdate: Bool = false) {
        if forcedUpdate == false && self.currentShareMethod == updateToShareMethod {return}

        let shareMethod = updateToShareMethod
        let mediaType = self.prefferedMediaType

        // Update the share method to the new one.
        self.currentShareMethod = shareMethod
        
        // Set the title and the color
        let title = self.titleByShareMethod(shareMethod, mediaType: mediaType)
        guard let color = self.colorsByShareMethod[shareMethod] else {return}
        
        // Updaet the delegate about the change so it will reflect in the UI.
        self.delegate?.controlSentActionNamed(
            EMSharingOptionsVC.emkUIActionShareMethodChanged,
            info: [
                EMSharingOptionsVC.emkShareButtonTitle: title,
                EMSharingOptionsVC.emkShareButtonColor: color
            ])
    }
    
    func titleByShareMethod(shareMethod: EMKShareMethod, mediaType: EMKShareOption) -> String {
        var title = ""
        switch shareMethod {
        case .emkShareMethodSaveToCameraRoll:
            title = EML.s("SAVE")
        case .emkShareMethodCopy:
            title = EML.s("COPY")
        default:
            title = EML.s("SHARE")
        }
        
        if mediaType == EMKShareOption.emkShareOptionVideo {
            title = "\(title) \(EML.s("VIDEO"))"
        } else {
            title = "\(title) \(EML.s("GIF"))"
        }
        return title.uppercaseStringWithLocale(NSLocale.currentLocale())
    }
    
    //
    // MARK: - Sharing an emu
    //
    func shareCurrentEmu(forcedShareMethod: EMKShareMethod? = nil) {
        if forcedShareMethod != nil {self.currentShareMethod = forcedShareMethod!}
        guard let emuToShare = self.emuToShare else {return}
        guard let emuDef = emuToShare.emuDef else {return}
        guard let package = emuDef.package else {return}
        let shareMethod = self.currentShareMethod

        // Hide the UI
        self.hideCarousel(animated: true)
        
        // Share the emu
        self.sharer = EMShareFactory.sharerForShareMethod(shareMethod)
        guard let sharer = self.sharer else {return}
        
        //
        // Set info for the sharer object
        //
        let shareMethodName = self.shareNames[shareMethod]!
        
        let extraCFG = HMParams()
        extraCFG.addKey("icon", valueIfNotNil: UIImage(named: shareMethodName))
        
        if let defaultHashTags = package.sharingHashTagsStringForShareMethodNamed(shareMethodName) {
            extraCFG.addKey("sharingHashTags", valueIfNotNil: defaultHashTags)
        }
        
        if let titleColor = self.colorsByShareMethod[shareMethod] {
            extraCFG.addKey("titleColor", valueIfNotNil: titleColor)
        }
        
//        self.sharer.info = shareInfo;
        sharer.extraCFG = NSMutableDictionary(dictionary: extraCFG.dictionary)
        sharer.objectToShare = emuToShare
        sharer.delegate = self;
        sharer.viewController = self;
        sharer.view = self.view;
        sharer.shareOption = self.prefferedMediaType
        self._shareEmuUsingCurrentSharer()
    }
    
    func _shareEmuUsingCurrentSharer() {
        guard let sharer = self.sharer else {return}
        guard sharer.objectToShare.isKindOfClass(Emuticon) else {return}
        guard let emuToShare = self.emuToShare else {return}

        //
        // First, check if need to create video for this share.
        //
        if self.sharer?.shareOption == .emkShareOptionVideo {
            if emuToShare.videoURL() == nil {
                // Temp video file not created yet.
                // Render it before sharing.
                var requiresWaterMark = true
                if emuToShare.emuDef!.package!.preventVideoWaterMarks?.boolValue != nil {requiresWaterMark = false}
                if sharer.isKindOfClass(EMShareFBMessanger) {requiresWaterMark = false}
                self.renderVideoBeforeShareForEmu(emuToShare, requiresWaterMark: requiresWaterMark)
                return
            }
        }
        
        self._share()
    }
    
    func renderVideoBeforeShareForEmu(emu: Emuticon, requiresWaterMark: Bool) {
        guard emu.emuDef!.allResourcesAvailable() else {return}
        guard emu.wasRendered?.boolValue == true else {return}
        
        let info = HMParams()
        info.addKey(emkEmuticonOID, valueIfNotNil: emu.oid)
        info.addKey(emkEmuticonDefOID, valueIfNotNil: emu.emuDef?.oid)
        info.addKey(emkPackageOID, valueIfNotNil: emu.emuDef?.package?.name)
        
        EMRenderManager3.sh().renderVideoFromEmuGif(
            emu,
            loopsCount: 4)
    }
    
    func _share() {
        if self.sharer?.requiresUserInput == true {
            self._userInputBeforeSharing()
            return
        }
        
        // Just the share mam, just the share.
        self.sharer?.share()
    }
    
    func _userInputBeforeSharing() {
        guard let emu = self.emuToShare else {return}
        
        let shareInputVC = EMShareInputVC(inParentVC: self.parentViewController!)
        shareInputVC.titleColor = UIColor.redColor()
        shareInputVC.titleIcon = self.sharer?.extraCFG["icon"] as? UIImage
        
        if let thumbURL = emu.thumbURL() {
            shareInputVC.sharedMediaIcon = UIImage(contentsOfFile: thumbURL.path!)
        }
        
        // Delegation
        shareInputVC.delegate = self
        
        // Default hashtag
        shareInputVC.defaultHashTags = self.sharer?.extraCFG["sharingHashTags"] as? String
        
        // Associated color
        shareInputVC.titleColor = self.sharer?.extraCFG["titleColor"] as? UIColor

        shareInputVC.updateUI()
        shareInputVC.showAnimated(true)
    }
    
    //
    // MARK: - EMShareDelegate
    //
    func sharerDidStartLongOperation(info: [NSObject : AnyObject]!, label: String!) {
        
    }
    
    func sharerDataTypeToShare() -> EMMediaDataType {
        if self.prefferedMediaType == EMKShareOption.emkShareOptionAnimatedGif {
            return EMMediaDataType.GIF
        } else {
            return EMMediaDataType.Video
        }
    }

    func sharerDidCancelWithInfo(info: [NSObject : AnyObject]!) {
        self.update()
        self.delegate?.controlSentActionNamed(EMSharingOptionsVC.emkUIActionShareDone, info: nil)
    }
    
    func sharerDidFailWithInfo(info: [NSObject : AnyObject]!) {
        self.update()
        self.delegate?.controlSentActionNamed(EMSharingOptionsVC.emkUIActionShareDone, info: nil)
    }
    
    func sharerDidFinishWithInfo(info: [NSObject : AnyObject]!) {
    }
    
    func sharerDidProgress(progress: Float, info: [NSObject : AnyObject]!) {
        
    }
    
    func sharerDidShareObject(sharedObject: AnyObject!, withInfo info: [NSObject : AnyObject]!) {
        self.update()
        self.delegate?.controlSentActionNamed(EMSharingOptionsVC.emkUIActionShareDone, info: nil)
    }
    
    //
    // MARK: - EMShareInputDelegate
    //
    func shareInputWasCanceled() {
        self.sharer?.cleanUp()
        self.sharer = nil
        self.view.makeToast(EML.s("SHARE_TOAST_CANCELED"))
        self.update()
        self.delegate?.controlSentActionNamed(EMSharingOptionsVC.emkUIActionShareDone, info: nil)
    }
    
    func shareInputWasConfirmedWithText(text: String!) {
        self.sharer?.userInputText = text
        self.sharer?.share()
    }
}



class ShareOption: UIView {
    
    var shareMethod: EMKShareMethod?
    var shareName: String?
    weak var imageView: UIImageView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initGUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func initGUI() {
        let imageView = UIImageView(frame: self.bounds)
        self.imageView = imageView
        self.addSubview(imageView)
    }
    
    func updateGUI() {
        guard let shareName = self.shareName else {return}
        self.imageView?.image = UIImage(named: shareName)
    }
}
