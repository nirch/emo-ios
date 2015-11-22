//
//  EMSettingsVC.m
//  emu
//
//  Created by Aviv Wolf on 03/11/2015.
//  Copyright © 2015 Homage. All rights reserved.
//

#define CELL_ID_SETTING @"setting cell"
#define CELL_ID_ABOUT @"setting about cell"
#define CELL_ID_HEADER @"section header cell"


#import "EMSettingsVC.h"
#import "EMNavBarVC.h"
#import "EMSettingsSectionCell.h"
#import "EMSettingsCell.h"
#import "AppManagement.h"
#import "UIView+Heirarchy.h"
#import "EMBackend+AppStore.h"
#import "EMNotificationCenter.h"
#import <UIView+Toast.h>
#import "EMDB.h"
#import "EMBlockingProgressVC.h"
#import "EMURLSchemeHandler.h"
#import "EMCaches.h"
#import "EMUISound.h"
#import "AppManagement.h"

@interface EMSettingsVC () <
    UITableViewDataSource,
    UITableViewDelegate
>

@property (weak, nonatomic) IBOutlet UITableView *guiTableView;


@property (nonatomic) NSMutableArray *settings;
@property (nonatomic) NSMutableDictionary *indexPathsByActionName;

// Navigation bar
@property (weak, nonatomic) EMNavBarVC *navBarVC;
@property (nonatomic) id<EMNavBarConfigurationSource> navBarCFG;

// Blocking progress VC
@property (weak, nonatomic, readonly) EMBlockingProgressVC *blockingProgressVC;

@end

@implementation EMSettingsVC

@synthesize blockingProgressVC = _blockingProgressVC;

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self initData];
    [self initNavigationBar];
    self.guiTableView.backgroundView = nil;
    self.guiTableView.backgroundColor = [UIColor clearColor];
    self.indexPathsByActionName = [NSMutableDictionary new];

}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self initObservers];
    [self.navBarVC updateTitle:LS(@"SETTINGS_TITLE")];
    [self.navBarVC showTitleAnimated:YES];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self removeObservers];
}

-(void)initObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    // On restore purchases updates.
    [nc addUniqueObserver:self
                 selector:@selector(onRestoredPurchasesUpdate:)
                     name:emkDataProductsRestoredPurchases
                   object:nil];
    
    // On app store errors
    [nc addUniqueObserver:self
                 selector:@selector(onAppStoreError:)
                     name:emkDataProductsError
                   object:nil];
    
    // On app store errors
    [nc addUniqueObserver:self
                 selector:@selector(onRedeemCodeUpdate:)
                     name:emkDataUpdatedUnhidePackages
                   object:nil];
    
    // On packages data updated.
    [nc addUniqueObserver:self
                 selector:@selector(onUpdatedData:)
                     name:emkDataUpdatedPackages
                   object:nil];
}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:emkDataProductsRestoredPurchases];
    [nc removeObserver:emkDataProductsError];
    [nc removeObserver:emkDataUpdatedUnhidePackages];
}

#pragma mark - Observers handlers
-(void)onRestoredPurchasesUpdate:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    if (info[@"restoredCount"]) {
        NSInteger count = [info[@"restoredCount"] integerValue];
        NSString *restoredMessage = LS(@"SETTINGS_RESPONSE_RESTORED_PURCHASES_MESSAGE");
        restoredMessage = [restoredMessage stringByReplacingOccurrencesOfString:@"#" withString:[@(count) stringValue]];
        [self.view makeToast:restoredMessage
                    duration:3.5
                    position:CSToastPositionCenter
                       title:LS(@"SETTINGS_RESPONSE_RESTORED_PURCHASES")];
    }
    
    EMSettingsCell *cell = [self cellForActionNamed:@"restorePurchases"];
    [cell stopActivity];
}

-(void)onAppStoreError:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSString *message = LS(@"ERROR_IN_STORE_INFO");
    if (info[@"error"]) {
        NSError *error = info[@"error"];
        if ([error localizedDescription]) {
            message = [error localizedDescription];
        }
    }
    [self.view makeToast:message
                duration:3.5
                position:CSToastPositionCenter];
    [self.guiTableView reloadData];
}

-(void)onRedeemCodeUpdate:(NSNotification *)notification
{
    if (notification.isReportingError) {
        [self.view makeToast:LS(@"FAILED")
                    duration:3.5
                    position:CSToastPositionCenter];
    }
    [self.guiTableView reloadData];
}

-(void)onUpdatedData:(NSNotification *)notification
{
    [self.blockingProgressVC updateTitle:@"Done"];
    [self.blockingProgressVC updateProgress:1.0 animated:YES];
    [self.blockingProgressVC done];

    if (notification.isReportingError) {
        [self.view makeToast:LS(@"FAILED")
                    duration:3.5
                    position:CSToastPositionCenter];
        return;
    }
    
    [self.view makeToast:@"Groovy baby!"
                duration:3.5
                position:CSToastPositionCenter];

    [self.guiTableView reloadData];
}

#pragma mark - Initializations
-(void)initData
{
    NSDictionary *sectionInfo;
    self.settings = [NSMutableArray new];

    /**
     *  About
     */
    sectionInfo = @{
                    @"title":LS(@"SETTINGS_ABOUT_HEADER"),
                    @"items":@[
                            @{
                                @"title1":LS(@"SETTINGS_APP_NAME"),
                                @"title2":[SF:LS(@"SETTINGS_ABOUT_VERSION"), [AppManagement.sh applicationBuild]], @"cellType":CELL_ID_ABOUT,
                                @"title3":LS(@"SETTINGS_HOMAGE_TITLE"),
                            }
                            ]
                    };
    [self.settings addObject:sectionInfo];


    if (AppManagement.sh.isTestApp) {
        sectionInfo = @{
                        @"title":@"Debugging options",
                        @"items":@[
                                @{@"actionText":@"Clear all and refetch all", @"actionName":@"debugClearAllAndRefetch",@"async":@YES},
                                ]
                        };
        [self.settings addObject:sectionInfo];
    }
    
    /**
     *  In App Purchases
     */
    NSNumber *redeemCodeOption = [HMPanel.sh numberForKey:VK_SETTINGS_REDEEM_CODE_OPTION
                                            fallbackValue:@0];
    
    NSMutableArray *iapItems = [NSMutableArray new];
    [iapItems addObject:@{@"actionText":LS(@"SETTINGS_ACTION_RESTORE_PURCHASES"), @"icon":@"settingsIconRestorePurchases", @"actionName":@"restorePurchases", @"async":@YES}];
    if ([redeemCodeOption isEqualToNumber:@1]) [iapItems addObject:@{@"actionText":LS(@"SETTINGS_ACTION_REDEEM_CODE"), @"icon":@"settingsIconRedeemCode", @"actionName":@"redeemCode", @"async":@YES}];
    
    sectionInfo = @{
                @"title":LS(@"SETTINGS_IN_APP_PURCHASES_TITLE"),
                @"items":iapItems
                };
    [self.settings addObject:sectionInfo];

    /**
     *  Cache
     */
    sectionInfo = @{
                    @"title":LS(@"SETTINGS_CACHE_TITLE"),
                    @"items":@[
                            @{@"actionText":LS(@"SETTINGS_ACTION_CACHE_CLEAR_HD"), @"icon":@"settingsIconClearHD", @"actionName":@"clearCacheHD"},
                            @{@"actionText":LS(@"SETTINGS_ACTION_CACHE_CLEAR_ALL"), @"icon":@"settingsIconClearCache", @"actionName":@"clearCacheAll"},
                            ]
                    };
    [self.settings addObject:sectionInfo];

    /**
     *  Misc.
     */
    sectionInfo = @{
                    @"title":LS(@"SETTINGS_MISC_TITLE"),
                    @"items":@[
                            @{@"actionText":LS(@"SETTINGS_UI_SOUND_EFFECTS"), @"icon":@"settingsIconUISound", @"actionName":@"toggleUISound", @"boolSettingName":@"uiSoundFX", @"appCFGBoolFieldName":@"playUISounds"},
                            ]
                    };
    [self.settings addObject:sectionInfo];
}

-(NSIndexPath *)indexPathForActionNamed:(NSString *)actionName
{
    return self.indexPathsByActionName[actionName];
}

-(EMSettingsCell *)cellForActionNamed:(NSString *)actionName
{
    NSIndexPath *indexPath = [self indexPathForActionNamed:actionName];
    if (indexPath == nil) return nil;
    return [self.guiTableView cellForRowAtIndexPath:indexPath];
}

-(void)initNavigationBar
{
    self.navBarVC = [EMNavBarVC navBarVCInParentVC:self themeColor:[EmuStyle colorThemeSettings]];
//    self.navBarVC.delegate = self;
    
//    self.navBarCFG = [EMMeNavigationCFG new];
    self.navBarVC.configurationSource = self.navBarCFG;
    [self.navBarVC updateUIByCurrentState];
    self.guiTableView.contentInset = UIEdgeInsetsMake(44, 0, 39, 0);
}

#pragma mark - UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.settings.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary *sectionInfo = self.settings[section];
    return [sectionInfo[@"items"] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *sectionInfo = self.settings[indexPath.section];
    NSDictionary *itemInfo = sectionInfo[@"items"][indexPath.item];
    NSString *actionName = itemInfo[@"actionName"];
    NSString *cellType = itemInfo[@"cellType"]?itemInfo[@"cellType"]:CELL_ID_SETTING;
    EMSettingsCell *cell = [tableView dequeueReusableCellWithIdentifier:cellType forIndexPath:indexPath];
    cell.cellType = cellType;
    cell.itemInfo = itemInfo;
    cell.indexPath = indexPath;
    [cell updateGUI];
    if (actionName!=nil) self.indexPathsByActionName[actionName] = indexPath;
    return cell;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    static NSString *cellIdentifier = CELL_ID_HEADER;
    EMSettingsSectionCell *headerView = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    NSDictionary *sectionInfo = self.settings[section];
    headerView.info = sectionInfo;
    [headerView updateGUI];
    return headerView;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *sectionInfo = self.settings[indexPath.section];
    NSDictionary *itemInfo = sectionInfo[@"items"][indexPath.item];
    NSString *cellType = itemInfo[@"cellType"]?itemInfo[@"cellType"]:CELL_ID_SETTING;
    if ([cellType isEqualToString:CELL_ID_ABOUT])
    {
        return 160.0f;
    } else if ([cellType isEqualToString:CELL_ID_SETTING]) {
        return 80.0f;
    } else {
        return 60.0f;
    }
}

#pragma mark - Items & Action names
-(NSString *)actionNameAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self itemAtIndexPath:indexPath];
    return item[@"actionName"];
}

-(NSDictionary *)itemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath == nil) return nil;
    if (indexPath.section >= self.settings.count) return nil;
    NSDictionary *sectionInfo = self.settings[indexPath.section];
    NSArray *items = sectionInfo[@"items"];
    if (items == nil || indexPath.item >= items.count) return nil;
    return items[indexPath.item];
}

#pragma mark - Actions
-(void)doActionAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *actionName = [self actionNameAtIndexPath:indexPath];
    if ([actionName isEqualToString:@"restorePurchases"]) {
        [self _restorePurchases];

    } else if ([actionName isEqualToString:@"clearCacheHD"]) {

        dispatch_async(dispatch_get_main_queue(), ^{
            [self _clearHDContent];
        });

    } else if ([actionName isEqualToString:@"clearCacheAll"]) {

        dispatch_async(dispatch_get_main_queue(), ^{
            [self _clearAllCache];
        });
        
    } else if ([actionName isEqualToString:@"redeemCode"]) {
        
        [self _redeemCode];
        
    } else if ([actionName isEqualToString:@"debugClearAllAndRefetch"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _deleteAllAndRefetch];
        });
    }
}

-(void)doActionAtIndexPath:(NSIndexPath *)indexPath withSwitchValue:(BOOL)switchValue
{
    NSString *actionName = [self actionNameAtIndexPath:indexPath];
    if ([actionName isEqualToString:@"toggleUISound"]) {
        [self _settingPlayUISounds:switchValue];
    }
}

-(void)_restorePurchases
{
    [EMBackend.sh restorePurchases];
}

-(void)_redeemCode
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LS(@"SETTINGS_ACTION_REDEEM_CODE") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:nil];
    [alert addAction:[UIAlertAction actionWithTitle:LS(@"SEND") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *code = alert.textFields.firstObject.text;
        code = [self trimmedString:code];
        EMURLSchemeHandler *handler = [EMURLSchemeHandler new];
        [handler redeemCode:code];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:LS(@"CANCEL") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self.guiTableView reloadData];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)_clearHDContent
{
    NSArray *emuticons = [Emuticon allEmuticonsRenderedInHD];
    for (Emuticon *emu in emuticons) {
        [emu.emuDef removeAllHDResources];
        [emu cleanUpHDOutputGif];
        emu.shouldRenderAsHDIfAvailable = @NO;
    }
    [self.view makeToast:LS(@"SETTINGS_CLEARED_HD_MESSAGE")
                duration:3.5
                position:CSToastPositionCenter
                title:LS(@"SETTINGS_CLEARED_HD_TITLE")];
}

-(void)_clearAllCache
{
    NSArray *packages = [Package allPackagesInContext:EMDB.sh.context];
    CGFloat total = packages.count;
    if (total < 1.0f) return;

    [self showBlockingProgressVC];
    [self.blockingProgressVC updateTitle:LS(@"SETTINGS_CLEARING_CACHE_PROGRESS")];
    __block CGFloat cleared = 0.0f;
    __weak EMSettingsVC *wSelf = self;
    for (Package *package in packages) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [wSelf _clearAllCachedFilesForPack:package];
        });
        dispatch_async(dispatch_get_main_queue(), ^{
            cleared += 1.0f;
            [wSelf.blockingProgressVC updateProgress:cleared/total animated:YES];
        });
    }
    dispatch_after(DTIME(1.5), dispatch_get_main_queue(), ^{
        [self.blockingProgressVC done];
    });
}

-(void)_deleteAllAndRefetch
{
    [self showBlockingProgressVC];
    [self.blockingProgressVC updateTitle:@"Exterminate!!!"];
    dispatch_after(DTIME(0.1), dispatch_get_main_queue(), ^{
        [self.blockingProgressVC updateProgress:0.2 animated:YES];
        for (Package *package in [Package allPackagesInContext:EMDB.sh.context]) {
            NSArray *emus = [Emuticon allEmuticonsInPackage:package];
            for (Emuticon *emu in emus) {
                [emu cleanUp:YES andRemoveResources:YES];
            }
            [package recountRenders];
        }
        dispatch_after(DTIME(0.1), dispatch_get_main_queue(), ^{
            [self.blockingProgressVC updateTitle:@"Refetching..."];
            [self.blockingProgressVC updateProgress:0.7 animated:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:emkDataRequiredPackages
                                                                object:self
                                                              userInfo:@{@"forced_reload":@YES, @"delete all and clean":@YES}];
        });
    });
    [EMDB.sh save];

}

-(void)_clearAllCachedFilesForPack:(Package *)package
{
    NSArray *emus = [package emuticons];
    for (Emuticon *emu in emus) {
        [emu.emuDef removeAllResources];
    }
    [EMCaches.sh clearAllCache];
}

-(void)_settingPlayUISounds:(BOOL)flag
{
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    appCFG.playUISounds = @(flag);
    [EMUISound.sh updateConfig];
}

-(NSString *)trimmedString:(NSString *)str
{
    return [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

#pragma mark - Blocking progress VC
-(EMBlockingProgressVC *)blockingProgressVC
{
    // Put it on top of everything.
    if (_blockingProgressVC) return _blockingProgressVC;
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    UIViewController *rootVC = window.rootViewController;
    EMBlockingProgressVC *vc = [EMBlockingProgressVC blockingProgressVCInParentVC:rootVC];
    _blockingProgressVC = vc;
    return vc;
}

-(void)showBlockingProgressVC
{
    [self.blockingProgressVC showAnimated:YES];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onSettingsButtonPressed:(UIButton *)sender
{
    sender.enabled = NO;
    sender.alpha = 0.5;
    dispatch_after(DTIME(2.0), dispatch_get_main_queue(), ^{
        sender.enabled = YES;
        sender.alpha = 1.0;
    });
    EMSettingsCell *cell = (EMSettingsCell *)[sender viewFindAncestorOfKind:[EMSettingsCell class]];
    if (cell == nil) return;
    [cell startActivity];
    [self doActionAtIndexPath:cell.indexPath];
}

- (IBAction)onSettingSwitchValueChanged:(UISwitch *)sender
{
    EMSettingsCell *cell = (EMSettingsCell *)[sender viewFindAncestorOfKind:[EMSettingsCell class]];
    if (cell == nil) return;
    [self doActionAtIndexPath:cell.indexPath withSwitchValue:sender.on];
}

- (IBAction)onLongPressedLogo:(id)sender
{
    NSNumber *redeemCodeOption = [HMPanel.sh numberForKey:VK_SETTINGS_REDEEM_CODE_OPTION
                                            fallbackValue:@0];
    if ([redeemCodeOption isEqualToNumber:@2]) {
        [self _redeemCode];        
    }
}

@end
