//
//  PickAMilestoneTableViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/23/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "PickAMilestoneTableViewController.h"
#import "MainViewController.h"
#import "Baby.h"
#import "StandardMilestone.h"
#import "NoteMilestoneViewController.h"
#import "MilestoneDetailsViewController.h"
#import "CreateMilestoneViewController.h"
#import "StandardMilestoneQuery.h"

@implementation PickAMilestoneTableViewController

- (id)initWithStyle:(UITableViewStyle)style {
  self = [super initWithStyle:style];
  if (self) {
    // This table displays items in the Todo class
    self.pullToRefreshEnabled = YES;
    self.paginationEnabled = NO;
    self.objectsPerPage = 10;
  }
  return self;
}


-(void) viewDidLoad {
  [super viewDidLoad];
  // Whenever the current baby chnages, we need to refresh the table
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(babyUpdated:) name:kDDNotificationCurrentBabyChanged object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(milestoneNotedAndSaved:) name:kDDNotificationMilestoneNotedAndSaved object:nil];
  [self stylePFLoadingViewTheHardWay];
}

// Hack to customize the inititial loading view
- (void)stylePFLoadingViewTheHardWay
{
  UIColor *labelTextColor = [UIColor blueColor];
  UIColor *labelShadowColor = [UIColor darkGrayColor];
  
  // go through all of the subviews until you find a PFLoadingView subclass
  for (UIView *subview in self.view.subviews)
  {
    if ([subview class] == NSClassFromString(@"PFLoadingView"))
    {
      // find the loading label and loading activity indicator inside the PFLoadingView subviews
      for (UIView *loadingViewSubview in subview.subviews) {
        if ([loadingViewSubview isKindOfClass:[UILabel class]])
        {
          UILabel *label = (UILabel *)loadingViewSubview;
          {
            label.textColor = labelTextColor;
            label.shadowColor = labelShadowColor;
          }
        }
        
        if ([loadingViewSubview isKindOfClass:[UIActivityIndicatorView class]])
        {
          UIImage * image = [UIImage animatedImageNamed:@"progress-" duration:1.0f];
          UIImageView* imageView = [[UIImageView alloc] initWithFrame:CGRectMake(subview.frame.size.width / 2 - image.size.width / 2, subview.frame.size.height / 2 - image.size.height / 2, image.size.width, image.size.height)];
          [imageView setImage:image];
          [loadingViewSubview removeFromSuperview];
          [subview addSubview: imageView];
        }
      }
    }
  }
}

-(void)viewWillDisappear:(BOOL)animated{
  [super viewWillDisappear:animated];
  [self.navigationController setNavigationBarHidden:NO];    // it shows
}

-(void) viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [[[self navigationController] navigationBar] setNeedsLayout];
  [self.navigationController setNavigationBarHidden:YES];
}

-(void) viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [[[self navigationController] navigationBar] setNeedsLayout];
  self.addNewButton.enabled = Baby.currentBaby != nil;
}

-(void) babyUpdated:(NSNotification*)notification {
  self.addNewButton.enabled = Baby.currentBaby != nil;
  if(Baby.currentBaby) [self loadObjects];
}

-(void) milestoneNotedAndSaved:(NSNotification*)notification {
  MilestoneAchievement * achievement = [notification.userInfo objectForKey:@""];
  if(achievement.standardMilestone) {
    [self loadObjects];
  }
}

-(void) loadObjects {
  [super loadObjects];
  // Must be reset so that more can load again.
  _lastPageTriggeredBy =  0;

}

-(void) objectsDidLoad:(NSError *)error {
  [super objectsDidLoad:error];
  if(!self.objects.count && !self.isLoading) {
    if(!_hud) {
      // Show HUD to suggest adding new milestones.
      _hud = [MBProgressHUD showHUDAddedTo:self.tableView animated:NO];
      _hud.mode = MBProgressHUDModeText;
      _hud.dimBackground = YES;
      _hud.labelText = @"No More Milestones";
      _hud.detailsLabelText = @"There are no more milestones for your baby's age, enter your own by pressing 'New'";
    }
  } else if(_hud) {
    [_hud hide:NO];
    _hud = nil;
  }
}

// TODO: When we need to add sections, see https://parse.com/questions/using-pfquerytableviewcontroller-for-uitableview-sections
- (PFQuery *)queryForTable {
  // If no Baby available yet, don't try to load anything
  if(!Baby.currentBaby) return nil;

  StandardMilestoneQuery * query = [[StandardMilestoneQuery alloc] init];
  query.babyId = Baby.currentBaby.objectId;
  query.rangeDays = [NSNumber numberWithInteger:Baby.currentBaby.daysSinceDueDate];
  // If no objects are loaded in memory, we look to the cache
  // first to fill the table and then subsequently do a query
  // against the network.
  PFCachePolicy policy = self.objects.count ? kPFCachePolicyNetworkOnly : kPFCachePolicyCacheThenNetwork;
  query.cachePolicy = policy;
  return query;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
                        object:(StandardMilestone *)milestone {
  static NSString *CellIdentifier = @"SwipeCell";
  
  
  SWTableViewCell *cell = (SWTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
  __weak SWTableViewCell *weakCell = cell;
  //Do any fixed setup here (will be executed once unless force is set to YES)
  [cell setAppearanceWithBlock:^{
    weakCell.containingTableView = tableView;
    
    NSMutableArray *leftUtilityButtons = [NSMutableArray new];
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    
    [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.07 green:0.75f blue:0.16f alpha:1.0]
                                                title:@"Done"];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0]
                                                title:@"Ignore"];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title:@"Postpone"];
    
    weakCell.leftUtilityButtons = leftUtilityButtons;
    weakCell.rightUtilityButtons = rightUtilityButtons;
    
    weakCell.delegate = self;
    weakCell.textLabel.numberOfLines = 3; // Multiline
    weakCell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail; // Make wrap
    weakCell.textLabel.font = [UIFont fontWithName:@"GothamRounded-Book" size:15.0];
//    weakCell.detailTextLabel.numberOfLines = 3; // Multiline
//    weakCell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingTail; // Make wrap
//    weakCell.detailTextLabel.font = [UIFont fontWithName:@"GothamRounded-Light" size:11.0];
  } force:NO];
  
  cell.textLabel.text = milestone.title;
  // I think it's better to only show this on the deails page so as not to cluter the UI
  // cell.detailTextLabel.text = milestone.shortDescription;
  
//    - (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath
  
  return cell;
}

#pragma mark - SWTableViewDelegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index {
  NSAssert(index == 0, @"Only expected zero index for left utility");
  NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
  [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
  [self performSegueWithIdentifier:kDDSegueNoteMilestone sender:self];
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
  switch (index) {
    case 0:
      NSLog(@"TODO: Ignore button was pressed");
      break;
    case 1:
      NSLog(@"TODO: Postpone button was pressed");
      break;
    default:
      break;
  }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([indexPath row] <= self.objects.count -1 ) { // Ignore the Load More cell click
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self performSegueWithIdentifier:kDDSegueShowMilestoneDetails sender:self];
  }
}

// Since we are going to load more items as we get near the bottom, we will return a cell saying more is loading
- (PFTableViewCell *)tableView:(UITableView *)tableView cellForNextPageAtIndexPath:(NSIndexPath *)indexPath {
  PFTableViewCell * cell = [[PFTableViewCell alloc] init];
  cell.imageView.image = [UIImage animatedImageNamed:@"progress-" duration:1.0f];
  cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
  //cell.imageView.frame = CGRectMake(0,0,50,50);
  cell.textLabel.text = @"Loading more...";
  cell.textLabel.font = [UIFont fontWithName:@"GothamRounded-Bold" size:15.0];
  cell.userInteractionEnabled = NO;
  return cell;
}


-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath > _lastPageTriggeredBy && self.objects.count > 5 && indexPath.row == self.objects.count - 5 && !self.isLoading) {
    _lastPageTriggeredBy = indexPath;
    [self loadNextPage];
  }
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
  MilestoneAchievement * achievement = [MilestoneAchievement object];
  achievement.baby = Baby.currentBaby;
  if([segue.identifier isEqualToString:kDDSegueNoteMilestone]) {
    achievement.standardMilestone = (StandardMilestone*)[self objectAtIndexPath:selectedIndexPath];
    ((NoteMilestoneViewController*)segue.destinationViewController).achievement = achievement;
  } else if([segue.identifier isEqualToString:kDDSegueShowMilestoneDetails]) {
    achievement.standardMilestone = (StandardMilestone*)[self objectAtIndexPath:selectedIndexPath];
    ((MilestoneDetailsViewController*)segue.destinationViewController).achievement = achievement;
  } else if([segue.identifier isEqualToString:kDDSegueCreateCustomMilestone]) {
    ((CreateMilestoneViewController*)segue.destinationViewController).achievement = achievement;
  }
}


@end