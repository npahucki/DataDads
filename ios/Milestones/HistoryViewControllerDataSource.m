//
//  HistoryViewControllerDataSource.m
//  Milestones
//
//  Created by Nathan  Pahucki on 6/4/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "HistoryViewControllerDataSource.h"

@implementation HistoryViewControllerDataSource


#pragma mark - UITableViewControllerDataSource - Headers/Sections

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  switch (section) {
    case FutureMilestoneSection:
      return _model.futureMilestones.count + (_model.hasMoreFutureMilestones ? 1 : 0);
    case PastMilestoneSection:
      return _model.pastMilestones.count + (_model.hasMorePastMilestones ? 1 : 0);
    case AchievementSection:
      return _model.achievements.count + (_model.hasMoreAchievements ? 1 : 0);
    default:
      NSAssert(NO,@"Invalid section type with number %ld", (long)section);
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
    case AchievementSection:
      return @"Noted Milestones";
    case PastMilestoneSection:
      return @"Outgrown Milestones";
    default:
      NSAssert(NO,@"Invalid section type with number %ld", (long)section);
      return nil;
  }
  
}

#pragma mark - UITableViewControllerDataSource - Cells

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  HistoryTableViewCell * cell = nil;
  
  switch (indexPath.section) {
    case FutureMilestoneSection:
      if (indexPath.row == 0 && _model.hasMoreFutureMilestones)
        cell = [self tableView:tableView cellForLoadingIndicator:indexPath];
      else {
        if(_model.hasMoreFutureMilestones) {
          indexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
        }
        cell = [self tableView:tableView cellForMilestone:_model.futureMilestones[indexPath.row] atIndexPath:indexPath];
      }
      break;
    case PastMilestoneSection:
      if (indexPath.row == _model.pastMilestones.count)
        cell = [self tableView:tableView cellForLoadingIndicator:indexPath];
      else
        cell = [self tableView:tableView cellForMilestone:_model.pastMilestones[indexPath.row] atIndexPath:indexPath];
      break;
    case AchievementSection:
      if (indexPath.row == _model.achievements.count)
        cell = [self tableView:tableView cellForLoadingIndicator:indexPath];
      else
        cell = [self tableView:tableView cellForAchievement:_model.achievements[indexPath.row] atIndexPath:indexPath];
      break;
    default:
      NSAssert(NO,@"Invalid section type with number %ld", (long)indexPath.section);
  }
  
  cell.delegate = self.cellSwipeDelegate;
  cell.containingTableView = tableView;
  [cell setCellHeight:tableView.rowHeight];
  return cell;
}

- (LoadingTableViewCell *)tableView:(UITableView *)tableView cellForLoadingIndicator:(NSIndexPath*) indexPath {

  BOOL showError;
  switch (indexPath.section) {
    case FutureMilestoneSection:
      showError = _model.hadErrorLoadingFutureMilestones;
      break;
    case PastMilestoneSection:
      showError = _model.hadErrorLoadingPastMilestones;
      break;
    case AchievementSection:
      showError = _model.hadErrorLoadingAchievements;
      break;
  }
  
  LoadingTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"loadingCell" forIndexPath:indexPath];
  if(indexPath.section == FutureMilestoneSection && _model.hasMoreFutureMilestones) {
    // Special case because we add the loading cell to the 0 Zero Cell.
    cell.bottomLineHidden =  indexPath.row >= [self tableView:tableView numberOfRowsInSection:indexPath.section] - 2;
  } else {
    cell.bottomLineHidden =  indexPath.row >= [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1;
  }
  cell.topLineHidden = indexPath.row == 0;

  if(showError) {
    cell.pictureView.image = [UIImage imageNamed:@"error-9"];
    cell.loadingLabel.text = @"Failed to load. Touch here to try loading again.";
    cell.loadingLabel.textColor = UIColorFromRGB(0xCE3339);  // Same color as icon
  } else {
    cell.pictureView.image = [UIImage animatedImageNamed:@"progress-" duration:1];
    cell.loadingLabel.text = @"Loading...";
    cell.loadingLabel.textColor = [UIColor appGreyTextColor];
    
  }
  return cell;
}

- (MilestoneTableViewCell *)tableView:(UITableView *)tableView cellForMilestone:(StandardMilestone*) milestone atIndexPath:(NSIndexPath*) indexPath {
  
  MilestoneTableViewCell *cell = (MilestoneTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"milestoneCell" forIndexPath:indexPath];
  cell.milestone = milestone;
  
  if(indexPath.section == FutureMilestoneSection && _model.hasMoreFutureMilestones) {
    // Special case because we add the loading cell to the 0 Zero Cell.
    cell.bottomLineHidden =  indexPath.row >= [self tableView:tableView numberOfRowsInSection:indexPath.section] - 2;
    cell.topLineHidden = indexPath.row == 0 && !_model.hasMoreFutureMilestones;
  } else {
    cell.bottomLineHidden =  indexPath.row >= [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1;
    cell.topLineHidden = indexPath.row == 0;
  }
  return cell;
}

- (AchievementTableViewCell *)tableView:(UITableView *)tableView cellForAchievement:(MilestoneAchievement*) achievement atIndexPath:(NSIndexPath*) indexPath {
  NSAssert([achievement.baby.objectId isEqualToString:Baby.currentBaby.objectId], @"Expected only milestones for current baby");
  AchievementTableViewCell *cell = (AchievementTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"achievementCell" forIndexPath:indexPath];
  achievement.baby = Baby.currentBaby; // Make sure all fields on Baby are populated
  cell.achievement = achievement;
  cell.bottomLineHidden =  indexPath.row >= [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1;
  cell.topLineHidden = indexPath.row == 0;
  return cell;
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


