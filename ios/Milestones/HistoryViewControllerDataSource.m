//
//  HistoryViewControllerDataSource.m
//  Milestones
//
//  Created by Nathan  Pahucki on 6/4/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "HistoryViewControllerDataSource.h"
#import "UIImage+FX.h"

#pragma mark Cell impls

@implementation LoadingTableViewCell
@end

@implementation HistoryTableViewCell
@end

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

#pragma mark - UITableViewControllerDataSource - Cells

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
  __weak LoadingTableViewCell *weakCell = cell;
  [cell setAppearanceWithBlock:^{
    weakCell.loadingLabel.font = [UIFont fontForAppWithType:Bold andSize:14];
    weakCell.loadingLabel.textColor = [UIColor appNormalColor];

    static int circleOffset = 10;
    UIView * circle = [[UIView alloc] initWithFrame:CGRectMake(weakCell.loadingImageView.frame.origin.x - circleOffset, weakCell.loadingImageView.frame.origin.y - circleOffset,
                                                               weakCell.loadingImageView.frame.size.width + circleOffset * 2, weakCell.loadingImageView.frame.size.height + circleOffset * 2)];
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
    weakCell.delegate = self.cellSwipeDelegate;
    weakCell.containingTableView = tableView;
  } force:NO];

  if(indexPath.section == FutureMilestoneSection && _model.hasMoreFutureMilestones) {
    // Special case because we add the loading cell to the 0 Zero Cell.
    cell.bottomLineView.hidden =  indexPath.row >= [self tableView:tableView numberOfRowsInSection:indexPath.section] - 2;
  } else {
    cell.bottomLineView.hidden =  indexPath.row >= [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1;
  }
  cell.topLineView.hidden = indexPath.row == 0;

  
  cell.loadingImageView.image = [UIImage animatedImageNamed:@"progress-" duration:1];
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
  cell.detailTextLabel.text = milestone.titleForCurrentBaby;
  cell.imageView.image = [UIImage imageNamed:@"historyNoPic"];
  if(indexPath.section == FutureMilestoneSection && _model.hasMoreFutureMilestones) {
    // Special case because we add the loading cell to the 0 Zero Cell.
    cell.bottomLineView.hidden =  indexPath.row >= [self tableView:tableView numberOfRowsInSection:indexPath.section] - 2;
    cell.topLineView.hidden = indexPath.row == 0 && !_model.hasMoreFutureMilestones;
  } else {
    cell.bottomLineView.hidden =  indexPath.row >= [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1;
    cell.topLineView.hidden = indexPath.row == 0;
  }
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
      [rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor redColor] title:@"Delete"];
    }
    
    weakCell.rightUtilityButtons = rightUtilityButtons;
  } force:NO];
  
  NSAssert([achievement.baby.objectId isEqualToString:Baby.currentBaby.objectId], @"Expected only milestones for current baby");
  
  cell.textLabel.text = [achievement.completionDate stringWithHumanizedTimeDifference];
  cell.detailTextLabel.text = achievement.displayTitle;
  
  
  cell.imageView.image = [UIImage imageNamed:@"historyNoPic"]; // use in case of error
  cell.imageView.alpha = 0.5;
  
  PFFile * imageFile;
  BOOL hasAttachmentImage = (achievement.attachment && [achievement.attachmentType rangeOfString : @"image"].location != NSNotFound);
  if(hasAttachmentImage) {
    imageFile = achievement.attachmentThumbnail ? achievement.attachmentThumbnail : achievement.attachment;
  } else {
    imageFile = Baby.currentBaby.avatarImageThumbnail ? Baby.currentBaby.avatarImageThumbnail : Baby.currentBaby.avatarImage;
  }
  if(imageFile) {
    [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
      if(!error) {
        // TODO: It would be nice to not have to scale the image here, but if we don't, on
        // return from the milestone page, the image explodes into a much larger size (occupying the full height of the cell)
        // until the cell refreshes. Perhaps we could use programmed constrants to fix this? For now, we scale the image and that's it.
        UIImage * image = [[UIImage alloc] initWithData:data];
        // NOTE: Image will be null if the image data is bad, which can happen for example if parse returns a 200 code but error text instead.
        if(image) {
          cell.imageView.image =  [image imageCroppedAndScaledToSize:IMG_SIZE contentMode:UIViewContentModeScaleAspectFill padToFit:NO];
          cell.imageView.alpha = hasAttachmentImage ? 1.0 : 0.3;
        }
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
  weakCell.delegate = self.cellSwipeDelegate;
  weakCell.containingTableView = tableView;
}

// TODO: Save thumbnails so we don't have to scale
- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
  
  float ratio = newSize.height/image.size.height;
  if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
    if ([[UIScreen mainScreen] scale] == 2.0) {
      UIGraphicsBeginImageContextWithOptions(newSize, YES, 2.0);
    } else {
      UIGraphicsBeginImageContext(newSize);
    }
  } else {
    UIGraphicsBeginImageContext(newSize);
  }
  [image drawInRect:CGRectMake(0, 0, ratio * image.size.width, newSize.height)];
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


