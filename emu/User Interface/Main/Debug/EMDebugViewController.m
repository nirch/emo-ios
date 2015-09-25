//
//  EMDebugViewController.m
//  emu
//
//  Created by Aviv Wolf on 6/10/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
#define TAG @"EMDebugViewController"

#import "EMDebugViewController.h"
#import "EMDebugCell.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "EMShareDebuggingFile.h"

@interface EMDebugViewController () <
    UITableViewDataSource,
    UITableViewDelegate
>

@property (weak, nonatomic) IBOutlet UITableView *guiTableView;
@property (nonatomic) NSError *error;
@property (nonatomic) NSString *rootPath;
@property (nonatomic) NSMutableArray *folders;
@property (nonatomic) NSFileManager *fm;
@property (nonatomic) EMShare *sharer;

@end

@implementation EMDebugViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.fm = [NSFileManager defaultManager];
    [self initGUI];
    [self initData];
}

-(void)viewDidAppear:(BOOL)animated
{
    [self.guiTableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    HMLOG(TAG, EM_DBG, @"Memory warning :-(");
}

#pragma mark - Initializations
-(void)initGUI
{
    
}

-(void)initData
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *url = [[fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    self.rootPath = [url path];
    
    self.folders = [NSMutableArray new];
    for (NSString *file in [fm contentsOfDirectoryAtPath:self.rootPath error:nil]) {
        NSString *path = [self.rootPath stringByAppendingPathComponent:file];
        BOOL isDirectory = NO;
        [fm fileExistsAtPath:path isDirectory:&isDirectory];
        if ([file hasPrefix:@"DEBUG_"] && isDirectory) {
            [self.folders addObject:file];
            HMLOG(TAG, EM_DBG, @"File");
        }
    }
}

-(void)reloadData
{
    [self initData];
    [self.guiTableView reloadData];
}

#pragma mark - UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.folders.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"debug cell";
    EMDebugCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

-(void)configureCell:(EMDebugCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    NSString *folderName = self.folders[indexPath.item];
    NSString *folderPath = [self.rootPath stringByAppendingPathComponent:folderName];

    cell.guiLabel1.text = folderName;
    
    // Show image if available.
    cell.guiImage.image = nil;
    NSError *error;
    NSArray *filesInDir = [self.fm contentsOfDirectoryAtPath:folderPath error:&error];
    if (error) {
        cell.guiLabel2.text = [SF:@"error reading files. %@", [error localizedDescription]];
        return;
    } else if (filesInDir.count < 1) {
        cell.guiLabel2.text = @"Files missing...";
        return;
    }
    
    // More info string.
    NSString *info = [SF:@"files (%@)", @(filesInDir.count)];
    NSString *outputPath = [folderPath stringByAppendingPathComponent:@"output"];
    BOOL isDirectory = NO;
    [self.fm fileExistsAtPath:outputPath isDirectory:&isDirectory];
    if (isDirectory) {
        info = [info stringByAppendingString:@" - Raw & processed images"];
    } else {
        info = [info stringByAppendingString:@" - Raw images"];
    }
    
    cell.guiLabel2.text = info;
    
    
    // Image
    NSString *filePath = [folderPath stringByAppendingPathComponent:filesInDir[0]];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (data) {
        cell.guiImage.image = [UIImage imageWithData:data];
    }
    
}

-(void)deleteAll
{
    for (NSString *folderName in self.folders) {
        [self deleteFolderNamed:folderName];
    }
}


-(void)deleteFolderNamed:(NSString *)folderName
{
    if (self.error) return;
    
    NSString *folderPath = [self.rootPath stringByAppendingPathComponent:folderName];
    NSString *zipName = [SF:@"%@.zip", folderName];
    NSString *zipPath = [self.rootPath stringByAppendingPathComponent:zipName];
    
    [self.fm removeItemAtPath:zipPath error:nil];
    NSError *error;
    [self.fm removeItemAtPath:folderPath error:&error];
    if (error) {
        self.error = error;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:[error description] preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            dispatch_after(DTIME(5.0), dispatch_get_main_queue(), ^{
                self.error = nil;
            });
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}


#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *folderName = self.folders[indexPath.item];
        [self deleteFolderNamed:folderName];
        [self reloadData];
    }
}

#pragma mark - Sharing
-(void)shareFolderNamed:(NSString *)folderName
{
    return;
//    // Update the UI for long process
//    HMLOG(TAG, EM_DBG, @"Share folder: %@", folderName);
//    [UIView animateWithDuration:0.3 animations:^{
//        self.guiTableView.alpha = 0.2;
//    }];
//    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    
//    // Zip and share
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        // ZIP in the background
//        NSString *zipFilePath = [self.rootPath stringByAppendingPathComponent:[SF:@"%@.zip", folderName]];
//        ZKFileArchive *archive = [ZKFileArchive archiveWithArchivePath:zipFilePath];
//        NSString *folderPath = [self.rootPath stringByAppendingPathComponent:folderName];
//        NSInteger result = [archive deflateDirectory:folderPath relativeToPath:self.rootPath usingResourceFork:NO];
//        HMLOG(TAG, EM_DBG, @"Zip result: %@", @(result));
//        dispatch_async(dispatch_get_main_queue(), ^{
//            // Done
//            self.guiTableView.alpha = 1;
//            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
//            
//            // Share zipped file
//            if (result == 1) {
//                self.sharer = [EMShareDebuggingFile new];
//                NSURL *zipFileURL = [NSURL fileURLWithPath:zipFilePath];
//                self.sharer.objectToShare = zipFileURL;
//                self.sharer.viewController = self;
//                self.sharer.view = self.view;
//                [self.sharer share];
//            }
//        });
//    });
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedDoneButton:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)onPressedDeleteAllButton:(UIBarButtonItem *)sender
{
    [self deleteAll];
    [self reloadData];
    sender.enabled = NO;
}

- (IBAction)onLongPressedTable:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateEnded) return;
    CGPoint p = [recognizer locationInView:self.guiTableView];
    NSIndexPath *indexPath = [self.guiTableView indexPathForRowAtPoint:p];
    if (indexPath == nil) return;
    
    NSString *folderName = self.folders[indexPath.item];
    [self shareFolderNamed:folderName];
}
@end
