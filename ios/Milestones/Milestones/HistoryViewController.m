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

-(void) viewDidLoad {
  [super viewDidLoad];
   _model = [[HistoryViewTableModel alloc] init];
  _model.delegate = self;
  [_model loadAllObjects];
  //_model.objectsPerPage = 25;
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(babyUpdated:) name:kDDNotificationCurrentBabyChanged object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(milestoneNotedAndSaved:) name:kDDNotificationMilestoneNotedAndSaved object:nil];
  self.navigationItem.title = Baby.currentBaby.name;
}

-(void) babyUpdated:(NSNotification*)notification {
  if(Baby.currentBaby) [_model loadAllObjects];
  self.navigationItem.title = Baby.currentBaby.name;
}

-(void) milestoneNotedAndSaved:(NSNotification*)notification {
  // TODO: Load only acheievments
  [_model loadAllObjects];
  
}

-(void) objectsUpdated {
  // TODO: refresh table - HOW?
}

//// TODO: When we need to add sections, see https://parse.com/questions/using-pfquerytableviewcontroller-for-uitableview-sections
//- (PFQuery *)queryForTable {
//  // If no Baby available yet, don't try to load anything
//  if(!Baby.currentBaby) return nil;
//  PFQuery * query = [MilestoneAchievement query];
//  [query whereKey:@"baby" equalTo:Baby.currentBaby];
//  [query whereKey:@"isSkipped" equalTo:[NSNumber numberWithBool:NO]];
//  [query whereKey:@"isPostponed" equalTo:[NSNumber numberWithBool:NO]];
//
//  [query includeKey:@"standardMilestone"];
//  if(_reverseSort) {
//    [query orderByAscending:@"completionDate"];
//  } else {
//    [query orderByDescending:@"completionDate"];
//  }
//  
//  // If no objects are loaded in memory, we look to the cache
//  // first to fill the table and then subsequently do a query
//  // against the network.
//  PFCachePolicy policy = self.objects.count ? kPFCachePolicyNetworkOnly : kPFCachePolicyCacheThenNetwork;
//  query.cachePolicy = policy;
//  return query;
//}

- (IBAction)didClickSortButton:(id)sender {
  //_model.reverseSort = !_model.reverseSort;
  //self.sortButton.title = _reverseSort ? @"↑" : @"↓";
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
  //UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 18)];
  UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 18)];
  label.textAlignment = NSTextAlignmentCenter;
  [label setFont:[UIFont fontForAppWithType:Book andSize:17]];
  label.text =  [self tableView:tableView titleForHeaderInSection:section];
  label.textColor = [UIColor appNormalColor];
  [label sizeToFit];
  //[view addSubview:label];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForMilestone:(StandardMilestone*) milestone atIndexPath:(NSIndexPath*) indexPath {

  HistoryTableViewCell * cell = [self tableView:tableView reusableCellForIndexPath:indexPath];

  cell.textLabel.text = indexPath.section == FutureMilestoneSection ? @"in about 1-2 months" : @"normally 2-3 months ago";
  cell.detailTextLabel.text = milestone.title;
  cell.imageView.image = [UIImage imageNamed:@"historyNoPic"];
  cell.bottomLineView.hidden =  indexPath.row >= [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1;
  cell.topLineView.hidden = indexPath.row == 0;
  return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForAchievement:(MilestoneAchievement*) achievement atIndexPath:(NSIndexPath*) indexPath {

  HistoryTableViewCell * cell = [self tableView:tableView reusableCellForIndexPath:indexPath];
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

- (HistoryTableViewCell *)tableView:(UITableView *)tableView reusableCellForIndexPath:(NSIndexPath*) indexPath {
  static int circleOffset = 10;
  
  HistoryTableViewCell *cell = (HistoryTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"simpleHistoryCell" forIndexPath:indexPath];
  __weak HistoryTableViewCell *weakCell = cell;
  //Do any fixed setup here (will be executed once unless force is set to YES)
  [cell setAppearanceWithBlock:^{
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
  } force:NO];
  
  return cell;

}



// TODO: custom header view
//-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
//{
//  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 18)];
//  /* Create custom view to display section header... */
//  UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, tableView.frame.size.width, 18)];
//  [label setFont:[UIFont boldSystemFontOfSize:12]];
//  NSString *string =[list objectAtIndex:section];
//  /* Section header is in 0th index... */
//  [label setText:string];
//  [view addSubview:label];
//  [view setBackgroundColor:[UIColor colorWithRed:166/255.0 green:177/255.0 blue:186/255.0 alpha:1.0]]; //your background color...
//  return view;
//}

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

@end

@interface HistoryTableViewCell ()
{
  dispatch_once_t onceToken;
}
@end

@implementation HistoryTableViewCell

- (void)setAppearanceWithBlock:(void (^)())appearanceBlock force:(BOOL)force
{
  if (force)
  {
    appearanceBlock();
  }
  else
  {
    dispatch_once(&onceToken, ^{
      appearanceBlock();
    });
  }
}

@end


