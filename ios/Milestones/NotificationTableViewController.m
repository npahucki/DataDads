//
//  NotificationTableViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/28/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "NotificationTableViewController.h"
#import "NSDate+HumanizedTime.h"
#import "WebViewerViewController.h"
#import "PFCloud+Cache.h"
#import "NotificationDetailViewController.h"

#define TITLE_FONT_READ [UIFont fontForAppWithType:Light andSize:14]
#define TITLE_FONT_UNREAD [UIFont fontForAppWithType:Bold andSize:14]

#define DETAIL_FONT [UIFont fontForAppWithType:Book andSize:12]
#define MAX_LOAD_COUNT 10


@implementation NotificationTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    //[rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor appSelectedColor] title:@"Share"];
    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor redColor] title:@"Hide"];
    self.rightUtilityButtons = rightUtilityButtons;

    self.textLabel.textColor = [UIColor appNormalColor];
    self.detailTextLabel.font = DETAIL_FONT;
    self.detailTextLabel.textColor = [UIColor appGreyTextColor];
}

- (void)setBabyAssignedTip:(BabyAssignedTip *)tipAssignment {
    self.textLabel.text = tipAssignment.tip.titleForCurrentBaby;
    self.textLabel.font = tipAssignment.viewedOn ? TITLE_FONT_READ : TITLE_FONT_UNREAD;
    self.detailTextLabel.text = [NSString stringWithFormat:@"Delivered %@", [tipAssignment.assignmentDate stringWithHumanizedTimeDifference]];
    self.imageView.image = [UIImage imageNamed:tipAssignment.tip.tipType == TipTypeGame ? @"gameIcon" : @"tipsButton_active"];
    self.accessoryType = tipAssignment.tip.url.length ? UITableViewCellAccessoryDetailButton : UITableViewCellAccessoryNone;
}

@end

@implementation NotificationTableViewController {
    NSMutableArray *_objects;
    BOOL _hasMoreTips;
    BOOL _hadError;
    BOOL _isEmpty;
    BOOL _isMorganTouch;
    BOOL _isLoading;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 60;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(babyUpdated:) name:kDDNotificationCurrentBabyChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadObjects) name:kDDNotificationNeedDataRefreshNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkReachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedOut) name:kDDNotificationUserLoggedOut object:nil];

    _hasMoreTips = YES;
}

- (void)userLoggedOut {
    _objects = nil;
    _isEmpty = YES;
    _hadError = NO;
    _hasMoreTips = YES;
    _isLoading = NO;
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _isMorganTouch = NO; // Hack work around a double segue bug, caused by touching the cell too long
    [self.tableView reloadData];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)babyUpdated:(NSNotification *)notification {
    [self loadObjects];
}

- (void)networkReachabilityChanged:(NSNotification *)notification {
    if ([Reachability isParseCurrentlyReachable]) {
        [self loadObjects];
    }
}

- (void)loadObjects {
    [self loadObjectsSkip:0 withLimit:MAX_LOAD_COUNT];
}

- (void)loadObjectsSkip:(NSInteger)skip withLimit:(NSInteger)limit {
    if (Baby.currentBaby && !_isLoading) {
        NSDictionary *requestParams = @{@"babyId" : Baby.currentBaby.objectId,
                @"appVersion" : NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"],
                @"skip" : [@(skip) stringValue],
                @"limit" : [@(limit) stringValue],
                @"showHiddenTips" : @(ParentUser.currentUser.showHiddenTips)};

        // Show the loading indicator.
        _isLoading = YES;
        BOOL hasCachedResult = [PFCloud hasCachedResult:@"queryMyTips" params:requestParams];
        PFCachePolicy cachePolicy = _objects ? kPFCachePolicyNetworkElseCache : kPFCachePolicyCacheThenNetwork;
        __block BOOL cachedResult = hasCachedResult && cachePolicy == kPFCachePolicyCacheThenNetwork;
        [PFCloud callFunctionInBackground:@"queryMyTips"
                           withParameters:requestParams
                              cachePolicy:cachePolicy
                                    block:^(NSArray *objects, NSError *error) {
                                        _hadError = error != nil;
                                        _isLoading = cachedResult;      // Don't clear loading flag until data is loaded from network.
                                        cachedResult = NO;              // After the first time, the second call will NOT be cache.
                                        if (!_hadError) {
                                            if (skip == 0 || !_objects) {
                                                _objects = [[NSMutableArray alloc] initWithArray:objects];
                                            } else {
                                                // Add to end of list
                                                [_objects addObjectsFromArray:objects];
                                            }
                                            _hasMoreTips = objects.count == MAX_LOAD_COUNT;
                                        }
                                        _isEmpty = _objects.count == 0;
                                        [self.tableView reloadData];
                                    }];
    }
}


#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!_hadError && _hasMoreTips && indexPath.row >= _objects.count) {
        if ([self isLoadingRow:indexPath]) {
            [self loadObjectsSkip:_objects.count withLimit:MAX_LOAD_COUNT];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_isLoading) {
        return; // Do Nothing if the loading cell is clicked
    } else if ([self isLoadingRow:indexPath] && (_hadError || _isEmpty)) {
        [self.tableView reloadData];
        [self loadObjects];
    } else {
        if (!_isMorganTouch) {
            // Avoid the double segue bug
            _isMorganTouch = YES;
            [self performSegueWithIdentifier:kDDSegueShowNotificationDetails sender:[self.tableView cellForRowAtIndexPath:indexPath]];
        }
    }
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _isEmpty || _hadError ? 1 : _objects.count + (_hasMoreTips ? 1 : 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self isLoadingRow:indexPath]) {
        NotificationTableViewCell *cell = (NotificationTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"tipCell" forIndexPath:indexPath];
        cell.delegate = self;
        [cell setBabyAssignedTip:(BabyAssignedTip *) _objects[(NSUInteger) indexPath.row]];
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"loadingCell" forIndexPath:indexPath];
        cell.textLabel.textColor = [UIColor appGreyTextColor];
        cell.textLabel.font = [UIFont fontForAppWithType:Bold andSize:14];

        if (_isLoading || _hasMoreTips) {
            cell.textLabel.text = @"Loading...";
            cell.imageView.image = nil; // TODO: remove : Work around for Bug (see 18595125)  on ios 8
            cell.imageView.image = [UIImage animatedImageNamed:@"progress-" duration:1.0];
        } else if (_hadError) {
            cell.textLabel.text = @"Couldn't load tips. Click to try again";
            cell.imageView.image = [UIImage imageNamed:@"error-9"];
        } else {
            cell.textLabel.text = @"No Tips to show now. New tips should be arriving soon. Touch here to refresh";
            cell.imageView.image = [UIImage imageNamed:@"tipsButton_active"];
        }
        return cell;
    }
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:kDDSegueShowWebView sender:_objects[(NSUInteger) indexPath.row]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kDDSegueShowWebView]) {
        WebViewerViewController *webView = (WebViewerViewController *) segue.destinationViewController;
        BabyAssignedTip *assignment = (BabyAssignedTip *) sender;
        NSAssert(assignment.tip.url.length, @"This should only be called on a tip with a URL");
        webView.url = [NSURL URLWithString:assignment.tip.url];
    } else if ([segue.identifier isEqualToString:kDDSegueShowNotificationDetails]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        BabyAssignedTip *tipAssignment = (BabyAssignedTip *) _objects[(NSUInteger) indexPath.row];
        NotificationDetailViewController *detailController = (NotificationDetailViewController *) segue.destinationViewController;
        detailController.tipAssignment = tipAssignment;

        if (!tipAssignment.viewedOn) {
            tipAssignment.viewedOn = [NSDate date];
            [tipAssignment saveEventually];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            // Send this so the badges can be updated.
            [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationTipAssignmentViewedOrHidden object:tipAssignment];
        }
    }
}

#pragma mark - private methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    if (![self isLoadingRow:indexPath]) {
        CGFloat defaultSize = [super tableView:tableView heightForRowAtIndexPath:indexPath];
        if (indexPath.row > _objects.count - 1) {
            return defaultSize;
        }

        BabyAssignedTip *assignment = [self tipForIndexPath:indexPath];
        UIFont *fontToUse = assignment.viewedOn ? TITLE_FONT_READ : TITLE_FONT_UNREAD;
        CGFloat width = assignment.tip.url.length ? self.tableView.frame.size.width - 44 : self.tableView.frame.size.width;
        CGFloat newTitleLabelSize = [self getLabelSize:assignment.tip.titleForCurrentBaby andFont:fontToUse withMaxWidth:width];
        CGFloat newDateLabelSize = [self getLabelSize:[assignment.createdAt stringWithHumanizedTimeDifference] andFont:DETAIL_FONT withMaxWidth:width];
        return MAX(newTitleLabelSize + newDateLabelSize + 40, defaultSize);
    } else {
        // Loading row..
        return self.tableView.rowHeight;
    }
}

- (CGFloat)getLabelSize:(NSString *)text andFont:(UIFont *)font withMaxWidth:(CGFloat)width {

    NSDictionary *attributesDictionary = @{NSFontAttributeName : font};
    CGRect frame = [text boundingRectWithSize:CGSizeMake(width, 2000.0)
                                      options:NSStringDrawingUsesLineFragmentOrigin
                                   attributes:attributesDictionary
                                      context:nil];

    CGSize size = frame.size;

    return size.height;
}

- (void)hideNotification:(BabyAssignedTip *)tipAssignment withIndexPath:(NSIndexPath *)path {

    if (ParentUser.currentUser.showHiddenTips) {
        [[[UIAlertView alloc] initWithTitle:@"Can't do that" message:@"While showing hidden tips you can not hide one. Turn off 'Show HiddenTips' in settings if you want to hide this tip." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }

    tipAssignment.isHidden = YES;
    [tipAssignment saveEventually];

    [self.tableView beginUpdates];
    [_objects removeObjectAtIndex:(NSUInteger) path.row];
    [self.tableView deleteRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationRight];
    [self.tableView endUpdates];
    _isEmpty = _objects.count == 0;
    if (_isEmpty) [self.tableView reloadData];

    // Send this so the badges can be updated.
    [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationTipAssignmentViewedOrHidden object:tipAssignment];
}


#pragma mark - SWTableViewDelegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)buttonIndex {
    NSIndexPath *path = [self.tableView indexPathForCell:cell];
    BabyAssignedTip *a = [self tipForIndexPath:path];
    if (buttonIndex == 0) {
        [self hideNotification:a withIndexPath:path];
    }
}

- (BOOL)swipeableTableViewCell:(SWTableViewCell *)cell canSwipeToState:(SWCellState)state {
    if (state != kCellStateCenter) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return YES;
}


// Work around a bug where the accessory view is on top of the slide cell.
- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state {
    NSIndexPath *path = [self.tableView indexPathForCell:cell];
    // NOTE: Under some odd case, where the user clicks on the loading row a bunch of times in a row
    // the path can be null, which causes a crash when calling tipForIndexPath.
    if (path && state == kCellStateCenter) {
        // Back to normal. Must use delay to not interfere with scroll animation.
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
            BabyAssignedTip *tipAssignment = [self tipForIndexPath:path];
            cell.accessoryType = tipAssignment.tip.url.length ? UITableViewCellAccessoryDetailButton : UITableViewCellAccessoryNone;
        });
    }
}


- (BabyAssignedTip *)tipForIndexPath:(NSIndexPath *)indexPath {
    NSAssert(indexPath.section == 0, @"Unexpected section %ld", (long) indexPath.section);
    return _objects[(NSUInteger) indexPath.row];
}

- (BOOL)isLoadingRow:(NSIndexPath *)indexPath {
    return indexPath.row >= _objects.count;
}


@end
