//
//  HistoryViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/11/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

// TODO:
// Handle low memory by releasing past milestones not being looked at.

#import "HistoryViewController.h"
#import "HistoryViewControllerDataSource.h"
#import <FacebookSDK/FBSession.h>
#import "NSDate+Utils.h"

#define PRELOAD_START_AT_IDX 1



@interface HistoryHeaderView : UIView
@property (weak, nonatomic) UILabel * label;

-(void) setHighlighted:(BOOL)highlighted;
-(void) setPosition:(int) position;

@end

@implementation HistoryHeaderView {
  BOOL _highlighted;
}

-(void) setHighlighted:(BOOL)highlighted {
  if(highlighted != _highlighted) {
    _highlighted = highlighted;
    _label.font = [UIFont fontForAppWithType:highlighted ? Bold : Book andSize:17];
  }
}

-(void) setPosition:(int)position {
  self.frame = CGRectMake(0,position, self.bounds.size.width, self.bounds.size.height);
}

@end


@interface HistoryViewController () {
  CGSize _lastTableSize;
  BOOL _initialAchievementsLoaded;
  BOOL _initialFutureMilestonesLoaded;
  BOOL _initialPastMilestonesLoaded;
  
  
  HistoryHeaderView * _floatingAchievementsHeaderView;
  HistoryHeaderView * _floatingPastMilestonesHeaderView;
  HistoryHeaderView * _floatingFutureMilestonesHeaderView;
  
  NSIndexPath * _pendingNextPageTriggerIndex;
  BOOL _isJumpingToIndex;
  
}

@end

@implementation HistoryViewController {
  HistoryViewTableModel * _model;
  HistoryViewControllerDataSource * _dataSource; // Need reference to retain it
}

-(void) viewDidLoad {
  [super viewDidLoad];
  _model = [[HistoryViewTableModel alloc] init];
  _model.delegate = self;
  _model.pagingSize = 10;
  _dataSource = [[HistoryViewControllerDataSource alloc] init];
  _dataSource.model = _model;
  _dataSource.cellSwipeDelegate = self;
  self.tableView.dataSource = _dataSource;
  self.tableView.delegate = self;
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(babyUpdated:) name:kDDNotificationCurrentBabyChanged object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(milestoneNotedAndSaved:) name:kDDNotificationMilestoneNotedAndSaved object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkReachabilityChanged:) name:kReachabilityChangedNotification object:nil];
  
  if(Baby.currentBaby) { // Only load if there is already a baby set
    self.baby = Baby.currentBaby;
  }
}

-(void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) networkReachabilityChanged:(NSNotification*)notification {
  if([self isInitialLoadComplete]) {
    [self.tableView reloadData];
  } else {
    if([Reachability isParseCurrentlyReachable] && _model.baby) {
      [self reloadTable];
    }
  }
}

-(void) setFilterString:(NSString *)filterString {
  _initialAchievementsLoaded = NO;
  _initialFutureMilestonesLoaded  = NO;
  _initialPastMilestonesLoaded = NO;
  _model.filter = filterString;
}

-(NSString*) filterString {
  return _model.filter;
}

-(void) reloadTable {
    _initialAchievementsLoaded = NO;
    [_model loadAchievementsPage:0];

    _initialFutureMilestonesLoaded = NO;
    [_model loadFutureMilestonesPage:0];

    _initialPastMilestonesLoaded = NO;
    [_model loadPastMilestonesPage:0];
}

-(void) babyUpdated:(NSNotification*)notification {
  self.baby = Baby.currentBaby;
}

-(void) setBaby:(Baby*) baby {
  if(baby == nil) {
    // Logged out
    self.navigationItem.title = nil;
    [_model reset];
  } else {
    self.navigationItem.title = Baby.currentBaby.name;
    _model.baby = Baby.currentBaby;
  }
  [self reloadTable];
}


-(void) milestoneNotedAndSaved:(NSNotification*)notification {
  MilestoneAchievement * achievement = notification.object;
  NSMutableArray * reloadPaths = [NSMutableArray arrayWithCapacity:5];
  [UIView beginAnimations:@"insertAnimationId" context:nil];
  [UIView setAnimationDuration:1.0]; // Set duration here
  [CATransaction begin];
  [self.tableView beginUpdates];

  BOOL fromFuture;
  
  if(achievement.standardMilestone) {
    StandardMilestone * m = achievement.standardMilestone;
    NSInteger index = [_model indexOfFutureMilestone:m];
    NSIndexPath* removedIndexPath;
    if(index != NSNotFound) {
      fromFuture = YES;
      [_model markFutureMilestone:index ignored:NO postponed:NO]; // Removes it from the list
      removedIndexPath = [NSIndexPath indexPathForRow:index + (_model.hasMoreFutureMilestones ? 1 : 0) inSection:FutureMilestoneSection]; // add one for the loading row
      [reloadPaths addObjectsFromArray:[self reloadPathsForRemovedCell:removedIndexPath]];
    } else {
      index = [_model indexOfPastMilestone:m];
      if(index != NSNotFound) {
        [_model  markPastMilestone:index ignored:NO postponed:NO]; // Removes it from the list
        removedIndexPath = [NSIndexPath indexPathForRow:index inSection:PastMilestoneSection];
        [reloadPaths addObjectsFromArray:[self reloadPathsForRemovedCell:removedIndexPath]];
      }
    }
    NSAssert(removedIndexPath,@"Milestone was not found in past or future!");
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:removedIndexPath]  withRowAnimation:UITableViewRowAnimationLeft];
  }
  
  NSInteger addedIndex = [_model addNewAchievement:achievement];
  if(addedIndex >= 0) { // Negative means it was not added to the view at all because it is after what is loaded in the model now.
    NSIndexPath* addedIndexPath = [NSIndexPath indexPathForRow:addedIndex inSection:AchievementSection];
    if([self.tableView numberOfRowsInSection:AchievementSection] > addedIndex) {
      [self.tableView selectRowAtIndexPath:addedIndexPath animated:NO scrollPosition:fromFuture ? UITableViewScrollPositionBottom : UITableViewScrollPositionMiddle];
      [reloadPaths addObject:addedIndexPath];
    }
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:addedIndexPath] withRowAnimation:UITableViewRowAnimationRight];
  }
  

  [self.tableView reloadRowsAtIndexPaths:reloadPaths withRowAnimation:UITableViewRowAnimationNone];
  
  [self.tableView endUpdates];
  [CATransaction commit];
  [UIView commitAnimations];

}

-(void) viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  [self layoutFloatingHeaders];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  [self layoutFloatingHeaders];
}

-(void) scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
  [self layoutFloatingHeaders];
  _isJumpingToIndex = NO;
}

-(void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  [self checkAndLoadPendingNextPage];
}

-(void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  if(!decelerate) [self checkAndLoadPendingNextPage]; // if decelerate, handle when decelerated
}

#pragma mark - UITableViewDelegate

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 36;
}

-(HistoryHeaderView *)tableView:(UITableView *)tableView viewForFloatingHeaderInSection:(NSInteger)section {
  HistoryHeaderView * floater = [[HistoryHeaderView alloc] initWithFrame:CGRectMake(0,0,tableView.frame.size.width,[self tableView:tableView heightForHeaderInSection:section])];
  floater.label  = (UILabel*)[self tableView:self.tableView viewForHeaderInSection:section];
  [floater addSubview:floater.label];
  floater.backgroundColor = self.tableView.backgroundColor;
  floater.opaque = YES;
  floater.hidden = YES;
  floater.alpha = .95;
  floater.userInteractionEnabled = YES;
  UITapGestureRecognizer *viewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleHeaderTap:)];
  [floater addGestureRecognizer:viewTap];
  return floater;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
  int height = [self tableView:self.tableView heightForHeaderInSection:section];
  UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, height)];
  label.textAlignment = NSTextAlignmentCenter;
  [label setFont:[UIFont fontForAppWithType:Bold andSize:17]];
  label.text = [_dataSource tableView:tableView titleForHeaderInSection:section];
  label.textColor = [UIColor appNormalColor];
  return label;
}


-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  if(_isJumpingToIndex) return;
  
  switch (indexPath.section) {
    case FutureMilestoneSection:
      if(indexPath.row == PRELOAD_START_AT_IDX && _model.hasMoreFutureMilestones && !_model.isLoadingFutureMilestones) {
        _pendingNextPageTriggerIndex = indexPath;
      }
      break;
    case PastMilestoneSection:
      if(indexPath.row == _model.pastMilestones.count - PRELOAD_START_AT_IDX && _model.hasMorePastMilestones && !_model.isLoadingPastMilestones) {
        _pendingNextPageTriggerIndex = indexPath;
      }
      break;
    case AchievementSection:
      if(indexPath.row == _model.achievements.count - PRELOAD_START_AT_IDX && _model.hasMoreAchievements && !_model.isLoadingAchievements) {
        _pendingNextPageTriggerIndex = indexPath;
      }
      break;
    default:
      NSAssert(NO,@"Invalid section type with numer %ld", (long)indexPath.section);
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  BOOL isLoadingRow;
  switch (indexPath.section) {
    case AchievementSection:
      isLoadingRow = indexPath.row == _model.achievements.count;
      if(!isLoadingRow) [self.delegate achievementClicked:_model.achievements[indexPath.row]];
      break;
    case FutureMilestoneSection:
      isLoadingRow = indexPath.row == 0 && _model.hasMoreFutureMilestones;
      if(!isLoadingRow) [self.delegate standardMilestoneClicked:_model.futureMilestones[indexPath.row - (_model.hasMoreFutureMilestones ? 1 : 0)]];
      break;
    case PastMilestoneSection:
      isLoadingRow = indexPath.row == _model.pastMilestones.count;
      if(!isLoadingRow) [self.delegate standardMilestoneClicked:_model.pastMilestones[indexPath.row]];
      break;
    default:
      break;
  }
}


#pragma mark - SWTableViewDelegate
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)buttonIndex {

  NSIndexPath * path = [self.tableView indexPathForCell:cell];
  if(path.section == AchievementSection) {
    BOOL delete = buttonIndex == 0;
    if(delete) {
      [self.tableView beginUpdates];
      [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationLeft];
      [self.tableView reloadRowsAtIndexPaths:[self reloadPathsForRemovedCell:path] withRowAnimation:UITableViewRowAnimationNone];
      MilestoneAchievement * deletedAchievement = [_model deleteAchievementAtIndex:path.row];
      [self.tableView endUpdates];
      // Put the thing back in the milestone list. 
      if(deletedAchievement.standardMilestone) {
        // need to put this back into the list.
        if(_model.baby.daysSinceDueDate >= [deletedAchievement.standardMilestone.rangeHigh integerValue]) {
          [_model loadPastMilestonesPage:0];
        } else {
          [_model loadFutureMilestonesPage:0];
        }
      }
    }
  } else {
    BOOL ignored = buttonIndex == 0;
    BOOL postponed = buttonIndex == 1;
    
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationLeft];

    
    [self.tableView reloadRowsAtIndexPaths:[self reloadPathsForRemovedCell:path] withRowAnimation:UITableViewRowAnimationNone];
    
    if(path.section == PastMilestoneSection) {
      [_model markPastMilestone:path.row ignored:ignored postponed:postponed];
    } else {
      NSInteger index = path.row - (_model.hasMoreFutureMilestones ? 1 : 0);  // adjust for first loading row.
      [_model markFutureMilestone:index ignored:ignored postponed:postponed];
    }
    [self.tableView endUpdates];
  }
}

#pragma mark - HistoryViewTableModelDelegate

-(void) didLoadAchievements {
  [self.tableView reloadData];
  if(_initialAchievementsLoaded) {
  } else {
    _initialAchievementsLoaded = YES;
    [self scrollToFirstAchievement];
  }
}

-(void) didFailToLoadAchievements:(NSError *) error {
  NSLog(@"Failed to load achievements %@", error);
}

-(void) didLoadFutureMilestones {
  [self.tableView reloadData]; // use instead of relaod section which makes the table jump!
  if(_initialFutureMilestonesLoaded) {
    if(_lastTableSize.height > 0) {
      CGPoint afterContentOffset = self.tableView.contentOffset;
      CGSize afterContentSize = self.tableView.contentSize;
      CGPoint newContentOffset = CGPointMake(afterContentOffset.x, afterContentOffset.y + afterContentSize.height - _lastTableSize.height);
      self.tableView.contentOffset = newContentOffset;
      _lastTableSize.height = 0; // reset it
    }
  } else {
    _initialFutureMilestonesLoaded = YES;
    [self scrollToFirstAchievement];
  }
}

-(void) willLoadFutureMilestones:(NSInteger)startIdx {
  // Mark the table size before the load begins
  _lastTableSize = self.tableView.contentSize;
}

-(void) didFailToLoadFutureMilestones:(NSError *) error {
  NSLog(@"Failed to future milestones %@", error);
}

-(void) didLoadPastMilestones {
  [self.tableView reloadData];
  if(!_initialPastMilestonesLoaded) {
    _initialPastMilestonesLoaded = YES;
    [self scrollToFirstAchievement];
  }
}

-(void) didFailToLoadPastMilestones:(NSError *) error {
  NSLog(@"Failed to past milestones %@", error);
  
}

#pragma mark Floating Headers

-(void) layoutFloatingHeaders {
  int tableHeight = self.tableView.frame.size.height;
  
  int futureMilestoneHeaderHeight = [self tableView:self.tableView heightForHeaderInSection:FutureMilestoneSection];
  int achievementHeaderHeight = [self tableView:self.tableView heightForHeaderInSection:AchievementSection];
  int pastMilestoneHeaderHeight = [self tableView:self.tableView heightForHeaderInSection:PastMilestoneSection];
  
  int futureMilestoneHeaderPosition = [self calculateHeaderPostionForSection:FutureMilestoneSection];
  int achievementMilestoneHeaderPosition = [self calculateHeaderPostionForSection:AchievementSection];
  int pastMilestoneHeaderPosition = [self calculateHeaderPostionForSection:PastMilestoneSection];
  
  BOOL futureMilestoneHeaderIsAbove = futureMilestoneHeaderPosition <= 0;
  BOOL achievementMilestoneHeaderIsAbove = achievementMilestoneHeaderPosition <= futureMilestoneHeaderHeight;
  BOOL achievementMilestoneHeaderIsBelow = achievementMilestoneHeaderPosition + achievementHeaderHeight >= self.tableView.frame.size.height - pastMilestoneHeaderHeight;
  BOOL pastMilestoneHeaderHeightIsAbove = pastMilestoneHeaderPosition <= futureMilestoneHeaderHeight + achievementHeaderHeight;
  BOOL pastMilestoneHeaderHeightIsBelow = pastMilestoneHeaderPosition + pastMilestoneHeaderHeight >= self.tableView.frame.size.height;
  
  // Future Header
  if(futureMilestoneHeaderPosition == MAXFLOAT) {
    // No rows in section, hide the floating header.
    _floatingFutureMilestonesHeaderView.hidden = YES;
  } else {
    if(!_floatingFutureMilestonesHeaderView) {
      _floatingFutureMilestonesHeaderView = [self tableView:self.tableView viewForFloatingHeaderInSection:FutureMilestoneSection];
      [self.tableView.superview insertSubview:_floatingFutureMilestonesHeaderView aboveSubview:self.tableView];
    }
    if(futureMilestoneHeaderIsAbove && _floatingFutureMilestonesHeaderView.hidden) {
      _floatingFutureMilestonesHeaderView.position = 0;
      _floatingFutureMilestonesHeaderView.hidden = NO;
    } else if(!futureMilestoneHeaderIsAbove && !_floatingAchievementsHeaderView.hidden) {
      _floatingFutureMilestonesHeaderView.hidden = YES;
    }
    _floatingFutureMilestonesHeaderView.highlighted = !achievementMilestoneHeaderIsAbove;
  }
  
  // Achievement Header
  if(achievementMilestoneHeaderPosition == MAXFLOAT) {
    // No rows in section, hide the floating header.
    _floatingAchievementsHeaderView.hidden = YES;
  } else {
    if(!_floatingAchievementsHeaderView) {
      _floatingAchievementsHeaderView = [self tableView:self.tableView viewForFloatingHeaderInSection:AchievementSection];
      [self.tableView.superview insertSubview:_floatingAchievementsHeaderView aboveSubview:self.tableView];
    }
    if((achievementMilestoneHeaderIsAbove || achievementMilestoneHeaderIsBelow) && _floatingAchievementsHeaderView.hidden) {
      _floatingAchievementsHeaderView.position = achievementMilestoneHeaderIsBelow ? tableHeight - (achievementHeaderHeight + pastMilestoneHeaderHeight) : futureMilestoneHeaderHeight;
      _floatingAchievementsHeaderView.hidden = NO;
    } else if(!achievementMilestoneHeaderIsBelow && !achievementMilestoneHeaderIsAbove && !_floatingAchievementsHeaderView.hidden) {
      _floatingAchievementsHeaderView.hidden = YES;
    }
    _floatingAchievementsHeaderView.highlighted = achievementMilestoneHeaderIsAbove && !pastMilestoneHeaderHeightIsAbove;
  }
  
  // Past Header
  if(pastMilestoneHeaderPosition == MAXFLOAT) {
    // No rows in section, hide the floating header.
    _floatingPastMilestonesHeaderView.hidden = YES;
  } else {
    if(!_floatingPastMilestonesHeaderView.superview) {
      _floatingPastMilestonesHeaderView = [self tableView:self.tableView viewForFloatingHeaderInSection:PastMilestoneSection];
      [self.tableView.superview insertSubview:_floatingPastMilestonesHeaderView aboveSubview:self.tableView];
    }
    if((pastMilestoneHeaderHeightIsAbove || pastMilestoneHeaderHeightIsBelow) && _floatingPastMilestonesHeaderView.hidden) {
      _floatingPastMilestonesHeaderView.position = pastMilestoneHeaderHeightIsBelow ? tableHeight - pastMilestoneHeaderHeight : futureMilestoneHeaderHeight + achievementHeaderHeight;
      _floatingPastMilestonesHeaderView.hidden = NO;
      _floatingPastMilestonesHeaderView.highlighted = pastMilestoneHeaderHeightIsAbove;
    } else if(!pastMilestoneHeaderHeightIsBelow && !pastMilestoneHeaderHeightIsAbove && !_floatingPastMilestonesHeaderView.hidden) {
      _floatingPastMilestonesHeaderView.hidden = YES;
    }
  }
}

-(CGFloat) calculateHeaderPostionForSection:(NSInteger) section {
  if([self.tableView numberOfRowsInSection:section] < 1 ) return MAXFLOAT;
  int headerHeight = [self tableView:self.tableView heightForHeaderInSection:section];
  CGRect rectInTableView = [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
  CGRect rectInSuperview = [self.tableView convertRect:rectInTableView toView:self.tableView.superview];
  return rectInSuperview.origin.y - headerHeight;
}


-(void) handleHeaderTap:(id) sender {
  int futureMilestoneHeaderHeight = [self tableView:self.tableView heightForHeaderInSection:0];
  int achievementHeaderHeight = [self tableView:self.tableView heightForHeaderInSection:1];
  int pastMilestoneHeaderHeight = [self tableView:self.tableView heightForHeaderInSection:2];
  
  UITapGestureRecognizer * recognizer = sender;
  if(recognizer.view == _floatingFutureMilestonesHeaderView) {
    _isJumpingToIndex = YES;
    int lastRow = [self.tableView numberOfRowsInSection:0] - 1;
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:lastRow inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
  } else if(recognizer.view == _floatingAchievementsHeaderView) {
    _isJumpingToIndex = YES;
    int headerPosY = [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]].origin.y - (futureMilestoneHeaderHeight + achievementHeaderHeight);
    [self.tableView setContentOffset:CGPointMake(0, headerPosY) animated:YES];
  } else if(recognizer.view == _floatingPastMilestonesHeaderView) {
    _isJumpingToIndex = YES;
    int headerPosY = [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]].origin.y - (futureMilestoneHeaderHeight + achievementHeaderHeight + pastMilestoneHeaderHeight);
    [self.tableView setContentOffset:CGPointMake(0, headerPosY) animated:YES];
  }
}

#pragma mark Utility Methods

-(BOOL) isInitialLoadComplete {
  return _initialAchievementsLoaded && _initialFutureMilestonesLoaded && _initialPastMilestonesLoaded;
}

-(void) scrollToFirstAchievement {
  NSIndexPath * scrollRow = [NSIndexPath indexPathForRow:0 inSection:AchievementSection];
  if([self.tableView numberOfRowsInSection:AchievementSection] > 0) {
    [self.tableView scrollToRowAtIndexPath:scrollRow atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
  } else if([self.tableView numberOfRowsInSection:FutureMilestoneSection] > 0) {
    scrollRow = [NSIndexPath indexPathForRow:[self.tableView numberOfRowsInSection:FutureMilestoneSection] - 1 inSection:FutureMilestoneSection];
    [self.tableView scrollToRowAtIndexPath:scrollRow atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
  }
}

-(NSMutableArray*) reloadPathsForRemovedCell:(NSIndexPath*) path {
  NSMutableArray * reloadPaths = [NSMutableArray array];
  NSInteger numRows = [self.tableView numberOfRowsInSection:path.section];
  if(path.row == numRows - 1 && numRows > 1) {
    [reloadPaths addObject:[NSIndexPath indexPathForRow:path.row - 1 inSection:path.section]];
  }
  if(path.row == 0 && numRows > 1) {
    [reloadPaths addObject:[NSIndexPath indexPathForRow:path.row + 1 inSection:path.section]];
  }
  return reloadPaths;
}

-(void) checkAndLoadPendingNextPage {
  if(_pendingNextPageTriggerIndex) {
    NSLog(@"Checking pending load request %d:%d", _pendingNextPageTriggerIndex.section, _pendingNextPageTriggerIndex.row);
    for(NSIndexPath * path in self.tableView.indexPathsForVisibleRows) {
      NSLog(@"Visible: %d:%d", path.section, path.row);
    }
  }
  
  if([self.tableView.indexPathsForVisibleRows containsObject:_pendingNextPageTriggerIndex]) {
    switch (_pendingNextPageTriggerIndex.section) {
      case FutureMilestoneSection:
        if(!_model.isLoadingFutureMilestones) [_model loadFutureMilestonesPage:_model.futureMilestones.count];
        break;
      case PastMilestoneSection:
        if(!_model.isLoadingPastMilestones) [_model loadPastMilestonesPage:_model.pastMilestones.count];
        break;
      case AchievementSection:
        if(!_model.isLoadingAchievements) [_model loadAchievementsPage:_model.achievements.count];
        break;
      default:
        NSAssert(NO,@"Invalid section type with numer %ld", (long)_pendingNextPageTriggerIndex.section);
    }
  }
  _pendingNextPageTriggerIndex = nil;
}






@end
