//
//  EMAlphaNumericKeyboard.m
//  emu
//
//  Created by Aviv Wolf on 4/5/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
#define TAG @"EMAlphaNumericKeyboard"

#import "EMAlphaNumericKeyboard.h"
#import "EMDB.h"
#import "TagCell.h"
#import "KBKeyButton.h"

#define KB_ABC @1000
#define KB_NUMERIC @2000


@interface EMAlphaNumericKeyboard () <
    UICollectionViewDataSource,
    UICollectionViewDelegate
>


@property (weak, nonatomic) IBOutlet UICollectionView *guiTagsCollectionView;

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *guiKeysRow;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *guiKeys;

@property (weak, nonatomic) IBOutlet UIButton *guiToggleAlphaNumericButton;
@property (weak, nonatomic) IBOutlet UIButton *guiShiftButton;

@property (weak, nonatomic) IBOutlet KBKeyButton *guiDeleteBackKey;
@property (weak, nonatomic) IBOutlet UILabel *guiNoContentMessage;


@property (nonatomic) NSTimer *repeatingDeletingBackTimer;

@property (nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic) BOOL isLettersKB;
@property (nonatomic) BOOL isShiftPressed;
@property (nonatomic) BOOL isShiftHeld;
@property (nonatomic) BOOL isExtraSymbols;

@property (nonatomic) NSDate *lastTimeDoubleTapped;

@property (strong, nonatomic) NSArray *upperCaseLetterKeys;
@property (strong, nonatomic) NSArray *lowerCaseLetterKeys;
@property (strong, nonatomic) NSArray *numericAndSymbolsKeys;
@property (strong, nonatomic) NSArray *extraSymbolsKeys;

@end

@implementation EMAlphaNumericKeyboard

-(void)viewDidLoad {
    [super viewDidLoad];
    [self initKeys];
    [self updateKeyboardKeysForCurrentState];
    [self refresh];
}

-(void)initKeys
{
    self.isLettersKB = YES;
    
    self.upperCaseLetterKeys = @[@"Q",@"W",@"E",@"R",@"T",@"Y",@"U",@"I",@"O",@"P",
                                 @"A",@"S",@"D",@"F",@"G",@"H",@"J",@"K",@"L",
                                 @"Z",@"X",@"C",@"V",@"B",@"N",@"M"];
    
    self.lowerCaseLetterKeys = @[@"q",@"w",@"e",@"r",@"t",@"y",@"u",@"i",@"o",@"p",
                                 @"a",@"s",@"d",@"f",@"g",@"h",@"j",@"k",@"l",
                                 @"z",@"x",@"c",@"v",@"b",@"n",@"m"];
    
    self.numericAndSymbolsKeys = @[@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"0",
                                   @"-",@"/",@":",@";",@"(",@")",@"$",@"&",@"@",
                                   @".",@",",@"?",@"!",@"'",@"👍",@"\""];
    
    self.extraSymbolsKeys = @[@"[",@"]",@"{",@"}",@"#",@"%",@"^",@"*",@"+",@"=",
                              @"_",@"\\",@"|",@"~",@"<",@">",@"€",@"£",@"¥",
                              @".",@",",@"?",@"!",@"'",@"☕",@"•"];
    
    // Bind keypress events
    for (UIButton *keyButton in self.guiKeys) {
        [keyButton addTarget:self action:@selector(onPressedKeyButton:)
            forControlEvents:UIControlEventTouchUpInside];
    }
    
    // Double tappin the shift key
    [self.guiShiftButton addTarget:self
                            action:@selector(onShiftKeyMultipleTap:withEvent:)
                  forControlEvents:UIControlEventTouchDownRepeat];
}

-(BOOL)isFullAccessGranted
{
    return [self.delegate keyboardFullAccessWasGranted];
}

-(void)refresh
{
    self.guiNoContentMessage.hidden = [self.delegate isUserContentAvailable];
}

#pragma mark - Update keyboard keys
-(void)updateKeyboardKeysForCurrentState
{
    // Upper case letters by default.
    NSArray *keyStrings;
    
    // If switched keyboard to symbols or numbers, show the chosen keys.
    if (self.isLettersKB) {
        // Upper case letters.
        keyStrings = self.upperCaseLetterKeys;
        
        // Shift/alternate key.
        UIColor *shiftKeyBGColor = self.isShiftPressed? [EmuStyle colorKBKeyStrongestBG] : [EmuStyle colorKBKeyStrongBG];
        self.guiShiftButton.backgroundColor = shiftKeyBGColor;
        UIImage *shiftKeyImage =  self.isShiftHeld? [UIImage imageNamed:@"kbHeldShiftKey"] : [UIImage imageNamed:@"kbShiftKey"];
        [self.guiShiftButton setImage:shiftKeyImage forState:UIControlStateNormal];
        [self.guiShiftButton setTitle:@"" forState:UIControlStateNormal];

        // Switch letters/numeric keyboard key.
        [self.guiToggleAlphaNumericButton setTitle:@"123" forState:UIControlStateNormal];
    } else {
        keyStrings = self.isExtraSymbols? self.extraSymbolsKeys : self.numericAndSymbolsKeys;

        // Shift/alternate key.
        UIColor *shiftKeyBGColor = self.isExtraSymbols? [EmuStyle colorKBKeyStrongestBG] : [EmuStyle colorKBKeyStrongBG];
        self.guiShiftButton.backgroundColor = shiftKeyBGColor;
        [self.guiShiftButton setImage:nil forState:UIControlStateNormal];
        NSString *shiftKeyTitle = self.isExtraSymbols? @"123" : @"#+=";
        [self.guiShiftButton setTitle:shiftKeyTitle forState:UIControlStateNormal];
        
        // Switch letters/numeric keyboard key.
        [self.guiToggleAlphaNumericButton setTitle:@"abc" forState:UIControlStateNormal];
    }
    
    for (UIButton *keyButton in self.guiKeys) {
        NSInteger keyIndex = keyButton.tag;
        NSString *keyString = [self stringForKeyAtIndex:keyIndex
                                             keyStrings:keyStrings];
        [keyButton setTitle:keyString forState:UIControlStateNormal];
    }
}

#pragma mark - Keystrokes
-(NSArray *)currentKeyStrings
{
    if (self.isLettersKB) {
        if (self.isShiftPressed) {
            return self.upperCaseLetterKeys;
        } else {
            return self.lowerCaseLetterKeys;
        }
    } else {
        if (self.isExtraSymbols) {
            return self.extraSymbolsKeys;
        } else {
            return self.numericAndSymbolsKeys;
        }
    }
}

-(NSString *)stringForKeyAtIndex:(NSInteger)keyIndex
                      keyStrings:(NSArray *)keyStrings
{
    NSString *keyString;
    
    if (keyIndex < keyStrings.count) {
        keyString = keyStrings[keyIndex];
    } else {
        keyString = @"";
    }
    
    return keyString;
}

-(NSString *)stringForKeyAtIndex:(NSInteger)keyIndex
{
    return [self stringForKeyAtIndex:keyIndex
                          keyStrings:[self currentKeyStrings]];
}

-(void)handleSpecialCaseForString:(NSString *)s
{
    if ([s isEqualToString:@"'"]) {
        [self toggleAlphaNumericKB];
        [self updateKeyboardKeysForCurrentState];
    }
}

#pragma mark - KB states
-(void)toggleAlphaNumericKB
{
    // clear shift
    self.isShiftPressed = NO;
    self.isShiftHeld = NO;
    
    // Toggle letters/symbols
    if (self.isLettersKB) {
        self.isLettersKB = NO;
    } else {
        self.isLettersKB = YES;
    }
    
    [self updateKeyboardKeysForCurrentState];
}

-(void)toggleLettersShiftState
{
    if (self.isShiftHeld || self.isShiftPressed) {
        self.isShiftHeld = NO;
        self.isShiftPressed = NO;
    } else {
        self.isShiftHeld = NO;
        self.isShiftPressed = YES;
    }
    [self updateKeyboardKeysForCurrentState];
}

-(void)toggleSymbolsShiftState
{
    self.isExtraSymbols = !self.isExtraSymbols;
    self.isShiftHeld = NO;
    self.isShiftPressed = NO;
    [self updateKeyboardKeysForCurrentState];
}

#pragma mark - Fetched results controller
-(NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"emuDefs.@count>%@ AND rendersCount>%@", @0, @0];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:E_PACKAGE];
    fetchRequest.predicate = predicate;
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:YES] ];
    fetchRequest.fetchBatchSize = 20;
    
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                          managedObjectContext:EMDB.sh.context
                                                                            sectionNameKeyPath:nil
                                                                                     cacheName:@"Root"];
    _fetchedResultsController = frc;
    
    NSError *error;
    [_fetchedResultsController performFetch:&error];
    
    return frc;
}

-(void)resetFetchedResultsController
{
    _fetchedResultsController = nil;
    [self refresh];
    
    if (!self.isFullAccessGranted)
        return;
    NSError *error;
    [self.fetchedResultsController performFetch:&error];
}

#pragma mark - UICollectionViewDataSource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section
{
    if (!self.isFullAccessGranted) return 0;
    NSInteger count = self.fetchedResultsController.fetchedObjects.count;
    return count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"tag cell";
    TagCell *cell = [self.guiTagsCollectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier
                                                                          forIndexPath:indexPath];
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

-(CGSize)collectionView:(UICollectionView *)collectionView
                 layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width = 100;
    CGFloat height = self.guiTagsCollectionView.bounds.size.height;
    return CGSizeMake(width, height);
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Package *package = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (package == nil) return;
    [self.delegate keyboardShouldDismissAlphaNumericWithInfo:@{@"package":package}];
}

-(void)configureCell:(TagCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    Package *package = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.guiTagLabel.text = [package tagLabel];
}


#pragma mark - Deleting back
-(void)startRepeatingBackButton
{
    if (self.repeatingDeletingBackTimer) {
        [self.repeatingDeletingBackTimer invalidate];
    }

    [self.delegate keyboardShouldDeleteBackward];
    self.repeatingDeletingBackTimer = [NSTimer scheduledTimerWithTimeInterval:0.10
                                                                       target:self
                                                                     selector:@selector(repeatingBackDeleteTick:)
                                                                     userInfo:nil
                                                                      repeats:YES];
}

-(void)endRepeatingBackButton
{
    [self.repeatingDeletingBackTimer invalidate];
    self.repeatingDeletingBackTimer = nil;
    [self.guiDeleteBackKey released];
}

-(void)repeatingBackDeleteTick:(NSTimer *)timer
{
    [self.delegate keyboardShouldDeleteBackward];
}

#pragma mark - Bound actions
// =============
// Bound actions
// =============
-(void)onPressedKeyButton:(UIButton *)sender
{
    NSString *s = [self stringForKeyAtIndex:sender.tag];
    [self.delegate keyboardTypedString:s];
    [self handleSpecialCaseForString:s];

    if (self.isLettersKB && self.isShiftPressed && !self.isShiftHeld) {
        [self toggleLettersShiftState];
    }
}

-(void)onShiftKeyMultipleTap:(UIButton *)sender
                   withEvent:(UIEvent*)event
{
    UITouch* touch = [[event allTouches] anyObject];
    if (touch.tapCount != 2) return;
    self.lastTimeDoubleTapped = [NSDate date];
    self.isShiftPressed = YES;
    self.isShiftHeld = YES;
    [self updateKeyboardKeysForCurrentState];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedBackButton:(id)sender
{
    [self.delegate keyboardShouldDismissAlphaNumeric];
}

- (IBAction)onPressedNextKBButton:(UIButton *)sender
{
    [self.delegate keyboardShouldAdadvanceToNextInputMode];
}

- (IBAction)onPressedBackspaceKeyButton:(id)sender
{
    [self.delegate keyboardShouldDeleteBackward];
}

- (IBAction)onPressedSpaceBar:(UIButton *)sender
{
    [self.delegate keyboardTypedString:@" "];
}

- (IBAction)onPressedReturnKey:(UIButton *)sender
{
    [self.delegate keyboardTypedString:@"\n"];
}

- (IBAction)onPressedToggleAlphaNumericButton:(id)sender
{
    [self toggleAlphaNumericKB];
    [self updateKeyboardKeysForCurrentState];
}

- (IBAction)onPressedShiftKey:(UIButton *)sender
{
    if (self.lastTimeDoubleTapped) {
        NSDate *now = [NSDate date];
        if ([now timeIntervalSinceDate:self.lastTimeDoubleTapped] < 0.25) {
            return;
        }
    }
    
    self.lastTimeDoubleTapped = nil;
    
    if (self.isLettersKB) {
        [self toggleLettersShiftState];
    } else {
        [self toggleSymbolsShiftState];
    }
}


- (IBAction)onLongPressBackButton:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self startRepeatingBackButton];
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        [self endRepeatingBackButton];
    }
}

- (IBAction)onPressedEmuKey:(id)sender
{
    [self.delegate keyboardShouldDismissAlphaNumeric];
}


@end
