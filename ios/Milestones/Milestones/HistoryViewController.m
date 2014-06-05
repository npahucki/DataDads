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



@interface HistoryViewController () {
  CGSize _lastTableSize;
  BOOL _initialAchievementsLoaded;
  BOOL _initialFutureMilestonesLoaded;
  BOOL _initialPastMilestonesLoaded;
  
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

-(void) reloadTable {
    _initialAchievementsLoaded = NO;
    [_model loadAchievementsPage:0];

    _initialFutureMilestonesLoaded = NO;
    [_model loadFutureMilestonesPage:0];

    _initialPastMilestonesLoaded = NO;
    [_model loadPastMilestonesPage:0];
}

-(void) babyUpdated:(NSNotification*)notification {
  if(Baby.currentBaby) {
    self.baby = Baby.currentBaby;
  }
}

-(void) setBaby:(Baby*) baby {
  self.navigationItem.title = Baby.currentBaby.name;
  _model.baby = Baby.currentBaby;
  [self reloadTable];
}


-(void) milestoneNotedAndSaved:(NSNotification*)notification {
  MilestoneAchievement * achievement = [notification.userInfo objectForKey:@""];
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



#pragma mark - UITableViewDelegate

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
    // TODO: something here, maybe share by email later?
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





@end
