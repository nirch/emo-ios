//
//  EmusVC.swift
//  emu
//
//  Created by Aviv Wolf on 29/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

import UIKit

class EmusVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Outlets
    @IBOutlet weak var guiEmusCollection: UICollectionView!
    @IBOutlet weak var guiPrevContainer: UIView!
    @IBOutlet weak var guiNextContainer: UIView!

    // Delegate
    weak var delegate: EmuSelectionProtocol?
    
    // Emu def
    var emuDef: EmuticonDef?
    var emus: [Emuticon]?
    
    // Emuticon def oid
    var emuDefOID: String?
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //
    // MARK: - Lifecycle
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        self.guiEmusCollection.alpha = 0
        self.guiNextContainer.alpha = 0
        self.guiPrevContainer.alpha = 0
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.initGUI()
        self.refreshCarouselButtons()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    //
    // MARK: - Initializations
    //
    func initGUI() {
        self.guiNextContainer.backgroundColor = UIColor.clearColor()
        self.guiPrevContainer.backgroundColor = UIColor.clearColor()
    }
    
    //
    // MARK: - collection view
    //
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.delegate?.emuPressed(self.currentEmu())
    }
    
    
    //
    // MARK: - Scroll view
    //
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        self.emuSelectionChanged()
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false {
            self.emuSelectionChanged()
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        self.delegate?.emuSelectionScrolled()
    }
    
    //
    // MARK: - Carousel buttons and emu selection
    //
    func refreshCarouselButtons() {
        guard let emuDef = self.emuDef else {return}
        guard emuDef.isJointEmu() && self.emus != nil && self.emus!.count > 0 else {
            self.guiNextContainer.alpha = 0
            self.guiPrevContainer.alpha = 0
            return
        }
        let emusCount = self.emus!.count
        
        UIView.animateWithDuration(0.2, animations: {
            self.guiNextContainer.alpha = (self.emuIndex() < emusCount) ? 1:0
            self.guiPrevContainer.alpha = (self.emuIndex() > 0) ? 1:0
        })
    }
    
    func emuSelectionChanged() {
        self.refreshCarouselButtons()
        self.delegate?.emuSelected(self.currentEmu())
        if let emu = self.currentEmu() {
            emu.gainFocus()
        }
    }
    
    func emuIndex() -> Int {
        if let collection = self.guiEmusCollection {
            if let indexPath = collection.indexPathForItemAtPoint(collection.contentOffset) {
                return indexPath.item
            }
        }
        return 0
    }
    
    func scrollToNext() {
        let next = self.emuIndex() + 1
        if (next < (self.emus!.count+1)) {
            let indexPath = NSIndexPath(forItem: next, inSection: 0)
            UIView.animateWithDuration(0.2, animations: {
                self.guiEmusCollection.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally, animated: false)
            }, completion: {
                    finished in
                self.emuSelectionChanged()
            })
        }
    }
    
    func scrollToPrevious() {
        let prev = self.emuIndex() - 1
        if (prev >= 0) {
            let indexPath = NSIndexPath(forItem: prev, inSection: 0)
            UIView.animateWithDuration(0.2, animations: {
                self.guiEmusCollection.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally, animated: false)
                }, completion: {
                    finished in
                    self.emuSelectionChanged()
            })
        }
    }
    
    func currentEmu() -> Emuticon? {
        if self.emus == nil {return nil}
        let index = self.emuIndex()
        if index < self.emus?.count && index >= 0 {
            return self.emus![index]
        }
        return nil
    }
    
    //
    // MARK: - Joint emu
    //
    
    //
    // MARK: - CV DataSource
    //
    func refresh() {
        self.emuDef = EmuticonDef.findWithID(self.emuDefOID, context: EMDB.sh().context)
        guard let emuDef = self.emuDef else {
            self.emus = nil
            return
        }
        
        let sortBy = [NSSortDescriptor(key: "timeCreated", ascending: true)]
        self.emus = emuDef.emusOrdered(sortBy) as? [Emuticon]
        
        guard let collection = self.guiEmusCollection else {return}
        
        collection.reloadData()
        self.refreshCarouselButtons()

        // Scroll to
        let indexPathInFocus = self.indexPathOfEmuInFocus()
        collection.scrollToItemAtIndexPath(
            indexPathInFocus,
            atScrollPosition: .CenteredHorizontally,
            animated: false)
        
        if collection.alpha == 0 {
            UIView.animateWithDuration(0.2, animations: {
                collection.alpha = 1
            })
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let emuDef = self.emuDef {
            // If not joint emu, allow only a single emu instance for this emu def.
            if !emuDef.isJointEmu() {
                return 1
            }
            
            // A joint emu. Allow adding multiple emus to the same emu def.
            if let emus = self.emus {
                return emus.count+1
            }
        }
        
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("emu instance cell", forIndexPath: indexPath) as! EMEmuCell
        cell.inUI = "emuVC"
        
        if let emus = self.emus {
            let index = indexPath.item
            if index < emus.count {
                let emu = emus[indexPath.item]
                self.handleVisibleEmu(emu)
                cell.updateStateWithEmu(emu, forIndexPath: indexPath)
                cell.updateGUI()
            } else {
                cell.updateStateToPlaceHolder()
                cell.updateGUI()
            }
        }
        return cell
    }
    
    func indexPathOfEmuInFocus() -> NSIndexPath {
        guard let emus = self.emus else {
            return NSIndexPath(forItem: 0, inSection: 0)
        }
        
        var index = 0
        for emu in emus {
            if emu.inFocus != nil && emu.inFocus!.boolValue == true {
                return NSIndexPath(forItem: index, inSection: 0)
            }
            index += 1
        }
        
        return NSIndexPath(forItem: 0, inSection: 0)
    }
    
    //
    // MARK: - Layout
    //
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.guiEmusCollection.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let size = self.guiEmusCollection.bounds.size
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
    
    //
    // MARK: - Show/Hide content
    //
    func seeThroughAnimated(animated animated: Bool = false) {
        guard let cell = self.guiEmusCollection.visibleCells().first else {return}
        if (animated) {
            UIView.animateWithDuration(0.3, animations: {
                cell.alpha = 0
            })
        } else {
            cell.alpha = 0
        }
    }
    
    func opaqueAnimated(animated animated: Bool = false) {
        guard let cell = self.guiEmusCollection.visibleCells().first else {return}
        if (animated) {
            UIView.animateWithDuration(0.3, animations: {
                cell.alpha = 1
            })
        } else {
            cell.alpha = 1
        }
    }
    
    //
    // MARK: - Downloads
    //
    func handleVisibleEmu(emu: Emuticon) {
        let info = [
            emkEmuticonOID:emu.oid!,
            emkPackageOID:emu.emuDef!.oid!,
            emkDLTaskType:emkDLTaskTypeFootages
        ] as [NSObject: AnyObject]

        emu.enqueueIfMissingResourcesWithInfo(info)
        emu.enqueueMissingRemoteFootageFilesWithInfo(info)
    }
    
    // MARK: - IB Actions
    // ===========
    // IB Actions.
    // ===========
    @IBAction func onPressedPrevEmuButton(sender: AnyObject) {
        self.scrollToPrevious()
    }
    
    @IBAction func onPressedNextEmuButton(sender: AnyObject) {
        self.scrollToNext()
    }
}
