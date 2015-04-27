//
//  EMHolySheetSection.m
//  emu
//
//  Created by Aviv Wolf on 4/20/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMHolySheetSection.h"

@implementation EMHolySheetSection

+ (instancetype)sectionWithTitle:(NSString *)title
                         message:(NSString *)message
                    buttonTitles:(NSArray *)buttonTitles
                     buttonStyle:(JGActionSheetButtonStyle)buttonStyle
{
    EMHolySheetSection *section = (EMHolySheetSection *)[super sectionWithTitle:title
                                                                        message:message
                                                                   buttonTitles:buttonTitles
                                                                    buttonStyle:buttonStyle];
    section.sectionStyle = buttonStyle;
    return section;
}

@end
