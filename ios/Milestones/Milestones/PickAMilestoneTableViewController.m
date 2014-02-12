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

@implementation PickAMilestoneTableViewController

- (id)initWithStyle:(UITableViewStyle)style {
  self = [super initWithStyle:style];
  if (self) {
    // This table displays items in the Todo class
    self.pullToRefreshEnabled = YES;
    self.paginationEnabled = NO;
    self.objectsPerPage = 25;
  }
  return self;
}


-(void) viewDidLoad {
  [super viewDidLoad];
  // Whenever the current baby chnages, we need to refresh the table
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(babyUpdated:) name:kDDNotificationCurrentBabyChanged object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(milestoneNotedAndSaved:) name:kDDNotificationMilestoneNotedAndSaved object:nil];
}

-(void) babyUpdated:(NSNotification*)notification {
  self.baby = [notification.userInfo objectForKey:@""];
  [self loadObjects];
}

-(void) milestoneNotedAndSaved:(NSNotification*)notification {
  MilestoneAchievement * achievement = [notification.userInfo objectForKey:@""];
  if(achievement.standardMilestone) {
    NSIndexPath *path = [NSIndexPath indexPathForRow:[self.objects indexOfObject:achievement.standardMilestone] inSection:0];
    UITableViewCell * checkedCell = [self.tableView cellForRowAtIndexPath:path];
    if(checkedCell) {
      // Show a check mark and forbid and more clicking of this cell so as not to note it more than once.
      checkedCell.accessoryType = UITableViewCellAccessoryCheckmark;
      checkedCell.userInteractionEnabled = NO;
    }
    [self loadObjects];
  }
}

//-(void) objectsDidLoad:(NSError *)error {
//  // Reset the checked cell once new objects are available.
//  if(!error) {
//    for (int section = 0; section < [tableView numberOfSections]; section++) {
//      for (int row = 0; row < [tableView numberOfRowsInSection:section]; row++) {
//        NSIndexPath* cellPath = [NSIndexPath indexPathForRow:row inSection:section];
//        UITableViewCell* cell = [tableView cellForRowAtIndexPath:cellPath];
//        cell.accessoryType = UITableViewCellAccessoryNone;
//        cell.userInteractionEnabled = YES;
//      }
//    }
//  }
//  [super objectsDidLoad:error];
//}



// TODO: When we need to add sections, see https://parse.com/questions/using-pfquerytableviewcontroller-for-uitableview-sections
- (PFQuery *)queryForTable {
  // If no Baby available yet, don't try to load anything
  if(!self.baby) return nil;
  
  NSNumber * rangeDays = [NSNumber numberWithInteger:self.baby.daysSinceDueDate];
  PFQuery *innerQuery = [MilestoneAchievement query];
  [innerQuery whereKey:@"baby" equalTo:self.baby];
  PFQuery *query = [StandardMilestone query];
  [query whereKey:@"rangeHigh" greaterThanOrEqualTo:rangeDays];
  [query whereKey:@"rangeLow" lessThanOrEqualTo:rangeDays];
  // Bit if a hack here, using string column here : See https://parse.com/questions/trouble-with-nested-query-using-objectid
  [query whereKey:@"objectId" doesNotMatchKey:@"standardMilestoneId" inQuery:innerQuery];
  [query orderByDescending:@"rangeUpper"];

  // If no objects are loaded in memory, we look to the cache
  // first to fill the table and then subsequently do a query
  // against the network.
  PFCachePolicy policy = self.objects.count ? kPFCachePolicyNetworkOnly : kPFCachePolicyCacheThenNetwork;
  innerQuery.cachePolicy = policy;
  query.cachePolicy = policy;

  return query;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
                        object:(StandardMilestone *)milestone {
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    cell.accessoryType =  UITableViewCellAccessoryDetailButton;
  }

  cell.accessoryType =  UITableViewCellAccessoryDetailButton;
  cell.userInteractionEnabled = YES;
  cell.textLabel.text = milestone.title;
  cell.detailTextLabel.text = milestone.shortDescription;
  return cell;
}

// Override to support conditional editing of the table view.
// This only needs to be implemented if you are going to be returning NO
// for some items. By default, all items are editable.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  // Return YES if you want the specified item to be editable.
  return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    MilestoneAchievement * achievement = [MilestoneAchievement object];
    achievement.standardMilestone = (StandardMilestone*)[self objectAtIndexPath:indexPath];
    achievement.baby = _myBaby;
    achievement.completionDate = [NSDate date];
    [achievement saveEventually];
    [self loadObjects];
  }
}


-(void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
  [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
  [self performSegueWithIdentifier:kDDSegueShowMilestoneDetails sender:self];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [super tableView:tableView didSelectRowAtIndexPath:indexPath];
  [self performSegueWithIdentifier:kDDSegueNoteMilestone sender:self];
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if([segue.identifier isEqualToString:kDDSegueNoteMilestone]) {
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    MilestoneAchievement * achievement = [MilestoneAchievement object];
    achievement.standardMilestone = (StandardMilestone*)[self objectAtIndexPath:selectedIndexPath];
    achievement.baby = _myBaby;
    ((NoteMilestoneViewController*)segue.destinationViewController).achievement = achievement;
  } else if([segue.identifier isEqualToString:kDDSegueShowMilestoneDetails]) {
    MilestoneDetailsViewController* details = (MilestoneDetailsViewController*)segue.destinationViewController;
    NSLog(@"%@", segue.sourceViewController);
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    details.milestone = (StandardMilestone*)[self objectAtIndexPath:selectedIndexPath];
  }
}


@end