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

#define TITLE_FONT [UIFont fontForAppWithType:Book andSize:14]
#define DETAIL_FONT [UIFont fontForAppWithType:Book andSize:12]
#define MAX_LOAD_COUNT 15


@implementation NotificationTableViewController {
    TipType _tipFilter;
    NSMutableArray *_objects;
    BOOL _hasMoreTips;
    BOOL _hadError;
    BOOL _isEmpty;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 60;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(babyUpdated:) name:kDDNotificationCurrentBabyChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadObjects) name:kDDNotificationNeedDataRefreshNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkReachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userSignedUp) name:kDDNotificationUserSignedUp object:nil];

    _hasMoreTips = YES;
}

- (void)userSignedUp {
    if (Baby.currentBaby) {
        NSString *msg = @"Thanks for signing in! Tips are delivered once per day";
        if (_isEmpty) {
            msg = [msg stringByAppendingString:@"you should be getting one soon!"];
        } else {
            msg = [msg stringByAppendingString:@"."];
        }
        [[[UIAlertView alloc] initWithTitle:@"Great!" message:msg delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    }
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

- (TipType)tipFilter {
    return _tipFilter;
}

- (void)setTipFilter:(TipType)tipFilter {
    _tipFilter = tipFilter;
    [self loadObjects];
}

- (void)loadObjects {
    [self loadObjectsSkip:0 withLimit:MAX_LOAD_COUNT];
}

- (void)loadObjectsSkip:(NSInteger)skip withLimit:(NSInteger)limit {
    if (Baby.currentBaby) {
        //    query.maxCacheAge = 60 * 60 * 24; // at max check once a day.
        [PFCloud callFunctionInBackground:@"queryMyTips"
                           withParameters:@{@"babyId" : Baby.currentBaby.objectId,
                                   @"skip" : [@(skip) stringValue],
                                   @"limit" : [@(limit) stringValue],
                                   @"showHiddenTips" : @(ParentUser.currentUser.showHiddenTips)}
                              cachePolicy:_objects.count == 0 ? kPFCachePolicyCacheThenNetwork : kPFCachePolicyNetworkOnly
                                    block:^(NSArray *objects, NSError *error) {
                                        _hadError = error != nil;
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
    if (_hasMoreTips && indexPath.row >= _objects.count) {
        if ([self isLoadingRow:indexPath]) {
            [self loadObjectsSkip:_objects.count withLimit:MAX_LOAD_COUNT];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isLoadingRow:indexPath] && (_hadError || _isEmpty)) {
        _isEmpty = NO;
        _hadError = NO; // Make sure loading icon shows again
        [self.tableView reloadData];
        [self loadObjects];
    } else {
        [self performSegueWithIdentifier:kDDSegueShowNotificationDetails sender:[self.tableView cellForRowAtIndexPath:indexPath]];
    }
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _isEmpty ? 1 : _objects.count + (_hasMoreTips ? 1 : 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self isLoadingRow:indexPath]) {
        SWTableViewCell *cell = (SWTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"tipCell" forIndexPath:indexPath];
        __weak SWTableViewCell *weakCell = cell;
        [cell setAppearanceWithBlock:^{
            NSMutableArray *rightUtilityButtons = [NSMutableArray new];
            //[rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor appSelectedColor] title:@"Share"];
            [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor redColor] title:@"Hide"];
            weakCell.rightUtilityButtons = rightUtilityButtons;

            weakCell.textLabel.font = TITLE_FONT;
            weakCell.textLabel.textColor = [UIColor appNormalColor];
            weakCell.detailTextLabel.font = DETAIL_FONT;
            weakCell.detailTextLabel.textColor = [UIColor appGreyTextColor];
            weakCell.containingTableView = tableView;
            weakCell.delegate = self;
        }                      force:NO];

        BabyAssignedTip *tipAssignment = (BabyAssignedTip *) _objects[indexPath.row];
        [cell setCellHeight:cell.frame.size.height];
        cell.textLabel.text = tipAssignment.tip.titleForCurrentBaby;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Delivered %@", [tipAssignment.assignmentDate stringWithHumanizedTimeDifference]];
        cell.imageView.image = [UIImage imageNamed:tipAssignment.tip.tipType == TipTypeGame ? @"gameIcon" : @"tipsButton_active"];
        // TODO: set image according to tip type.
        cell.accessoryType = tipAssignment.tip.url.length ? UITableViewCellAccessoryDetailButton : UITableViewCellAccessoryNone;
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"loadingCell" forIndexPath:indexPath];
        cell.textLabel.textColor = [UIColor appGreyTextColor];
        cell.textLabel.font = [UIFont fontForAppWithType:Bold andSize:14];
        if (_hadError) {
            cell.textLabel.text = @"Couldn't load tips. Click to try again";
            cell.imageView.image = [UIImage imageNamed:@"error-9"];
        } else {
            if (_isEmpty && !_hasMoreTips) {
                cell.textLabel.text = @"No Tips to show now. New tips should be arriving soon. Touch here to refresh";
                cell.imageView.image = [UIImage imageNamed:@"tipsButton_active"];
            } else {
                cell.textLabel.text = @"Loading...";
                cell.imageView.image = [UIImage animatedImageNamed:@"progress-" duration:1.0];
            }
        }
        return cell;
    }
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:kDDSegueShowWebView sender:_objects[indexPath.row]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kDDSegueShowWebView]) {
        WebViewerViewController *webView = (WebViewerViewController *) segue.destinationViewController;
        BabyAssignedTip *assignment = (BabyAssignedTip *) sender;
        NSAssert(assignment.tip.url.length, @"This should only be called on a tip with a URL");
        webView.url = [NSURL URLWithString:assignment.tip.url];
    } else if ([segue.identifier isEqualToString:kDDSegueShowNotificationDetails]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        NotificationDetailViewController *detailController = (NotificationDetailViewController *) segue.destinationViewController;
        detailController.tipAssignment = (BabyAssignedTip *) _objects[indexPath.row];
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
        CGFloat width = assignment.tip.url.length ? self.tableView.frame.size.width - 44 : self.tableView.frame.size.width;
        CGFloat newTitleLabelSize = [self getLabelSize:assignment.tip.titleForCurrentBaby andFont:TITLE_FONT withMaxWidth:width];
        CGFloat newDateLabelSize = [self getLabelSize:[assignment.createdAt stringWithHumanizedTimeDifference] andFont:DETAIL_FONT withMaxWidth:width];
        return MAX(newTitleLabelSize + newDateLabelSize + 40, defaultSize);
    } else {
        // Loading row..
        return self.tableView.rowHeight;
    }
}

- (CGFloat)getLabelSize:(NSString *)text andFont:(UIFont *)font withMaxWidth:(int)width {

    NSDictionary *attributesDictionary = @{NSFontAttributeName : font};
    CGRect frame = [text boundingRectWithSize:CGSizeMake(width, 2000.0)
                                      options:NSStringDrawingUsesLineFragmentOrigin
                                   attributes:attributesDictionary
                                      context:nil];

    CGSize size = frame.size;

    return size.height;
}

- (void)hideNotification:(BabyAssignedTip *)notificaiton withIndexPath:(NSIndexPath *)path {

    if (ParentUser.currentUser.showHiddenTips) {
        [[[UIAlertView alloc] initWithTitle:@"Can't do that" message:@"While showing hidden tips you can not hide one. Turn off 'Show HiddenTips' in settings if you want to hide this tip." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }

    [notificaiton saveEventually];

    [self.tableView beginUpdates];
    [_objects removeObjectAtIndex:path.row];
    [self.tableView deleteRowsAtIndexPaths:@[path] withRowAnimation:YES];
    [self.tableView endUpdates];
    _isEmpty = _objects.count == 0;
    if (_isEmpty) [self.tableView reloadData];
}

- (void)shareNotification:(BabyAssignedTip *)notificaiton withIndexPath:(NSIndexPath *)path {
    [[[UIAlertView alloc] initWithTitle:@"Keep your pants on!" message:@"Coming soon!" delegate:nil cancelButtonTitle:@"Yeah, I got it" otherButtonTitles:nil, nil] show];
}

#pragma mark - SWTableViewDelegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)buttonIndex {
    // TODO: rework this to not use PF table view - so we can do animated deletes.

    NSIndexPath *path = [self.tableView indexPathForCell:cell];
    BabyAssignedTip *a = [self tipForIndexPath:path];
    if (buttonIndex == 0) {
        [self hideNotification:a withIndexPath:path];
    } else if (buttonIndex == 1) {
        [self shareNotification:a withIndexPath:path];
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
    if (state == kCellStateCenter) {
        // Back to normal. Must use delay to not interfere with scroll animation.
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
            NSIndexPath *path = [self.tableView indexPathForCell:cell];
            BabyAssignedTip *tipAssignment = [self tipForIndexPath:path];
            cell.accessoryType = tipAssignment.tip.url.length ? UITableViewCellAccessoryDetailButton : UITableViewCellAccessoryNone;
        });
    }
}


- (BabyAssignedTip *)tipForIndexPath:(NSIndexPath *)indexPath {
    NSAssert(indexPath.section == 0, @"Unexpected section %ld", (long) indexPath.section);
    return _objects[indexPath.row];
}

- (BOOL)isLoadingRow:(NSIndexPath *)indexPath {
    return indexPath.row >= _objects.count;
}


@end
