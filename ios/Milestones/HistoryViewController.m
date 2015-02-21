//
//  HistoryViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/11/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

// TODO:
// Handle low memory by releasing past milestones not being looked at.

#import "HistoryViewController.h"
#import "HistoryTableHeaderView.h"
#import "SignUpOrLoginViewController.h"

#define PRELOAD_START_AT_IDX 1

@interface HistoryViewController () {
    CGSize _lastTableSize;

    HistoryTableHeaderView *_floatingAchievementsHeaderView;
    HistoryTableHeaderView *_floatingPastMilestonesHeaderView;
    HistoryTableHeaderView *_floatingFutureMilestonesHeaderView;

    HistoryTableHeaderView *_rovingAchievementsHeaderView;
    HistoryTableHeaderView *_rovingPastMilestonesHeaderView;
    HistoryTableHeaderView *_rovingFutureMilestonesHeaderView;


    NSIndexPath *_pendingNextPageTriggerIndex;
    BOOL _isJumpingToIndex;
    SInt8 _scrollStatus; // -1 going up, 0 not scrolling, 1 scrolling down.
    BOOL _didInitialLoad;
}

@end

@implementation HistoryViewController {
    HistoryViewControllerDataSource *_dataSource; // Need reference to retain it
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _model = [[HistoryViewTableModel alloc] init];
    _model.delegate = self;
    _model.pagingSize = 25;
    _dataSource = [[HistoryViewControllerDataSource alloc] init];
    _dataSource.model = _model;
    _dataSource.cellSwipeDelegate = self;
    self.tableView.dataSource = _dataSource;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 84;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundView = nil;


    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(babyUpdated:) name:kDDNotificationCurrentBabyChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(milestoneNotedAndSaved:) name:kDDNotificationMilestoneNotedAndSaved object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkReachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:kDDNotificationNeedDataRefreshNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAchievementNeedsUpdate:) name:kDDNotificationAchievementNotedAndSaved object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAchievementNeedsDeletion:) name:kDDNotificationAchievementNeedsDeleteAction object:nil];

    if (Baby.currentBaby) { // Only load if there is already a baby set
        self.baby = Baby.currentBaby;
    }

    self.tableView.sectionHeaderHeight = 0.0;
    self.tableView.sectionFooterHeight = 0.0;

}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)networkReachabilityChanged:(NSNotification *)notification {
    if ([Reachability isParseCurrentlyReachable] && _model.baby) {
        [self reloadTable];
    }
}

- (void)setFilterString:(NSString *)filterString {
    _model.filter = filterString;
    _didInitialLoad = NO; // Reset after search.
}

- (NSString *)filterString {
    return _model.filter;
}

- (void)reloadTable {
    _didInitialLoad = NO;
    _model.showPostponedMilestones = ParentUser.currentUser.showPostponedMilestones;
    _model.showIgnoredMilestones = ParentUser.currentUser.showIgnoredMilestones;
    [_model loadAchievementsPage:0];
    [_model loadFutureMilestonesPage:0];
    [_model loadPastMilestonesPage:0];
}

- (void)babyUpdated:(NSNotification *)notification {
    self.baby = Baby.currentBaby;
}

- (void)setBaby:(Baby *)baby {
    if (baby == nil) {
        // Logged out
        self.navigationItem.title = nil;
        [_model reset];
    } else {
        self.navigationItem.title = Baby.currentBaby.name;
        _model.baby = Baby.currentBaby;
    }
    [self reloadTable];
}


- (void)milestoneNotedAndSaved:(NSNotification *)notification {
    MilestoneAchievement *achievement = notification.object;
    NSMutableArray *reloadPaths = [NSMutableArray arrayWithCapacity:5];
    [UIView beginAnimations:@"insertAnimationId" context:nil];
    [UIView setAnimationDuration:1.0]; // Set duration here
    [CATransaction begin];
    [self.tableView beginUpdates];

    BOOL fromFuture = NO;

    if (achievement.standardMilestone) {
        StandardMilestone *m = achievement.standardMilestone;
        NSInteger index = [_model indexOfFutureMilestone:m];
        NSIndexPath *removedIndexPath;
        if (index != NSNotFound) {
            fromFuture = YES;
            [_model markFutureMilestone:index ignored:NO postponed:NO]; // Removes it from the list
            removedIndexPath = [NSIndexPath indexPathForRow:index + (_model.hasMoreFutureMilestones ? 1 : 0) inSection:FutureMilestoneSection]; // add one for the loading row
            [reloadPaths addObjectsFromArray:[self reloadPathsForRemovedCell:removedIndexPath]];
        } else {
            index = [_model indexOfPastMilestone:m];
            if (index != NSNotFound) {
                [_model markPastMilestone:index ignored:NO postponed:NO]; // Removes it from the list
                removedIndexPath = [NSIndexPath indexPathForRow:index inSection:PastMilestoneSection];
                [reloadPaths addObjectsFromArray:[self reloadPathsForRemovedCell:removedIndexPath]];
            }
        }
        if (removedIndexPath) { // Index path might not exist if a milestone was noted during a search, and would not normally be shown.
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:removedIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
        }
    }

    NSInteger addedIndex = [_model addNewAchievement:achievement];
    if (addedIndex >= 0) { // Negative means it was not added to the view at all because it is after what is loaded in the model now.
        NSIndexPath *addedIndexPath = [NSIndexPath indexPathForRow:addedIndex inSection:AchievementSection];
        if ([self.tableView numberOfRowsInSection:AchievementSection] > addedIndex) {
            [self.tableView selectRowAtIndexPath:addedIndexPath animated:NO scrollPosition:fromFuture ? UITableViewScrollPositionBottom : UITableViewScrollPositionMiddle];
            [reloadPaths addObject:addedIndexPath];
        }
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:addedIndexPath] withRowAnimation:UITableViewRowAnimationRight];
    }


    [self.tableView reloadRowsAtIndexPaths:reloadPaths withRowAnimation:UITableViewRowAnimationNone];

    [self.tableView endUpdates];
    [CATransaction commit];
    [UIView commitAnimations];

    [self recalcHeaderCounts];

    // We want to gently encourage the user to sign up
    if (!ParentUser.currentUser.suppressLoginPrompt && ParentUser.currentUser.isAnonymous && _model.countOfAchievements % 3 == 0 && !_model.filter) {
        long x = _model.countOfAchievements / 3;
        if (((x != 0) && ((x & (~x + 1)) == x)) > 0) { // is power of 2
            [[[UIAlertView alloc] initWithTitle:@"Make sure your data is safe!"
                                        message:@"Do you want to sign up now so we can backup your milestones and photos in the cloud?"
                                       delegate:nil
                              cancelButtonTitle:@"Not Now"
                              otherButtonTitles:@"Yes", @"Never Ask Again", nil] showWithButtonBlock:^(NSInteger buttonIndex) {
                [UsageAnalytics trackSignupTrigger:@"promptAfterAchievementsLogged" withChoice:buttonIndex == 1];
                if (buttonIndex == 1) {
                    [SignUpOrLoginViewController presentSignUpInController:self andRunBlock:nil];
                } else if (buttonIndex == 2) {
                    // Don't ask again
                    [ParentUser currentUser].suppressLoginPrompt = YES;
                    [UsageAnalytics trackSettingChange:@"suppressLoginPrompt" withValue:@(YES)];
                    [[[UIAlertView alloc] initWithTitle:@"Just so you know..."
                                                message:@"We won't ask again, but you can always signup on the profile screen."
                                               delegate:nil
                                      cancelButtonTitle:@"Ok"
                                      otherButtonTitles:nil] show];

                }
            }];
        }
    }

}

- (void)handleAchievementNeedsUpdate:(NSNotification *)notification {
    [_model replaceAchievementIfLoaded:notification.object];
    [self.tableView reloadData];
}

- (void)handleAchievementNeedsDeletion:(NSNotification *)notification {
    MilestoneAchievement *achievement = notification.object;
    NSInteger idx = [_model indexOfAchievement:achievement];
    if (idx != NSNotFound) {
        NSIndexPath *path = [NSIndexPath indexPathForItem:idx inSection:AchievementSection];
        [self.tableView beginUpdates];
        [_model deleteAchievementAtIndex:path.row];
        [self.tableView deleteRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView reloadRowsAtIndexPaths:[self reloadPathsForRemovedCell:path] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
        [self recalcHeaderCounts];
        // Put the thing back in the milestone list.
        // TODO: Inject back into table, avoid reloading!
        if (achievement.standardMilestone) {
            // need to put this back into the list.
            [_model loadPastMilestonesPage:0];
            [_model loadFutureMilestonesPage:0];
        }
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutFloatingHeaders];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self layoutFloatingHeaders];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    CGFloat dir = [scrollView.panGestureRecognizer translationInView:scrollView.superview].y;
    _scrollStatus = (dir > 0) - (dir < 0);
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    CGFloat dir = [scrollView.panGestureRecognizer translationInView:scrollView.superview].y;
    _scrollStatus = (dir > 0) - (dir < 0);
}


- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self layoutFloatingHeaders];
    _isJumpingToIndex = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self checkAndLoadPendingNextPage];
    _scrollStatus = 0;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) { // if decelerate, handle when decelerated
        _scrollStatus = 0;
        [self checkAndLoadPendingNextPage];
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44;
}

- (HistoryTableHeaderView *)tableView:(UITableView *)tableView viewForFloatingHeaderInSection:(NSInteger)section {
    HistoryTableHeaderView *floater = [[HistoryTableHeaderView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, [self tableView:tableView heightForHeaderInSection:section])];
    floater.title = [_dataSource tableView:tableView titleForHeaderInSection:section];
    floater.count = [_model countOfFutureMilestones];

    floater.opaque = YES;
    floater.hidden = YES;
    floater.userInteractionEnabled = YES;
    UITapGestureRecognizer *viewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleHeaderTap:)];
    [floater addGestureRecognizer:viewTap];
    return floater;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    switch (section) {
        case FutureMilestoneSection:
            if (!_rovingFutureMilestonesHeaderView) {
                _rovingFutureMilestonesHeaderView = [[HistoryTableHeaderView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, [self tableView:tableView heightForHeaderInSection:section])];
                _rovingFutureMilestonesHeaderView.title = [_dataSource tableView:tableView titleForHeaderInSection:section];
                _rovingFutureMilestonesHeaderView.count = [_model countOfFutureMilestones];
            }
            return _rovingFutureMilestonesHeaderView;
        case PastMilestoneSection:
            if (!_rovingPastMilestonesHeaderView) {
                _rovingPastMilestonesHeaderView = [[HistoryTableHeaderView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, [self tableView:tableView heightForHeaderInSection:section])];
                _rovingPastMilestonesHeaderView.title = [_dataSource tableView:tableView titleForHeaderInSection:section];
                _rovingPastMilestonesHeaderView.count = [_model countOfPastMilestones];
            }
            return _rovingPastMilestonesHeaderView;
        case AchievementSection:
            if (!_rovingAchievementsHeaderView) {
                _rovingAchievementsHeaderView = [[HistoryTableHeaderView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, [self tableView:tableView heightForHeaderInSection:section])];
                _rovingAchievementsHeaderView.title = [_dataSource tableView:tableView titleForHeaderInSection:section];
                _rovingAchievementsHeaderView.count = [_model countOfAchievements];
            }
            return _rovingAchievementsHeaderView;
        default:
            NSAssert(NO, @"Invalid section type with number %ld", (long) section);
            return nil;
    }
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_isJumpingToIndex) return;

    switch (indexPath.section) {
        case FutureMilestoneSection:
            if (indexPath.row == PRELOAD_START_AT_IDX && _model.hasMoreFutureMilestones && !_model.isLoadingFutureMilestones) {
                _pendingNextPageTriggerIndex = indexPath;
            }
            break;
        case PastMilestoneSection:
            if (indexPath.row == _model.pastMilestones.count - PRELOAD_START_AT_IDX && _model.hasMorePastMilestones && !_model.isLoadingPastMilestones) {
                _pendingNextPageTriggerIndex = indexPath;
            }
            break;
        case AchievementSection:
            if (indexPath.row == _model.achievements.count - PRELOAD_START_AT_IDX && _model.hasMoreAchievements && !_model.isLoadingAchievements) {
                _pendingNextPageTriggerIndex = indexPath;
            }
            break;
        default:
            NSAssert(NO, @"Invalid section type with number %ld", (long) indexPath.section);
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isLoadingRow = NO;
    switch (indexPath.section) {
        case AchievementSection:
            isLoadingRow = indexPath.row == _model.achievements.count;
            if (isLoadingRow) {
                // Whether it is errored out of not, we want to try to force a reload
                [_model loadAchievementsPage:_model.achievements.count];
            } else {
                [self.delegate achievementClicked:_model.achievements[indexPath.row]];
            }
            break;
        case FutureMilestoneSection:
            isLoadingRow = indexPath.row == 0 && _model.hasMoreFutureMilestones;
            if (isLoadingRow) {
                // Whether it is errored out of not, we want to try to force a reload
                [_model loadFutureMilestonesPage:_model.futureMilestones.count];
            } else {
                [self.delegate standardMilestoneClicked:_model.futureMilestones[indexPath.row - (_model.hasMoreFutureMilestones ? 1 : 0)]];
            }
            break;
        case PastMilestoneSection:
            isLoadingRow = indexPath.row == _model.pastMilestones.count;
            if (isLoadingRow) {
                // Whether it is errored out of not, we want to try to force a reload
                [_model loadPastMilestonesPage:_model.pastMilestones.count];
            } else {
                [self.delegate standardMilestoneClicked:_model.pastMilestones[indexPath.row]];
            }
            break;
        default:
            NSAssert(NO, @"Invalid section type with number %ld", (long) _pendingNextPageTriggerIndex.section);
    }

    if (isLoadingRow) {
        [self.tableView reloadData]; // Show loading icon again...
    }
}


#pragma mark - SWTableViewDelegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)buttonIndex {

    NSIndexPath *path = [self.tableView indexPathForCell:cell];
    if (path.section == AchievementSection) {
        BOOL delete = buttonIndex == 0;
        if (delete) {
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationLeft];
            [self.tableView reloadRowsAtIndexPaths:[self reloadPathsForRemovedCell:path] withRowAnimation:UITableViewRowAnimationNone];
            MilestoneAchievement *deletedAchievement = [_model deleteAchievementAtIndex:path.row];
            [self.tableView endUpdates];
            [self recalcHeaderCounts];
            // Put the thing back in the milestone list.
            // TODO: Inject back into table, avoid reloading!
            if (deletedAchievement.standardMilestone) {
                // need to put this back into the list.
                [_model loadPastMilestonesPage:0];
                [_model loadFutureMilestonesPage:0];
            }
        }
    } else {
        BOOL ignored = buttonIndex == 0;
        BOOL postponed = buttonIndex == 1;
        BOOL noteIt = buttonIndex == 2;

        if (noteIt) {
            [self.delegate standardMilestoneClicked:((MilestoneTableViewCell *) cell).milestone];
            return;
        }

        if (ignored && ParentUser.currentUser.showIgnoredMilestones) {
            [[[UIAlertView alloc] initWithTitle:@"Can't do that" message:@"While showing ignored milestones you can not ignore a milestone. Turn off 'Show Ignored Milestones' in settings if you want to ignore this milestone." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            return;
        } else if (postponed && ParentUser.currentUser.showPostponedMilestones) {
            [[[UIAlertView alloc] initWithTitle:@"Can't do that" message:@"While showing postponed milestones you can not postpone a milestone. Turn off 'Show Postponed Milestones' in settings if you want to postponse this milestone." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            return;
        }

        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationLeft];


        [self.tableView reloadRowsAtIndexPaths:[self reloadPathsForRemovedCell:path] withRowAnimation:UITableViewRowAnimationNone];

        if (path.section == PastMilestoneSection) {
            [_model markPastMilestone:path.row ignored:ignored postponed:postponed];
        } else {
            NSInteger index = path.row - (_model.hasMoreFutureMilestones ? 1 : 0);  // adjust for first loading row.
            [_model markFutureMilestone:index ignored:ignored postponed:postponed];
        }
        [self.tableView endUpdates];
        [self recalcHeaderCounts];
    }
}

#pragma mark - HistoryViewTableModelDelegate

- (void)didLoadAchievementsAtPageIndex:(NSInteger)pageIndex {
    [self.tableView reloadData]; // use instead of relaod section which makes the table jump!
    [self recalcHeaderCounts];
    if (pageIndex == 0 && !_didInitialLoad) {
        [self scrollToFirstAchievement];
    }
}

- (void)didFailToLoadAchievements:(NSError *)error atPageIndex:(NSInteger)pageIndex {
    [UsageAnalytics trackError:error forOperationNamed:@"LoadAchievements" andAdditionalProperties:@{@"pageIndex" : @(pageIndex)}];
    [self.tableView reloadData]; // To show the new loading icon, displaying the error.
}

- (void)didLoadFutureMilestonesAtPageIndex:(NSInteger)pageIndex {
    [self.tableView reloadData]; // use instead of relaod section which makes the table jump!
    [self recalcHeaderCounts];
    if (pageIndex > 0) {
        if (_lastTableSize.height > 0) {
            CGPoint afterContentOffset = self.tableView.contentOffset;
            CGSize afterContentSize = self.tableView.contentSize;
            CGPoint newContentOffset = CGPointMake(afterContentOffset.x, afterContentOffset.y + afterContentSize.height - _lastTableSize.height);
            self.tableView.contentOffset = newContentOffset;
            _lastTableSize.height = 0; // reset it
        }
    } else if (!_didInitialLoad) {
        _didInitialLoad = YES;
        [self scrollToFirstAchievement];
    }
}

- (void)willLoadFutureMilestonesAtPageIndex:(NSInteger)pageIndex {
    // Mark the table size before the load begins
    _lastTableSize = self.tableView.contentSize;
}

- (void)didFailToLoadFutureMilestones:(NSError *)error atPageIndex:(NSInteger)pageIndex {
    [UsageAnalytics trackError:error forOperationNamed:@"LoadFutureMilestones" andAdditionalProperties:@{@"pageIndex" : @(pageIndex)}];
    [self.tableView reloadData]; // To show the new loading icon, displaying the error.
}

- (void)didLoadPastMilestonesAtPageIndex:(NSInteger)pageIndex {
    [self.tableView reloadData];
    [self recalcHeaderCounts];
    if (!_didInitialLoad) {
        [self scrollToFirstAchievement];
    }
}

- (void)didFailToLoadPastMilestones:(NSError *)error atPageIndex:(NSInteger)pageIndex {
    [UsageAnalytics trackError:error forOperationNamed:@"LoadPastMilestones" andAdditionalProperties:@{@"pageIndex" : @(pageIndex)}];
    [self.tableView reloadData]; // To show the new loading icon, displaying the error.
}


#pragma mark Floating Headers

- (void)recalcHeaderCounts {
    _floatingAchievementsHeaderView.count = _model.countOfAchievements;
    _floatingFutureMilestonesHeaderView.count = _model.countOfFutureMilestones;
    _floatingPastMilestonesHeaderView.count = _model.countOfPastMilestones;
    _rovingAchievementsHeaderView.count = _model.countOfAchievements;
    _rovingFutureMilestonesHeaderView.count = _model.countOfFutureMilestones;
    _rovingPastMilestonesHeaderView.count = _model.countOfPastMilestones;
}

- (void)layoutFloatingHeaders {
    // For some odd reason, before the table loads, on iphone 6, the width of the table is always 320 pixels
    // which makes the headers too small. So, we don't load the floating headers until the table has initially loaded.
    if(!_didInitialLoad) return;
    
    
    int tableHeight = self.tableView.frame.size.height;
    int futureMilestoneHeaderPosition = [self calculateHeaderPositionForSection:FutureMilestoneSection];
    int achievementHeaderPosition = [self calculateHeaderPositionForSection:AchievementSection];
    int pastMilestoneHeaderPosition = [self calculateHeaderPositionForSection:PastMilestoneSection];

    int futureMilestoneHeaderHeight = futureMilestoneHeaderPosition == INT_MIN ? 0 : [self tableView:self.tableView heightForHeaderInSection:FutureMilestoneSection];
    int achievementHeaderHeight = achievementHeaderPosition == INT_MIN ? 0 : [self tableView:self.tableView heightForHeaderInSection:AchievementSection];
    int pastMilestoneHeaderHeight = pastMilestoneHeaderPosition == INT_MIN ? 0 : [self tableView:self.tableView heightForHeaderInSection:PastMilestoneSection];


    BOOL futureMilestoneHeaderIsAbove = futureMilestoneHeaderPosition <= 0;
    BOOL achievementMilestoneHeaderIsAbove = achievementHeaderPosition <= futureMilestoneHeaderHeight;
    BOOL achievementMilestoneHeaderIsBelow = achievementHeaderPosition + achievementHeaderHeight >= tableHeight - pastMilestoneHeaderHeight;
    BOOL pastMilestoneHeaderIsAbove = pastMilestoneHeaderPosition <= futureMilestoneHeaderHeight + achievementHeaderHeight;
    BOOL pastMilestoneHeaderIsBelow = pastMilestoneHeaderPosition + pastMilestoneHeaderHeight >= tableHeight;

    // Future Header
    if (!futureMilestoneHeaderHeight) {
        // No rows in section, hide the floating header.
        _floatingFutureMilestonesHeaderView.hidden = YES;
    } else {
        if (!_floatingFutureMilestonesHeaderView) {
            _floatingFutureMilestonesHeaderView = [self tableView:self.tableView viewForFloatingHeaderInSection:FutureMilestoneSection];
            [self.tableView.superview insertSubview:_floatingFutureMilestonesHeaderView aboveSubview:self.tableView];
        }
        _floatingFutureMilestonesHeaderView.position = 0;
        _floatingFutureMilestonesHeaderView.hidden = !futureMilestoneHeaderIsAbove;
        _floatingFutureMilestonesHeaderView.highlighted = !achievementMilestoneHeaderIsAbove;
    }

    // Achievement Header
    if (!achievementHeaderHeight) {
        // No rows in section, hide the floating header.
        _floatingAchievementsHeaderView.hidden = YES;
    } else {
        if (!_floatingAchievementsHeaderView) {
            _floatingAchievementsHeaderView = [self tableView:self.tableView viewForFloatingHeaderInSection:AchievementSection];
            [self.tableView.superview insertSubview:_floatingAchievementsHeaderView aboveSubview:self.tableView];
        }


        _floatingAchievementsHeaderView.hidden = !(achievementMilestoneHeaderIsAbove || achievementMilestoneHeaderIsBelow);
        _floatingAchievementsHeaderView.position = achievementMilestoneHeaderIsBelow ? tableHeight - (achievementHeaderHeight + pastMilestoneHeaderHeight) : futureMilestoneHeaderHeight;
        _floatingAchievementsHeaderView.highlighted = achievementMilestoneHeaderIsAbove && !pastMilestoneHeaderIsAbove;
    }

    // Past Header
    if (!pastMilestoneHeaderHeight) {
        // No rows in section, hide the floating header.
        _floatingPastMilestonesHeaderView.hidden = YES;
    } else {
        if (!_floatingPastMilestonesHeaderView.superview) {
            _floatingPastMilestonesHeaderView = [self tableView:self.tableView viewForFloatingHeaderInSection:PastMilestoneSection];
            [self.tableView.superview insertSubview:_floatingPastMilestonesHeaderView aboveSubview:self.tableView];
        }
        _floatingPastMilestonesHeaderView.hidden = !(pastMilestoneHeaderIsAbove || pastMilestoneHeaderIsBelow);
        _floatingPastMilestonesHeaderView.position = pastMilestoneHeaderIsBelow ? tableHeight - pastMilestoneHeaderHeight : futureMilestoneHeaderHeight + achievementHeaderHeight;
        _floatingPastMilestonesHeaderView.highlighted = !pastMilestoneHeaderIsBelow;
    }
}

- (int)calculateHeaderPositionForSection:(NSInteger)section {
    if ([self.tableView numberOfRowsInSection:section] < 1) return INT_MIN;
    int headerHeight = [self tableView:self.tableView heightForHeaderInSection:section];
    CGRect rectInTableView = [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
    CGRect rectInSuperview = [self.tableView convertRect:rectInTableView toView:self.tableView.superview];
    return rectInSuperview.origin.y - headerHeight;
}


- (void)handleHeaderTap:(id)sender {
    if (_scrollStatus == 0 && !_isJumpingToIndex) { // Only if done scrolling.
        int futureMilestoneHeaderHeight = [self tableView:self.tableView heightForHeaderInSection:0];
        int achievementHeaderHeight = [self tableView:self.tableView heightForHeaderInSection:1];
        int pastMilestoneHeaderHeight = [self tableView:self.tableView heightForHeaderInSection:2];

        UITapGestureRecognizer *recognizer = sender;
        if (recognizer.view == _floatingFutureMilestonesHeaderView) {
            long lastRow = [self.tableView numberOfRowsInSection:0] - 1;
            NSIndexPath *path = [NSIndexPath indexPathForRow:lastRow inSection:FutureMilestoneSection];
            int rowHeight = [self tableView:self.tableView heightForRowAtIndexPath:path];
            int headerPosY = [self.tableView rectForRowAtIndexPath:path].origin.y - (self.tableView.bounds.size.height - (achievementHeaderHeight + pastMilestoneHeaderHeight + rowHeight));
            if (self.tableView.contentOffset.y != headerPosY) {
                _isJumpingToIndex = YES;
                [self.tableView setContentOffset:CGPointMake(0, headerPosY) animated:YES];
            }

//      [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:lastRow inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        } else if (recognizer.view == _floatingAchievementsHeaderView) {
            int headerPosY = [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:AchievementSection]].origin.y - (futureMilestoneHeaderHeight + achievementHeaderHeight);
            if (self.tableView.contentOffset.y != headerPosY) {
                _isJumpingToIndex = YES;
                [self.tableView setContentOffset:CGPointMake(0, headerPosY) animated:YES];
            }
        } else if (recognizer.view == _floatingPastMilestonesHeaderView) {
            int headerPosY = [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:PastMilestoneSection]].origin.y - (futureMilestoneHeaderHeight + achievementHeaderHeight + pastMilestoneHeaderHeight);
            if (self.tableView.contentOffset.y != headerPosY) {
                _isJumpingToIndex = YES;
                [self.tableView setContentOffset:CGPointMake(0, headerPosY) animated:YES];
            }
        }
    }
}

#pragma mark Utility Methods

- (void)scrollToFirstAchievement {
    NSIndexPath *scrollRow = [NSIndexPath indexPathForRow:0 inSection:AchievementSection];
    if ([self.tableView numberOfRowsInSection:AchievementSection] > 0) {
        [self.tableView scrollToRowAtIndexPath:scrollRow atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    } else if ([self.tableView numberOfRowsInSection:FutureMilestoneSection] > 0) {
        scrollRow = [NSIndexPath indexPathForRow:[self.tableView numberOfRowsInSection:FutureMilestoneSection] - 1 inSection:FutureMilestoneSection];
        [self.tableView scrollToRowAtIndexPath:scrollRow atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    }
}

- (NSMutableArray *)reloadPathsForRemovedCell:(NSIndexPath *)path {
    NSMutableArray *reloadPaths = [NSMutableArray array];
    NSInteger numRows = [self.tableView numberOfRowsInSection:path.section];
    if (path.row == numRows - 1 && numRows > 1) {
        [reloadPaths addObject:[NSIndexPath indexPathForRow:path.row - 1 inSection:path.section]];
    }
    if (path.row == 0 && numRows > 1) {
        [reloadPaths addObject:[NSIndexPath indexPathForRow:path.row + 1 inSection:path.section]];
    }
    return reloadPaths;
}

- (void)checkAndLoadPendingNextPage {
    if ([self.tableView.indexPathsForVisibleRows containsObject:_pendingNextPageTriggerIndex]) {
        switch (_pendingNextPageTriggerIndex.section) {
            case FutureMilestoneSection:
                if (!_model.isLoadingFutureMilestones) [_model loadFutureMilestonesPage:_model.futureMilestones.count];
                break;
            case PastMilestoneSection:
                if (!_model.isLoadingPastMilestones) [_model loadPastMilestonesPage:_model.pastMilestones.count];
                break;
            case AchievementSection:
                if (!_model.isLoadingAchievements) [_model loadAchievementsPage:_model.achievements.count];
                break;
            default:
                NSAssert(NO, @"Invalid section type with number %ld", (long) _pendingNextPageTriggerIndex.section);
        }
    }
    _pendingNextPageTriggerIndex = nil;
}


@end
