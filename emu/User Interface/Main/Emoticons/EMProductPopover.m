//
//  EMProductPopoverVC.m
//  emu
//
//  Created by Aviv Wolf on 03/11/2015.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMProductPopover.h"
#import "EMFlowButton.h"
#import "EMNotificationCenter.h"
#import "EMDB.h"
#import "EMBackend+AppStore.h"

@interface EMProductPopover ()

@property (weak, nonatomic) IBOutlet UILabel *guiDescriptionLabel;
@property (weak, nonatomic) IBOutlet EMFlowButton *guiPurchaseButton;
@property (weak, nonatomic) IBOutlet EMFlowButton *guiCancelButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivity;
@property (weak, nonatomic) IBOutlet EMButton *guiHeaderButton;

@property (nonatomic) NSDictionary *productInfo;

@end

@implementation EMProductPopover

- (instancetype)init {
    if (self = [super init]) {
        self.modalPresentationStyle = UIModalPresentationPopover;
        self.popoverPresentationController.delegate = self;
    }
    return self;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone; //You have to specify this particular value in order to make it work on iPhone.
}

#pragma mark - VC lifecycle
-(void)viewDidLoad
{
    [super viewDidLoad];
    self.guiPurchaseButton.positive = YES;
    self.guiPurchaseButton.alpha = 0.2;
    self.guiPurchaseButton.userInteractionEnabled = NO;
    self.guiCancelButton.positive = NO;
    self.guiCancelButton.userInteractionEnabled = NO;
    self.guiCancelButton.alpha = 0.2;
    [self.guiHeaderButton setTitle:LS(@"CONTACTING_STORE_TITLE") forState:UIControlStateNormal];
    
    self.guiDescriptionLabel.text = @"";
    [self.guiPurchaseButton setTitle:@"" forState:UIControlStateNormal];
    [self.guiActivity startAnimating];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initObservers];
    [self refreshPackageProductInfo];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self removeObservers];
}

#pragma mark - Observers
-(void)initObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    // On packages data refresh required.
    [nc addUniqueObserver:self
                 selector:@selector(onUpdatedProductInfo:)
                     name:emkDataProductsInfoUpdated
                   object:nil];
}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:emkDataProductsInfoUpdated];
}

#pragma mark - Observers handlers
-(void)onUpdatedProductInfo:(NSNotification *)notification
{
    Package *package = [Package findWithID:self.packageOID context:EMDB.sh.context];
    NSString *productIdentifier = package.hdProductID;
    if (productIdentifier) {
        NSDictionary *info = notification.userInfo;
        if (info[productIdentifier]) {
            self.productInfo = info[productIdentifier];
        }
    }
    [self updateUI];
}

#pragma mark - Refresh product info
-(void)refreshPackageProductInfo
{
    Package *package = [Package findWithID:self.packageOID context:EMDB.sh.context];
    [EMBackend.sh refreshProductInfoForPack:package];
}

#pragma mark - Update UI
-(void)updateUI
{
    Package *package = [Package findWithID:self.packageOID context:EMDB.sh.context];
    [self.guiActivity stopAnimating];
    if (!package.hdProductValidated.boolValue) {
        [self.guiHeaderButton setTitle:LS(@"ERROR_IN_STORE_INFO") forState:UIControlStateNormal];
        self.guiDescriptionLabel.text = @"";
        [self.guiActivity stopAnimating];
        return;
    }
    
    self.guiPurchaseButton.alpha = 1.0;
    self.guiPurchaseButton.userInteractionEnabled = YES;
    self.guiCancelButton.alpha = 1.0;
    self.guiCancelButton.userInteractionEnabled = YES;
    
    [self.guiHeaderButton setTitle:package.productTitle forState:UIControlStateNormal];
    self.guiDescriptionLabel.text = package.productDescription;
    
    NSString *buttonText = [SF:@"Get for %@", package.hdPriceLabel];
    [self.guiPurchaseButton setTitle:buttonText forState:UIControlStateNormal];
    
    // Analytics
    HMParams *params = [HMParams new];
    [self addProductInfoToParams:params];
    [params addKey:AK_EP_ORIGIN_UI valueIfNotNil:self.originUI];
    [HMPanel.sh analyticsEvent:AK_E_IAP_PRODUCT_PRESENTED info:params.dictionary];
}

-(void)addProductInfoToParams:(HMParams *)params
{
    [params addKey:AK_EP_PRODUCT_ID valueIfNotNil:self.productInfo[AK_EP_PRODUCT_ID]];
    [params addKey:AK_EP_PRODUCT_NAME valueIfNotNil:self.productInfo[AK_EP_PRODUCT_NAME]];
    [params addKey:AK_EP_PRODUCT_TYPE valueIfNotNil:self.productInfo[AK_EP_PRODUCT_TYPE]];
    [params addKey:AK_EP_PRICE valueIfNotNil:self.productInfo[AK_EP_PRICE]];
    [params addKey:AK_EP_CURRENCY valueIfNotNil:self.productInfo[AK_EP_CURRENCY]];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedBuyButton:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        HMParams *info = [HMParams new];
        [info addKey:emkPackageOID valueIfNotNil:self.packageOID];
        [self addProductInfoToParams:info];
        [self.delegate controlSentActionNamed:emkUIPurchaseHDContent info:info.dictionary];
    }];
}

- (IBAction)onPressedCancelButton:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}



@end
