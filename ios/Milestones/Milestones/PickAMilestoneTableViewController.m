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
}

-(void) babyUpdated:(NSNotification*)notification {
  _myBaby =  [notification.userInfo objectForKey:@""];
  [self loadObjects];
}

// TODO: When we need to add sections, see https://parse.com/questions/using-pfquerytableviewcontroller-for-uitableview-sections
- (PFQuery *)queryForTable {
  // If no Baby available yet, don't try to load anything
  if(!_myBaby) return nil;
  
  NSNumber * rangeDays = [NSNumber numberWithInteger:_myBaby.daysSinceDueDate];
  PFQuery *query = [PFQuery queryWithClassName:@"StandardMilestones"];
  [query whereKey:@"rangeHigh" greaterThanOrEqualTo:rangeDays];
  [query whereKey:@"rangeLow" lessThanOrEqualTo:rangeDays];
  
  // If no objects are loaded in memory, we look to the cache
  // first to fill the table and then subsequently do a query
  // against the network.
  if ([self.objects count] == 0) {
    query.cachePolicy = kPFCachePolicyCacheThenNetwork;
  }
  
  [query orderByDescending:@"rangeUpper"];
  return query;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
                        object:(PFObject *)object {
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                  reuseIdentifier:CellIdentifier];
  }
  
  // Configure the cell to show todo item with a priority at the bottom
  cell.textLabel.text = [object objectForKey:@"title"];
  cell.detailTextLabel.text = [object objectForKey:@"description"];
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [super tableView:tableView didSelectRowAtIndexPath:indexPath];
  [self performSegueWithIdentifier:@"noteMilestone" sender:self];

}


@end