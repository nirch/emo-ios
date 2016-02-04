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
                // For receiver, show the invitation status.
                return 1
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
    case Declined
    case FootageDownloading
    case FootageAvailable
    
    func color() -> UIColor {
        switch self {
            
        case .Neutral:
            return UIColor.grayColor()
            
        case .InvitationSent:
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
            
        case .InvitationSent:
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
            if emu.isJointEmuInitiatorAtSlot(slotIndex) && emu.isJointEmuInitiatedByThisUser() {
                self.footage = emu.mostPrefferedUserFootage()
                self.cellState = .FootageAvailable
                self.text = "YOU"
            } else {
                let state = emu.jointEmuStateOfSlot(slotIndex)
                switch state {
                case .Invited:
                    self.cellState = .InvitationSent
                    self.text = EML.s("INVITED")
                default:
                    self.cellState = .Neutral
                    self.text = nil
                }
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
        if let i = self.guiThumb {
            i.clipsToBounds = true
            i.layer.cornerRadius = i.layer.bounds.width/2.0
            i.layer.borderWidth = self.isCellSelected ? 5.0:1.0
            i.layer.borderColor = self.cellState.color().CGColor
            i.layer.shadowColor = self.isCellSelected ? UIColor.grayColor().CGColor:UIColor.clearColor().CGColor
            i.layer.shadowOpacity = 0.8
            i.layer.shadowRadius = 4.0
        }
        
        self.updateLabel();
        self.updateImage();
    }
    
    func updateLabel() {
        self.guiLabel.textColor = self.cellState.color()
        self.guiLabel.text = self.text
    }
    
    func updateImage() {
        var imageURL: NSURL?
        
        if self.cellState == .FootageAvailable {
            imageURL = self.footage?.urlToThumbImage()
        }

        // Set the image
        if imageURL != nil {
            self.guiThumb.pin_setImageFromURL(imageURL, placeholderImage: SlotCell.placeholderImage)
        } else {
            self.guiThumb.image = SlotCell.placeholderImage
        }
    }
}
