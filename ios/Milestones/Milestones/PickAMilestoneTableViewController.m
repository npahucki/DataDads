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
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(milestoneNoted:) name:kDDNotificationMilestoneNoted object:nil];
}

-(void) babyUpdated:(NSNotification*)notification {
  _myBaby =  [notification.userInfo objectForKey:@""];
  [self loadObjects];
}

-(void) milestoneNoted:(NSNotification*)notification {
  //StandardMilestone * completed = [notification.userInfo objectForKey:@""];
  // TODO: add a check mark to the cell before it refreshes
  [self loadObjects];
}


// TODO: When we need to add sections, see https://parse.com/questions/using-pfquerytableviewcontroller-for-uitableview-sections
- (PFQuery *)queryForTable {
  // If no Baby available yet, don't try to load anything
  if(!_myBaby) return nil;
  
  NSNumber * rangeDays = [NSNumber numberWithInteger:_myBaby.daysSinceDueDate];
  PFQuery *innerQuery = [StandardMilestoneAchievement query];
  [innerQuery whereKey:@"baby" equalTo:_myBaby];
  PFQuery *query = [StandardMilestone query];
  [query whereKey:@"rangeHigh" greaterThanOrEqualTo:rangeDays];
  [query whereKey:@"rangeLow" lessThanOrEqualTo:rangeDays];
  // Bit if a hack here, using string column here : See https://parse.com/questions/trouble-with-nested-query-using-objectid
  [query whereKey:@"objectId" doesNotMatchKey:@"milestoneId" inQuery:innerQuery];
  [query orderByDescending:@"rangeUpper"];

  // If no objects are loaded in memory, we look to the cache
  // first to fill the table and then subsequently do a query
  // against the network.
  
  if ([self.objects count] == 0) {
    innerQuery.cachePolicy = kPFCachePolicyNetworkOnly;
    query.cachePolicy = kPFCachePolicyNetworkOnly;
  }

  return query;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
                        object:(StandardMilestone *)milestone {
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                  reuseIdentifier:CellIdentifier];
  }
  
  // Configure the cell to show todo item with a priority at the bottom
  cell.textLabel.text = milestone.title;
  cell.detailTextLabel.text = milestone.shortDescription;
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [super tableView:tableView didSelectRowAtIndexPath:indexPath];
  
  [self performSegueWithIdentifier:kDDSegueNoteMilestone sender:self];
  
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if([segue.identifier isEqualToString:kDDSegueNoteMilestone]) {
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    ((NoteMilestoneViewController*)segue.destinationViewController).milestone = (StandardMilestone*)[self objectAtIndexPath:selectedIndexPath];
    ((NoteMilestoneViewController*)segue.destinationViewController).baby = _myBaby;
  }
}


@end