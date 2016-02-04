//
//  Emuticon+CoreDataProperties.h
//  emu
//
//  Created by Aviv Wolf on 04/02/2016.
//  Copyright © 2016 Homage. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Emuticon.h"

NS_ASSUME_NONNULL_BEGIN

@interface Emuticon (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *audioFilePath;
@property (nullable, nonatomic, retain) NSNumber *audioStartTime;
@property (nullable, nonatomic, retain) NSNumber *inFocus;
@property (nullable, nonatomic, retain) NSNumber *isFavorite;
@property (nullable, nonatomic, retain) NSNumber *isPreview;
@property (nullable, nonatomic, retain) id jointEmuInstance;
@property (nullable, nonatomic, retain) NSDate *lastTimeShared;
@property (nullable, nonatomic, retain) NSDate *lastTimeViewed;
@property (nullable, nonatomic, retain) NSString *oid;
@property (nullable, nonatomic, retain) NSString *prefferedFootageOID;
@property (nullable, nonatomic, retain) id remoteFootages;
@property (nullable, nonatomic, retain) NSNumber *renderedSampleUploaded;
@property (nullable, nonatomic, retain) NSNumber *rendersCount;
@property (nullable, nonatomic, retain) NSNumber *shouldRenderAsHDIfAvailable;
@property (nullable, nonatomic, retain) NSDate *timeCreated;
@property (nullable, nonatomic, retain) NSNumber *usageCount;
@property (nullable, nonatomic, retain) NSNumber *videoLoopsCount;
@property (nullable, nonatomic, retain) NSNumber *videoLoopsEffect;
@property (nullable, nonatomic, retain) NSNumber *wasRendered;
@property (nullable, nonatomic, retain) NSNumber *wasRenderedInHD;
@property (nullable, nonatomic, retain) NSString *createdWithInvitationCode;
@property (nullable, nonatomic, retain) EmuticonDef *emuDef;

@end

NS_ASSUME_NONNULL_END
