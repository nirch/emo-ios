//
//  EMPagerView.m
//  emu
//
//  Created by Aviv Wolf on 2/18/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMPagerView.h"
#import "EmuStyle.h"

@interface EMPagerView() <
    UIGestureRecognizerDelegate
>

@property (nonatomic) CGFloat pw;
@property (nonatomic) CGFloat ph;

@end


@implementation EMPagerView

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initGUI];
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initGUI];
    }
    return self;
}

#pragma mark - Initializations
-(void)initGUI
{
    self.backgroundColor = [UIColor clearColor];
    self.pw = 29;
    self.ph = 17;
    self.rangedSelection = NO;
    
    // initialize tap recogniser
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    [tapRecognizer setNumberOfTapsRequired:1];
    [tapRecognizer setDelegate:self];
    [self addGestureRecognizer:tapRecognizer];
}

-(void)setCurrentPage:(NSInteger)currentPage
{
    _currentPage = currentPage;
    NSLayoutConstraint *widthConstraint = self.constraints.firstObject;
    widthConstraint.constant = self.pw * self.pagesCount;
    [self setNeedsDisplay];
}

-(void)setRangedSelection:(BOOL)rangedSelection
{
    _rangedSelection = rangedSelection;
    [self setNeedsDisplay];
}

#pragma mark - Custom drawing
-(void)drawRect:(CGRect)rect {
    
    // No need to display anything if just
    // a single page or less.
    if (self.pagesCount < 2)
        return;
    
    for (int i=0; i<self.pagesCount; i++) {
        
        BOOL isSelected = self.rangedSelection? i<= self.currentPage: i == self.currentPage;
        
        if (i==0) {
            // Left most
            [EmuStyle drawLeftPartWithPagerPartIndex:i
                                      pagerPartWidth:self.pw
                                   pagerPartSelected:isSelected];
        } else if (i==self.pagesCount-1) {
            // Right most
            [EmuStyle drawRightPartWithPagerPartIndex:i
                                       pagerPartWidth:self.pw
                                    pagerPartSelected:isSelected];
        } else {
            // Middle
            [EmuStyle drawMiddlePartWithPagerPartIndex:i
                                        pagerPartWidth:self.pw
                                     pagerPartSelected:isSelected];
        }
    }
    
}

#pragma mark - Gesture recognisers
-(void)tapped:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint p = [recognizer locationInView:self];
        NSInteger index = p.x / self.pw;
        self.currentPage = index;
    }
}

@end
