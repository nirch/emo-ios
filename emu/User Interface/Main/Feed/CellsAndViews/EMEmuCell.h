//
//  EMEmuCell.h
//  emu
//
//  Created by Aviv Wolf on 9/28/15.
//  Copyright © 2015 Homage. All rights reserved.
//

@class Emuticon;

#import <UIKit/UIKit.h>

@interface EMEmuCell : UICollectionViewCell

@property (nonatomic) NSInteger sectionIndex;

@property (nonatomic) NSString *inUI;

/**
 *  The label of the emu (used for debugging).
 */
@property (nonatomic, readonly) NSString *label;

/**
 *  The oid of the related emu.
 */
@property (nonatomic, readonly) NSString *oid;

/**
 *  Indicates if cell is selectable or not.
 */
@property (nonatomic) BOOL selectable;


/**
 *  The state of the cell according to the related emu.
 */
typedef NS_ENUM(NSInteger, EMEmuCellState){
    /**
     *  Unset state. Calling updateGUI on this state will be ignored (and crash on test apps).
     */
    EMEmuCellStateUnset = 0,
    
    /**
     *  The remu requires rendering, but not all source resources are available
     *  the resources will need to be downloaded first, before moving to the next state.
     */
    EMEmuCellStateRequiresResources = 10,

    /**
     *  The emu requires rendering and all resources available on the device.
     *  The emu was enqueued for rendering on the rendering queue.
     */
    EMEmuCellStateSentForRendering = 20,
    
    /**
     *  The emu rendering result is available. This state indicates that the cell should display
     *  the rendered content to the user.
     */
    EMEmuCellStateReady             = 30,
    
    /**
     *  Indicates if the cell is in a "Failed" state.
     *  (emu can't be presented or processed for some reason.
     *  Failed downloads of resources / failed rendering or any other reason)
     */
    EMEmuCellStateFailed            = 40,
    
    
    /**
     *  Empty cell. Sometimes we want cells to represent "no content".
     */
    EMEmuCellStateEmpty = 666,
};

/**
 *  The state of the cell.
 *  the state detemines how this cell should be presented to the user
 *  (determines how updateGUI will configure the cell UI)
 */
@property (nonatomic, readonly) EMEmuCellState state;

/**
 *  Update and process the state of the cell using info of an emu object.
 */
-(void)updateStateWithEmu:(Emuticon *)emu forIndexPath:(NSIndexPath *)indexPath;

/**
 *  Update the cell state to failed state (emu cell will be presented with some kind of "failed" indicator).
 */
-(void)updateStateToFailed;

/**
 *  Update the cell state to empty state (emu cell will be presented as empty).
 */
-(void)updateStateToEmpty;

/**
 *  Update the GUI elements according to the cell's current state.
 */
-(void)updateGUI;

@end
