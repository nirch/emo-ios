//
//  SlotsVC.swift
//  emu
//
//  Created by Aviv Wolf on 02/02/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

import UIKit

protocol SlotsSelectionDelegate: class {
    func slotWasPressed(slotIndex: Int)
}

class SlotsVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Outlets
    @IBOutlet weak var guiSlotsCollection: UICollectionView!
    
    // Data
    var emu: Emuticon? {
        didSet {
            if self.guiSlotsCollection != nil {
                self.guiSlotsCollection.reloadData()
            }
        }
    }
    
    var highlightedSlot: Int = 0 {
        didSet {
            if self.guiSlotsCollection != nil {
                self.guiSlotsCollection.reloadData()
            }
        }
    }
    
    // Delegate
    weak var delegate: SlotsSelectionDelegate?
    
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.guiSlotsCollection.alpha = 0.0
    }
    
    //
    // MARK: - UICollectionViewDataSource
    //
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return count()
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("slot cell", forIndexPath: indexPath) as! SlotCell
        let slotIndex = indexPath.item + 1
        cell.updateSlotCellWithJointEmu(self.emu, slotIndex: indexPath.item+1, isSelected: slotIndex == self.highlightedSlot)
        cell.updateGUI()
        return cell
    }
    
    func count() -> Int {
        if let emu = self.emu {
            if emu.isJointEmu() == false {return 0}
            self.guiSlotsCollection.userInteractionEnabled = true
            UIView.animateWithDuration(0.7, animations: {
                self.guiSlotsCollection.alpha = 1.0
            })
            if emu.isJointEmuInitiatedByThisUser() {
                // For initiator, show remote slots.
                return emu.jointEmuSlots().count
            } else {
                // For receiver, show the initiator and local receiver.
                return 2
            }
        }
        UIView.animateWithDuration(0.7, animations: {
            self.guiSlotsCollection.alpha = 0.1
            self.guiSlotsCollection.userInteractionEnabled = false
        })
        return 1
    }
    
    //
    // MARK: - D
    //
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if self.emu == nil || self.emu!.isJointEmu() == false {return}
        let slotIndex = indexPath.item+1
        self.delegate?.slotWasPressed(slotIndex)
    }
    
    func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? SlotCell {
            cell.pop()
        }
    }
    
    //
    // MARK: - Layout
    //
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.guiSlotsCollection.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        var size = self.guiSlotsCollection.bounds.size
        let count = self.count()
        if count < 1 {return size}
        
        if count < 4 {
            size.width = size.width/CGFloat(count)
        } else {
            size.width = size.height + 20
        }
        
        return size
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
}


enum SlotCellState {
    case Neutral
    case InvitationSent
    case InvitationReceived
    case Declined
    case FootageDownloading
    case FootageAvailable
    
    func color() -> UIColor {
        switch self {
            
        case .Neutral:
            return UIColor.grayColor()
            
        case .InvitationSent:
            return EmuStyle.colorButtonBGPositive()
            
        case .InvitationReceived:
            return EmuStyle.colorButtonBGPositive()
            
        case .Declined:
            return EmuStyle.colorButtonBGNegative()
            
        case .FootageDownloading:
            return UIColor.grayColor()
            
        case .FootageAvailable:
            return EmuStyle.colorButtonBGPositive()
            
        }
    }
    
    func thumbName() -> String {
        switch self {
            
        case .InvitationSent, .InvitationReceived:
            return "placeholderPositive240.png"
            
        case .Declined:
            return "placeholderNegative240.png"
            
        case .FootageDownloading:
            return "placeholderPositive240.png"
            
        default:
            return "placeholder240.png"
            
        }
    }
    
}

class SlotCell: UICollectionViewCell {
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Outlets
    @IBOutlet weak var guiThumb: UIImageView!
    @IBOutlet weak var guiLabel: UILabel!
    @IBOutlet weak var guiActivity: UIActivityIndicatorView!
    @IBOutlet weak var guiDownloadingLabel: UILabel!

    // vars
    static let placeholderImage: UIImage = UIImage(named: "placeholder240.png")!
    
    var cellState: SlotCellState = .Neutral
    var thumbFullPath: String?
    var footage: FootageProtocol?
    var text: String?
    var isCellSelected: Bool = false
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    func updateSlotCellWithJointEmu(emuticon: Emuticon?, slotIndex: Int, isSelected: Bool = false) {
        self.footage = nil
        self.text = nil
        self.isCellSelected = isSelected
        
        if let emu = emuticon {
            if emu.isJointEmuInitiatedByThisUser() {
                self.updateSlotCellWithJointEmuForInitiatorUI(emu, slotIndex: slotIndex, isSelected: isSelected)
            } else {
                self.updateSlotCellWithJointEmuForReceiverUI(emu, slotIndex: slotIndex, isSelected: isSelected)
            }
        }
    }
    
    func updateSlotCellWithJointEmuForInitiatorUI(emu: Emuticon, slotIndex: Int, isSelected: Bool = false) {
        if emu.isJointEmuInitiatorAtSlot(slotIndex) && emu.isJointEmuInitiatedByThisUser() {
            self.footage = emu.mostPrefferedUserFootage()
            self.cellState = .FootageAvailable
            self.text = EML.s("YOU")
        } else {
            let state = emu.jointEmuStateOfSlot(slotIndex)
            switch state {
            case .Invited:
                self.cellState = .InvitationSent
                self.text = EML.s("INVITED")
            case .DeclinedByReceiver:
                self.cellState = .Declined
                self.text = EML.s("DECLINED")
            case .ReceiverUploadedFootage:
                self.footage = emu.jointEmuFootageAtSlot(slotIndex)
                self.cellState = .FootageDownloading
                self.text = ""
                if self.footage != nil && self.footage!.isAvailable() {
                    self.cellState = .FootageAvailable
                    self.text = "✓"
                }
            default:
                self.cellState = .Neutral
                self.text = nil
            }
        }
    }
    
    func updateSlotCellWithJointEmuForReceiverUI(emu: Emuticon, slotIndex: Int, isSelected: Bool = false) {
        // The receiver will show only the initiator (other slots don't matter to the receiver).
        let initiatorSlot = emu.jointEmuInitiatorSlot()
        guard initiatorSlot > 0 else {return}
        guard let invitationCode = emu.createdWithInvitationCode else {return}
        let receiverSlot = emu.jointEmuSlotForInvitationCode(invitationCode)
        guard receiverSlot > 0 else {return}
        
        self.footage = nil
        if slotIndex == 1 {
            self.footage = emu.jointEmuFootageAtSlot(initiatorSlot)
            //self.text = EML.s("JOINT_EMU_INITIATOR_NICE")
            self.text = EML.s("JOIN_ME")
        } else {
            self.footage = emu.jointEmuFootageAtSlot(receiverSlot)
            self.text = EML.s("JOINT_EMU_MY_TAKE")
        }
        if let footage = self.footage {
            if footage.isAvailable() {
                self.cellState = .FootageAvailable
            } else {
                self.cellState = .FootageDownloading
            }
        }
    }
    
    //
    // Update the UI elements
    //
    func pop() {
        self.transform = CGAffineTransformMakeScale(0.85, 0.85)
        EMUISound.sh().playSoundNamed(SND_SOFT_CLICK)
        UIView.animateWithDuration(1.0) {
            self.transform = CGAffineTransformIdentity
        }
    }
    
    func updateGUI() {
        self.guiDownloadingLabel.hidden = true
        self.guiActivity.stopAnimating()
        
        if let i = self.guiThumb {
            i.clipsToBounds = true
            i.layer.cornerRadius = i.layer.bounds.width/2.0
            i.layer.borderWidth = self.isCellSelected ? 5.0:1.0
            i.layer.borderColor = self.cellState.color().CGColor
            i.layer.shadowColor = self.isCellSelected ? UIColor.grayColor().CGColor:UIColor.clearColor().CGColor
            i.layer.shadowOpacity = 0.8
            i.layer.shadowRadius = 4.0
        }
        
        self.updateImageAndLabel();
    }
    
    func updateImageAndLabel() {
        var imageURL: NSURL?
        
        switch self.cellState {
        case .FootageAvailable:
            imageURL = self.footage?.urlToThumbImage()
        case .FootageDownloading:
            imageURL = self.footage?.urlToThumbImage()
            self.guiDownloadingLabel.text = EML.s("DOWNLOADING")
            self.guiDownloadingLabel.hidden = false
            self.guiActivity.startAnimating()
        default:
            break
        }
        
        self.guiLabel.textColor = self.cellState.color()
        self.guiLabel.text = self.text
        
        // Set the image
        if imageURL != nil {
            self.guiThumb.pin_setImageFromURL(imageURL, placeholderImage: SlotCell.placeholderImage)
        } else {
            self.guiThumb.image = SlotCell.placeholderImage
        }
    }
}
