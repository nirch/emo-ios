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
    var emuDefOID: String? {
        didSet {
            self.refresh()
        }
    }
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //
    // MARK: - Lifecycle
    //
    override func viewDidLoad() {
        super.viewDidLoad()
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
        self.emuSelectionChanged()
    }
    
    
    
    //
    // MARK: - Carousel buttons and emu selection
    //
    func refreshCarouselButtons() {
        if let emuDef = self.emuDef {
            if emuDef.isJointEmu() {
                UIView.animateWithDuration(0.2, animations: { () -> Void in
                    self.guiNextContainer.alpha = (self.emuIndex() > 0) ? 0:1
                    self.guiPrevContainer.alpha = (self.emuIndex() < self.emus?.count) ? 0:1
                })
            } else {
                self.guiNextContainer.alpha = 0
                self.guiPrevContainer.alpha = 0
            }
        }
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
        if self.emuDef == nil {
            self.emus = nil
        } else {
            let sortBy = [NSSortDescriptor(key: "timeCreated", ascending: true)]
            self.emus = emuDef!.emusOrdered(sortBy) as? [Emuticon]
            if let collection = self.guiEmusCollection {
                collection.reloadData()
                self.refreshCarouselButtons()
            }
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
