//
//  HistoryViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/11/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "HistoryViewController.h"
#import "NSDate+HumanizedTime.h"

#define IMG_SIZE CGSizeMake(54,54)

typedef NS_ENUM(NSInteger, HistorySectionType) {
  FutureMilestoneSection,
  AchievementSection,
  PastMilestoneSection
};

@interface HistoryViewController ()

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
  self.navigationItem.title = Baby.currentBaby.name;
  
  if(Baby.currentBaby) { // Only load if there is already a baby set
    _model.baby = Baby.currentBaby;
    [self reloadTable];
  }
}

-(void) reloadTable {
  [_model loadAchievementsPage:0];
  [_model loadFutureMilestonesPage:0];
  [_model loadPastMilestonesPage:0];
}

-(void) babyUpdated:(NSNotification*)notification {
  if(Baby.currentBaby) {
    _model.baby = Baby.currentBaby;
    [self reloadTable];
  }
  self.navigationItem.title = Baby.currentBaby.name;
}

-(void) milestoneNotedAndSaved:(NSNotification*)notification {
//  // TODO: Load only acheievments
//  [_model loadAllObjects];
}




#pragma mark - UITableViewControllerDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  switch (section) {
    case FutureMilestoneSection:
      return _model.futureMilesstones.count;
    case PastMilestoneSection:
      return _model.pastMilesstones.count;
    case AchievementSection:
      return _model.achievements.count;
    default:
      NSAssert(NO,@"Invalid section type with numer %d", section);
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
      NSAssert(NO,@"Invalid section type with numer %d", section);
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


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  switch (indexPath.section) {
    case FutureMilestoneSection:
      return [self tableView:tableView cellForMilestone:_model.futureMilesstones[indexPath.row] atIndexPath:indexPath];
  case PastMilestoneSection:
    return [self tableView:tableView cellForMilestone:_model.pastMilesstones[indexPath.row] atIndexPath:indexPath];
    case AchievementSection:
      return [self tableView:tableView cellForAchievement:_model.achievements[indexPath.row] atIndexPath:indexPath];
    default:
      NSAssert(NO,@"Invalid section type with numer %d", indexPath.section);
      return nil;
  }
}

-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  // TODO: load next page!
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForMilestone:(StandardMilestone*) milestone atIndexPath:(NSIndexPath*) indexPath {
  
  HistoryTableViewCell *cell = (HistoryTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"milestoneCell" forIndexPath:indexPath];
  __weak HistoryTableViewCell *weakCell = cell;
  [cell setAppearanceWithBlock:^{
    [self tableView:tableView configureBasicCellProperties:weakCell];
    
    NSMutableArray *leftUtilityButtons = [NSMutableArray new];
    [leftUtilityButtons sw_addUtilityButtonWithColor: [UIColor whiteColor] icon: [UIImage imageNamed:@"completeIcon"]];
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor appNormalColor] title:@"Ignore"];
    [rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor appSelectedColor] title:@"Postpone"];

    weakCell.leftUtilityButtons = leftUtilityButtons;
    weakCell.rightUtilityButtons = rightUtilityButtons;
  } force:NO];

  
  
  NSString * humanRange = [self humanFormattedRangeBetween:[milestone.rangeLow intValue] - Baby.currentBaby.daysSinceDueDate
                                                       and:[milestone.rangeHigh intValue] - Baby.currentBaby.daysSinceDueDate];
  cell.textLabel.text =  [NSString stringWithFormat:@"%@ %@%@",
                         indexPath.section == FutureMilestoneSection ? @"in about" : @"normally",
                         humanRange,
                         indexPath.section == FutureMilestoneSection ? @"" : @" ago"
                         ];
  cell.detailTextLabel.text = milestone.title;
  cell.imageView.image = [UIImage imageNamed:@"historyNoPic"];
  cell.bottomLineView.hidden =  indexPath.row >= [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1;
  cell.topLineView.hidden = indexPath.row == 0;
  return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForAchievement:(MilestoneAchievement*) achievement atIndexPath:(NSIndexPath*) indexPath {

  HistoryTableViewCell *cell = (HistoryTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"achievementCell" forIndexPath:indexPath];
  __weak HistoryTableViewCell *weakCell = cell;
  [cell setAppearanceWithBlock:^{
    [self tableView:tableView configureBasicCellProperties:weakCell];
    
//    NSMutableArray *leftUtilityButtons;
//    if(!leftUtilityButtons) {
//      leftUtilityButtons = [NSMutableArray new];
//      [leftUtilityButtons sw_addUtilityButtonWithColor: [UIColor whiteColor] icon: [UIImage imageNamed:@"completeIcon"]];
//    }
//    
//    NSMutableArray *rightUtilityButtons;
//    if(!rightUtilityButtons) {
//      rightUtilityButtons = [NSMutableArray new];
//      [rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor appNormalColor] title:@"Ignore"];
//      [rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor appSelectedColor] title:@"Postpone"];
//    }
//    
//    weakCell.leftUtilityButtons = leftUtilityButtons;
//    weakCell.rightUtilityButtons = rightUtilityButtons;
  } force:NO];

  cell.textLabel.text = [achievement.completionDate stringWithHumanizedTimeDifference];
  cell.detailTextLabel.text = achievement.standardMilestone ? achievement.standardMilestone.title : achievement.customTitle;

  cell.imageView.image = [UIImage imageNamed:@"historyNoPic"]; // Place holder
  if(achievement.attachment && [achievement.attachmentType rangeOfString : @"image"].location != NSNotFound) {
    [achievement.attachment getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
      if(!error) {
        cell.imageView.image = [self imageWithImage:[[UIImage alloc] initWithData:data] scaledToSize:IMG_SIZE];
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
  weakCell.imageView.contentMode = UIViewContentModeScaleToFill;
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


//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//  if ([indexPath row] <= self.objects.count -1 ) { // Ignore the Load More cell click
//    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
//    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
//    StandardMilestone* milestone = (StandardMilestone*) [self objectAtIndexPath:indexPath];
//    [self.delegate standardMilestoneDetailsClicked:milestone];
//  }
//}
//

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

#pragma mark - SWTableViewDelegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index {
//  NSAssert(index == 0, @"Only expected zero index for left utility");
//  NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
//  StandardMilestone* milestone = (StandardMilestone*) [self objectAtIndexPath:indexPath];
//  [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
//  [self.delegate standardMilestoneCompleteClicked:milestone];
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
//  NSIndexPath * path = [self.tableView indexPathForCell:cell];
//  StandardMilestone* milestone = (StandardMilestone*) [self objectAtIndexPath:path];
//  switch (index) {
//    case 0:
//      [self standardMilestoneIgnoreClicked:milestone];
//      break;
//    case 1:
//      [self standardMilestonePostponeClicked:milestone];
//      break;
//    default:
//      break;
//  }
}

#pragma mark - HistoryViewTableModelDelegate
// TODO: show error and/or hide progress
-(void) didLoadAchievements {
  [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:AchievementSection]  withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(void) didFailToLoadAchievements:(NSError *) error {
  NSLog(@"Failed to load achievements %@", error);
}

-(void) didLoadFutureMilestones {
  [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:FutureMilestoneSection]  withRowAnimation:UITableViewRowAnimationAutomatic];
  [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:AchievementSection] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
  
}

-(void) didFailToLoadFutureMilestones:(NSError *) error {
  NSLog(@"Failed to future milestones %@", error);
  
}

-(void) didLoadPastMilestones {
  [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:PastMilestoneSection]  withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(void) didFailToLoadPastMilestones:(NSError *) error {
  NSLog(@"Failed to past milestones %@", error);
  
}


-(char*) s:(NSInteger) number {
  return number != 1 ? "s" : "";
}

-(NSString*) humanFormattedRangeBetween:(int)lowDays and:(int)highDays {
  
  if(lowDays < 1 && highDays > 0) { // Baby already in the range
    return [NSString stringWithFormat:@"the next %d days",highDays];
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





#pragma HistoryTableCell impl
@implementation HistoryTableViewCell


@end


