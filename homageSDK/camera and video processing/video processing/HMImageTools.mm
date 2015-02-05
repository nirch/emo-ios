//
//  HMImageTools.m
//  emo
//
//  Created by Aviv Wolf on 2/5/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMImageTools.h"

@implementation HMImageTools

+(void)saveImageType3:(image_type *)image3 withName:(NSString *)name
{
    image_type* image4 = image4_from(image3, NULL);
    UIImage *imageToSave = CVtool::CreateUIImage(image4);
    [self saveImage:imageToSave withName:name];
    image_destroy(image4, 1);
}

+(void)saveImage:(UIImage *)image withName:(NSString *)name
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    
    NSString *path = [NSString stringWithFormat:@"%@.jpg" , name];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:path];
    
    [UIImageJPEGRepresentation(image, 1.0) writeToFile:dataPath atomically:YES];
}

@end
