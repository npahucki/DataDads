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

-(void) viewDidAppear:(BOOL)animated {
  self.addNewButton.enabled = self.baby != nil;
}

-(void) babyUpdated:(NSNotification*)notification {
  self.baby = [notification.userInfo objectForKey:@""];
  self.addNewButton.enabled = self.baby != nil;
  if(self.baby) [self loadObjects];
}

-(void) milestoneNotedAndSaved:(NSNotification*)notification {
  MilestoneAchievement * achievement = [notification.userInfo objectForKey:@""];
  if(achievement.standardMilestone) {
    [self loadObjects];
  }
}

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
  [query orderByAscending:@"rangeHigh"];

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

  cell.hidden = NO;
  cell.accessoryType =  UITableViewCellAccessoryDetailDisclosureButton;
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

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
  return @"Skip";
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    // TODO: this doesn't seem to work too well.
    UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.hidden = YES;

    MilestoneAchievement * achievement = [MilestoneAchievement object];
    achievement.standardMilestone = (StandardMilestone*)[self objectAtIndexPath:indexPath];
    achievement.baby = _myBaby;
    achievement.completionDate = [NSDate date];
    [achievement saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
      if(succeeded) {
        [self loadObjects];
      } else {
        // TODO: show message
        NSLog(@"Failed to save the achievment %@", achievement);
      }
    }];
  }
}


-(void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
  [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
  [self performSegueWithIdentifier:kDDSegueShowMilestoneDetails sender:self];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [super tableView:tableView didSelectRowAtIndexPath:indexPath];
  if (!([indexPath row] > self.objects.count -1)) {
    [self performSegueWithIdentifier:kDDSegueNoteMilestone sender:self];
  }
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
  } else if([segue.identifier isEqualToString:kDDSegueCreateCustomMilestone]) {
    MilestoneAchievement * achievement = [MilestoneAchievement object];
    achievement.baby = self.baby;
    ((CreateMilestoneViewController*)segue.destinationViewController).achievement = achievement;
  }
}


@end