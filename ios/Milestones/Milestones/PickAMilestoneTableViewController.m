//
//  PickAMilestoneTableViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/23/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "PickAMilestoneTableViewController.h"
#import "StandardMilestoneQuery.h"
#import "MainMilestoneViewController.h"

@implementation PickAMilestoneTableViewController

#pragma mark - UIViewController

-(void) viewDidLoad {
  [super viewDidLoad];
  // Whenever the current baby chnages, we need to refresh the table
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(babyUpdated:) name:kDDNotificationCurrentBabyChanged object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(milestoneNotedAndSaved:) name:kDDNotificationMilestoneNotedAndSaved object:nil];
  self.objectsPerPage = 11;
}

#pragma mark - UITableViewContorller

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
    
    [leftUtilityButtons sw_addUtilityButtonWithColor: [UIColor whiteColor] icon: [UIImage imageNamed:@"completeIcon"]];
    [rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor appNormalColor] title:@"Ignore"];
    [rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor appSelectedColor] title:@"Postpone"];
    
    weakCell.leftUtilityButtons = leftUtilityButtons;
    weakCell.rightUtilityButtons = rightUtilityButtons;
    
    weakCell.delegate = self;
    weakCell.textLabel.numberOfLines = 3; // Multiline
    weakCell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail; // Make wrap
    weakCell.textLabel.font = [UIFont fontForAppWithType:Book andSize:15.0];
  } force:NO];

  cell.textLabel.text = milestone.title;
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    StandardMilestone* milestone = (StandardMilestone*) [self objectAtIndexPath:indexPath];
    [self.delegate standardMilestoneDetailsClicked:milestone];
}

#pragma mark - PFQueryTableViewController

-(void) objectsDidLoad:(NSError *)error {
  [super objectsDidLoad:error];
  if(!self.objects.count && !self.isLoading) {
    if(!_hud) {
      // Show HUD to suggest adding new milestones.
      _hud = [MBProgressHUD showHUDAddedTo:self.tableView animated:NO];
      _hud.mode = MBProgressHUDModeText;
      _hud.dimBackground = YES;
      _hud.labelText = @"No More Milestones";
      _hud.detailsLabelText = @"There are no more milestones for your baby's age. Enter your own by pressing the + button";
      [((MainMilestoneViewController*) self.parentViewController) bounceAddButton];
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

#pragma mark - SWTableViewDelegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index {
  NSAssert(index == 0, @"Only expected zero index for left utility");
  NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
  StandardMilestone* milestone = (StandardMilestone*) [self objectAtIndexPath:indexPath];
  [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
  [self.delegate standardMilestoneCompleteClicked:milestone];
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
  NSIndexPath * path = [self.tableView indexPathForCell:cell];
  StandardMilestone* milestone = (StandardMilestone*) [self objectAtIndexPath:path];
  switch (index) {
    case 0:
      [self.delegate standardMilestoneIgnoreClicked:milestone];
      break;
    case 1:
      [self.delegate standardMilestonePostponeClicked:milestone];
      break;
    default:
      break;
  }
}

#pragma mark - Private


-(void) babyUpdated:(NSNotification*)notification {
  if(Baby.currentBaby) [self loadObjects];
}

-(void) milestoneNotedAndSaved:(NSNotification*)notification {
  MilestoneAchievement * achievement = [notification.userInfo objectForKey:@""];
  if(achievement.standardMilestone) {
    [self loadObjects];
  }
}



@end