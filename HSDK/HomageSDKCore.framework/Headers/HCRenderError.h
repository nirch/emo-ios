//
//  HCRenderError.h
//  HomageSDKCore
//
//  Created by Aviv Wolf on 15/11/2015.
//  Copyright © 2015 Homage LTD. All rights reserved.
//

#import "HCError.h"

extern NSString* const hckErrorDomainRender;

/**
 *  hckRenderError - Render and render configuration errors.
 */
typedef NS_ENUM(NSInteger, hckRenderError) {
    /**
     *  Render engine requires at least a single source layer to be configured.
     */
    hckRenderErrorMissingLayers                 = 1000,
    
    /**
     *  Each source layer must indicate a valid type.
     *  Source type can be a static media type (gif, png, jpg, video etc).
     *  or some kind of "on the fly" generated source (dynamic texts, solid color, gradient etc).
     *  This error is raised if no media type provided or an invalid media type provided.
     */
    hckRenderErrorInvalidSourceType             = 2000,
    
    /**
     *  Render engine requires at least a single output to be configured.
     */
    hckRenderErrorMissingOutputs                = 3000,
    
    /**
     *  Render engine requires that the outputs info be provided as an array of outputs configs.
     *  The array of outputs info must provide at least one output configuration item.
     */
    hckRenderErrorOutputsMustBeAnArray          = 3001,
    
    /**
     *  A required file is missing at provided path.
     */
    hckRenderErrorMissingFileAtPath             = 4000,
    
    /**
     *  Provided path is nil.
     */
    hckRenderErrorPathIsNil                     = 4001,
    
    /**
     *  The process method was called while the renderer was in bad state.
     *  Bad state can happen when:
     *      - The setup method was not called before calling process.
     *      - The setup method was called, but setup encountered a configuration error.
     */
    hckRenderErrorBadState                      = 5000,
    
    /**
        Missing configuration parameters when configuring an output.
        Required parameters are (for animated outputs.:
        - hcrFPS (**fps**): frames per second for the result.
     */
    hckRenderErrorMissingRequiredOutputParams   = 6000,
};

/**
 *  HCError subclass, representing configuration and process errors of the render engine.
 */
@interface HCRenderError : HCError

@end
