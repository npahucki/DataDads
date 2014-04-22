//
//  HistoryViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/11/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "HistoryViewController.h"

@interface HistoryViewController ()

@end

@implementation HistoryViewController

+ (void)initialize {
  _dateFormatter = [[NSDateFormatter alloc] init];
  [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
  [_dateFormatter setTimeStyle:NSDateFormatterNoStyle];
}

-(BOOL) reverseSort {
  return _reverseSort;
}

-(void) setReverseSort: (BOOL) reverse {
  _reverseSort = reverse;
  self.sortButton.title = _reverseSort ? @"↑" : @"↓";
  [self loadObjects];
}

-(void) viewDidLoad {
  [super viewDidLoad];
  self.objectsPerPage = 50;
}

// TODO: When we need to add sections, see https://parse.com/questions/using-pfquerytableviewcontroller-for-uitableview-sections
- (PFQuery *)queryForTable {
  // If no Baby available yet, don't try to load anything
  if(!Baby.currentBaby) return nil;
  PFQuery * query = [MilestoneAchievement query];
  [query whereKey:@"baby" equalTo:Baby.currentBaby];
  [query whereKey:@"isSkipped" notEqualTo:[NSNumber numberWithBool:YES]];
  [query whereKey:@"isPostponed" notEqualTo:[NSNumber numberWithBool:YES]];
  [query includeKey:@"standardMilestone"];
  if(_reverseSort) {
    [query orderByAscending:@"completionDate"];
  } else {
    [query orderByDescending:@"completionDate"];
  }
  
  // If no objects are loaded in memory, we look to the cache
  // first to fill the table and then subsequently do a query
  // against the network.
  PFCachePolicy policy = self.objects.count ? kPFCachePolicyNetworkOnly : kPFCachePolicyCacheThenNetwork;
  query.cachePolicy = policy;
  return query;
}

- (IBAction)didClickSortButton:(id)sender {
    self.reverseSort = !self.reverseSort;
}




#pragma mark - UITableViewContorller

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
                        object:(MilestoneAchievement *)achievement {

  

  static int imageWidth = 54;
  static int imageHeight = 54;
  static int circleOffset = 10;
  
  
  
  
  HistoryTableViewCell *cell = (HistoryTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"simpleHistoryCell" forIndexPath:indexPath];
  __weak HistoryTableViewCell *weakCell = cell;
  //Do any fixed setup here (will be executed once unless force is set to YES)
  [cell setAppearanceWithBlock:^{
    weakCell.textLabel.font = [UIFont fontForAppWithType:Bold andSize:13];
    weakCell.detailTextLabel.font = [UIFont fontForAppWithType:Medium andSize:14];
    weakCell.detailTextLabel.numberOfLines = 4;

    weakCell.imageView.frame = CGRectMake(15, weakCell.frame.size.height / 2 - (imageHeight / 2),imageWidth,imageHeight);
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
  
  
  // TODO: Make member
  cell.textLabel.text = [_dateFormatter stringFromDate:achievement.completionDate];
  cell.detailTextLabel.text = achievement.standardMilestone ? achievement.standardMilestone.title : achievement.customTitle;

  cell.imageView.image = [UIImage imageNamed:@"historyNoPic"]; // Place holder
  if(achievement.attachment && [achievement.attachmentType rangeOfString : @"image"].location != NSNotFound) {
    [achievement.attachment getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
      if(!error) {
        cell.imageView.image = [self imageWithImage:[[UIImage alloc] initWithData:data] scaledToSize:CGSizeMake(imageWidth,imageHeight)];
      }
    }];
  }

  cell.bottomLineView.hidden =  indexPath.row >= [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1;
  cell.topLineView.hidden = indexPath.item == 0;
  
  
  
  return cell;
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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


