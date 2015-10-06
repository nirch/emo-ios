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
    EMEmuCellStateReady             = 30
};


/**
 *  Update and process the state of the cell using info of an emu object.
 */
-(void)updateStateWithEmu:(Emuticon *)emu forIndexPath:(NSIndexPath *)indexPath;

/**
 *  Update the GUI elements according to the cell's current state.
 */
-(void)updateGUI;

@end
