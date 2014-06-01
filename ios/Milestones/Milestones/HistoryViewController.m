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
#import "NSDate+HumanizedTime.h"

#define IMG_SIZE CGSizeMake(54,54)
#define PRELOAD_START_AT_IDX 3

typedef NS_ENUM(NSInteger, HistorySectionType) {
  FutureMilestoneSection,
  AchievementSection,
  PastMilestoneSection
};

@interface HistoryViewController () {
  CGSize _lastTableSize;
  BOOL _initialAchievementsLoaded;
  BOOL _initialFutureMilestonesLoaded;
  BOOL _initialPastMilestonesLoaded;
  
}

@end

@implementation HistoryViewController {
  HistoryViewTableModel * _model;
}

// TODO: Index based on time?

-(void) viewDidLoad {
  [super viewDidLoad];
   _model = [[HistoryViewTableModel alloc] init];
  _model.delegate = self;
  _model.pagingSize = 10;

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

#pragma mark - UITableViewDelegate - Headers


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  switch (section) {
    case FutureMilestoneSection:
      return _model.futureMilestones.count + (_model.hasMoreFutureMilestones ? 1 : 0);
    case PastMilestoneSection:
      return _model.pastMilestones.count + (_model.hasMorePastMilestones ? 1 : 0);
    case AchievementSection:
      return _model.achievements.count + (_model.hasMoreAchievements ? 1 : 0);
    default:
      NSAssert(NO,@"Invalid section type with numer %ld", (long)section);
      return 0;
  }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  switch (section) {
    case FutureMilestoneSection:
      return @"Upcoming Milestones";
    case PastMilestoneSection:
      return @"Past Milestones";
    case AchievementSection:
      return @"Completed Milestones";
    default:
      NSAssert(NO,@"Invalid section type with numer %ld", (long)section);
      return nil;
  }
  
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
  UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 18)];
  label.textAlignment = NSTextAlignmentCenter;
  [label setFont:[UIFont fontForAppWithType:Book andSize:17]];
  label.text =  [self tableView:tableView titleForHeaderInSection:section];
  label.textColor = [UIColor appNormalColor];
  [label sizeToFit];
  return label;
}

#pragma mark - UITableViewControllerDataSource - Cells

-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  
  switch (indexPath.section) {
    case FutureMilestoneSection:
      if(indexPath.row == PRELOAD_START_AT_IDX && _model.hasMoreFutureMilestones && !_model.isLoadingFutureMilestones) {
        _lastTableSize = self.tableView.contentSize;
        [_model loadFutureMilestonesPage:_model.futureMilestones.count];
      }
      break;
    case PastMilestoneSection:
      if(indexPath.row == _model.pastMilestones.count - PRELOAD_START_AT_IDX && _model.hasMorePastMilestones && !_model.isLoadingPastMilestones) {
        [_model loadPastMilestonesPage:_model.pastMilestones.count];
      }
      break;
    case AchievementSection:
      if(indexPath.row == _model.achievements.count - PRELOAD_START_AT_IDX && _model.hasMoreAchievements && !_model.isLoadingAchievements) {
        [_model loadAchievementsPage:_model.achievements.count];
      }
      break;
    default:
      NSAssert(NO,@"Invalid section type with numer %ld", (long)indexPath.section);
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  switch (indexPath.section) {
    case FutureMilestoneSection:
      if (indexPath.row == 0 && _model.hasMoreFutureMilestones)
        return [self tableView:tableView cellForLoadingIndicator:indexPath];
      else {
        if(_model.hasMoreFutureMilestones) {
          indexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
        }
        return [self tableView:tableView cellForMilestone:_model.futureMilestones[indexPath.row] atIndexPath:indexPath];
      }
  case PastMilestoneSection:
      if (indexPath.row == _model.pastMilestones.count)
        return [self tableView:tableView cellForLoadingIndicator:indexPath];
      else
        return [self tableView:tableView cellForMilestone:_model.pastMilestones[indexPath.row] atIndexPath:indexPath];
    case AchievementSection:
      if (indexPath.row == _model.achievements.count)
        return [self tableView:tableView cellForLoadingIndicator:indexPath];
      else
        return [self tableView:tableView cellForAchievement:_model.achievements[indexPath.row] atIndexPath:indexPath];
    default:
      NSAssert(NO,@"Invalid section type with numer %ld", (long)indexPath.section);
      return nil;
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForLoadingIndicator:(NSIndexPath*) indexPath {
  LoadingTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"loadingCell" forIndexPath:indexPath];
  cell.loadingImageView.image = [UIImage animatedImageNamed:@"progress-" duration:1];
  cell.loadingLabel.font = [UIFont fontForAppWithType:Bold andSize:14];
  cell.loadingLabel.textColor = [UIColor appNormalColor];
  return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForMilestone:(StandardMilestone*) milestone atIndexPath:(NSIndexPath*) indexPath {
  
  HistoryTableViewCell *cell = (HistoryTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"milestoneCell" forIndexPath:indexPath];
  __weak HistoryTableViewCell *weakCell = cell;
  [cell setAppearanceWithBlock:^{
    [self tableView:tableView configureBasicCellProperties:weakCell];
    
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor appNormalColor] title:@"Ignore"];
    [rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor appSelectedColor] title:@"Postpone"];
    weakCell.rightUtilityButtons = rightUtilityButtons;
  } force:NO];
  
  NSString * humanRange = [self humanFormattedRangeBetween:[milestone.rangeLow intValue] - (int)Baby.currentBaby.daysSinceDueDate
                                                       and:[milestone.rangeHigh intValue] - (int)Baby.currentBaby.daysSinceDueDate];
  cell.textLabel.text =  [NSString stringWithFormat:@"%@ %@%@",
                         indexPath.section == FutureMilestoneSection ? @"in about" : @"normally",
                         humanRange,
                         indexPath.section == FutureMilestoneSection ? @"" : @" ago"
                         ];
  cell.detailTextLabel.text = milestone.title;
  cell.imageView.image = [UIImage imageNamed:@"historyNoPic"];
  if(indexPath.section == FutureMilestoneSection && _model.hasMoreFutureMilestones) {
    // Special case because we add the loading cell to the 0 Zero Cell.
    cell.bottomLineView.hidden =  indexPath.row >= [self tableView:tableView numberOfRowsInSection:indexPath.section] - 2;
  } else {
    cell.bottomLineView.hidden =  indexPath.row >= [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1;
  }
  cell.topLineView.hidden = indexPath.row == 0;
  return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForAchievement:(MilestoneAchievement*) achievement atIndexPath:(NSIndexPath*) indexPath {

  HistoryTableViewCell *cell = (HistoryTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"achievementCell" forIndexPath:indexPath];
  __weak HistoryTableViewCell *weakCell = cell;
  [cell setAppearanceWithBlock:^{
    [self tableView:tableView configureBasicCellProperties:weakCell];
    
    
    NSMutableArray *rightUtilityButtons;
    if(!rightUtilityButtons) {
      rightUtilityButtons = [NSMutableArray new];
      [rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor appNormalColor] title:@"Share"];
      [rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor appSelectedColor] title:@"Favorite"];
    }
    
    weakCell.rightUtilityButtons = rightUtilityButtons;
  } force:NO];

  cell.textLabel.text = [achievement.completionDate stringWithHumanizedTimeDifference];
  cell.detailTextLabel.text = achievement.standardMilestone ? achievement.standardMilestone.title : achievement.customTitle;

  
  cell.imageView.image = [UIImage imageNamed:@"historyNoPic"]; // use in case of error
  cell.imageView.alpha = 0.5;
 
  PFFile * imageFile;
  BOOL isThumbnail = NO;
  BOOL hasAttachmentImage = (achievement.attachment && [achievement.attachmentType rangeOfString : @"image"].location != NSNotFound);
  if(hasAttachmentImage) {
    isThumbnail = achievement.attachmentThumbnail != nil;
    imageFile = isThumbnail ? achievement.attachmentThumbnail : achievement.attachment;
  } else {
    NSAssert([achievement.baby.objectId isEqualToString:Baby.currentBaby.objectId], @"Expected only milestones for current baby");
    isThumbnail = Baby.currentBaby.avatarImageThumbnail != nil;
    imageFile = Baby.currentBaby.avatarImageThumbnail ? Baby.currentBaby.avatarImageThumbnail : Baby.currentBaby.avatarImage;
  }
  if(imageFile) {
    [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
      if(!error) {
        // TODO: It would be nice to not have to scale the image here, but if we don't, on
        // return from the milestone page, the image explodes into a much larger size (occupying the full height of the cell)
        // until the cell refreshes. Perhaps we could use programmed constrants to fix this? For now, we scale the image and that's it.
        cell.imageView.image = [self imageWithImage:[[UIImage alloc] initWithData:data] scaledToSize:IMG_SIZE];
        cell.imageView.alpha = hasAttachmentImage ? 1.0 : 0.3;
      }
    }];
  }

  cell.bottomLineView.hidden =  indexPath.row >= [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1;
  cell.topLineView.hidden = indexPath.row == 0;
  
  return cell;
}

-(void) tableView:(UITableView*) tableView configureBasicCellProperties:(HistoryTableViewCell*) weakCell {

  static int circleOffset = 10;

  weakCell.textLabel.font = [UIFont fontForAppWithType:Bold andSize:13];
  weakCell.detailTextLabel.font = [UIFont fontForAppWithType:Medium andSize:14];
  weakCell.detailTextLabel.numberOfLines = 4;
  
  weakCell.imageView.frame = CGRectMake(15, weakCell.frame.size.height / 2 - (IMG_SIZE.height / 2),IMG_SIZE.width, IMG_SIZE.height);
  weakCell.imageView.contentMode = UIViewContentModeCenter; // Don't do any more scaling since we scale ourselves.
  weakCell.imageView.layer.masksToBounds = YES;
  [weakCell.imageView.layer setCornerRadius:weakCell.imageView.frame.size.width/2];
  
  UIView * circle = [[UIView alloc] initWithFrame:CGRectMake(weakCell.imageView.frame.origin.x - circleOffset, weakCell.imageView.frame.origin.y - circleOffset,
                                                             weakCell.imageView.frame.size.width + circleOffset * 2, weakCell.imageView.frame.size.height + circleOffset * 2)];
  circle.layer.borderWidth = 1;
  circle.layer.borderColor = [UIColor appGreyTextColor].CGColor;
  [circle.layer setCornerRadius:circle.frame.size.width/2];
  [weakCell.contentView addSubview:circle];
  
  
  weakCell.topLineView = [[UIView alloc] initWithFrame:CGRectMake(circle.frame.origin.x + circle.frame.size.width / 2 , 0, 1,circle.frame.origin.y)];
  weakCell.topLineView.backgroundColor = [UIColor appGreyTextColor];
  [weakCell.contentView addSubview:weakCell.topLineView];
  
  weakCell.bottomLineView = [[UIView alloc] initWithFrame:CGRectMake(circle.frame.origin.x + circle.frame.size.width / 2 , circle.frame.origin.y + circle.frame.size.height, 1, weakCell.frame.size.height - (circle.frame.origin.y + circle.frame.size.height))];
  weakCell.bottomLineView.backgroundColor = [UIColor appGreyTextColor];
  [weakCell.contentView addSubview:weakCell.bottomLineView];
  weakCell.delegate = self;
  weakCell.containingTableView = tableView;
}




#pragma mark - SWTableViewDelegate
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)buttonIndex {

  NSIndexPath * path = [self.tableView indexPathForCell:cell];
  if(path.section == AchievementSection) {
    //MilestoneAchievement * achievement = (MilestoneAchievement*) _model.achievements[path.row];
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



// TODO: Save thumbnails so we don't have to scale
- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
  if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
    if ([[UIScreen mainScreen] scale] == 2.0) {
      UIGraphicsBeginImageContextWithOptions(newSize, YES, 2.0);
    } else {
      UIGraphicsBeginImageContext(newSize);
    }
  } else {
    UIGraphicsBeginImageContext(newSize);
  }
  [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
  UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return newImage;
}


-(char*) s:(NSInteger) number {
  return number != 1 ? "s" : "";
}

-(NSString*) humanFormattedRangeBetween:(int)lowDays and:(int)highDays {
  
  if(lowDays < 1 && highDays > 0) { // Baby already in the range
    if(highDays > 90) {
      return [NSString stringWithFormat:@"the next %d months",highDays / 30];
    } else {
      if(highDays < 7) {
        return @"the next few days";
        
      } else {
        return [NSString stringWithFormat:@"the next %d days",highDays];
      }
    }
  }
  
  // When both minus, this is a past milestone, we swap them also because they are in the past.
  if(lowDays < 1 && highDays < 1) {
    int oldLowDays = lowDays;
    lowDays = abs(MAX(lowDays, highDays));
    highDays = abs(MIN(oldLowDays, highDays));
  }
  
  if(lowDays == highDays) {
    if(lowDays <= 90) {
      return [NSString stringWithFormat:@"%d days",lowDays];
    } else {
        return [NSString stringWithFormat:@"%d months",lowDays / 30];
    }
  }
  
  if(lowDays <= 90) {
    if(highDays <= 90) {
      return [NSString stringWithFormat:@"%d to %d days",lowDays, highDays];
    } else {
      if(lowDays <30) {
        return [NSString stringWithFormat:@"%d days to %d months",lowDays, highDays / 30];
      }
    }
  }
  return [NSString stringWithFormat:@"%d to %d months",lowDays / 30 , highDays / 30];
}


@end



@implementation LoadingTableViewCell

@end


#pragma HistoryTableCell impl
@implementation HistoryTableViewCell


@end


