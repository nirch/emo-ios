//
//  Emuticon+CoreDataProperties.m
//  emu
//
//  Created by Aviv Wolf on 04/02/2016.
//  Copyright © 2016 Homage. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Emuticon+CoreDataProperties.h"

@implementation Emuticon (CoreDataProperties)

@dynamic audioFilePath;
@dynamic audioStartTime;
@dynamic inFocus;
@dynamic isFavorite;
@dynamic isPreview;
@dynamic jointEmuInstance;
@dynamic lastTimeShared;
@dynamic lastTimeViewed;
@dynamic oid;
@dynamic prefferedFootageOID;
@dynamic remoteFootages;
@dynamic renderedSampleUploaded;
@dynamic rendersCount;
@dynamic shouldRenderAsHDIfAvailable;
@dynamic timeCreated;
@dynamic usageCount;
@dynamic videoLoopsCount;
@dynamic videoLoopsEffect;
@dynamic wasRendered;
@dynamic wasRenderedInHD;
@dynamic createdWithInvitationCode;
@dynamic emuDef;

@end
