//
//  BabyTagsTableViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/4/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "BabyTagsTableViewController.h"
#import "PFQueryWithExtendedResultSet.h"

@interface BabyTagsTableViewController ()

@end

@implementation BabyTagsTableViewController {
  // Tag objects to be added to the list.
  NSMutableArray * _allTags;
  BOOL _isLoading;
}


- (void)viewDidLoad
{
  [super viewDidLoad];
  [self networkReachabilityChanged:nil]; // set the initial loading based on connectivity
  _allTags = [NSMutableArray array]; // holds any added tag objects.
  if(_selectedTags) {
    _selectedTags = [[NSMutableSet alloc] initWithSet:_selectedTags];
  } else {
    _selectedTags = [[NSMutableSet alloc] init];
  }
  
  [self loadStandardTags];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkReachabilityChanged:) name:kReachabilityChangedNotification object:nil];
}

-(void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

-(void) networkReachabilityChanged:(NSNotification*)notification {
  [self loadStandardTags];
}

-(void) loadStandardTags {
  if([Reachability isParseCurrentlyReachable]) {
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    PFQuery * query = [Tag query];
    [query whereKey:@"languageId" equalTo:language]; // select only tags in your language
    [query orderByDescending:@"relevance"];
    PFCachePolicy policy = kPFCachePolicyCacheElseNetwork;
    query.cachePolicy = policy;
    query.limit = 500; // TODO: Find more relevant tags?
    _isLoading = YES;
    //[self.tableView reloadData]; // make sure loading row shows up
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
      if(error) {
        NSLog(@"Failed to load tags, will try again :%@", error);
        [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(loadStandardTags) userInfo:nil repeats:false];
      } else {
        _isLoading = NO;
        _allTags = [[NSMutableArray alloc] initWithCapacity:objects.count + _selectedTags.count];
        // Selected Tags first
        [_allTags addObjectsFromArray:[_selectedTags allObjects]];
        for(Tag * tag in objects) {
          if(![_selectedTags containsObject:tag.tagName]) {
            [_allTags addObject:tag.tagName];
          }
        }
        [self.tableView reloadData];
      }
    }];
  }
}


-(void) addNewTag: (NSString*) tagName {
  NSIndexPath * topPath = [NSIndexPath indexPathForRow:0 inSection:0];
  [self.tableView scrollToRowAtIndexPath:topPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
  [self.tableView beginUpdates];
  [_allTags insertObject:tagName atIndex:0];
  [((NSMutableSet*)self.selectedTags) addObject:tagName]; // automatically select
  [self.tableView insertRowsAtIndexPaths:@[topPath] withRowAnimation:UITableViewRowAnimationTop];
  [self.tableView endUpdates];
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if(!_isLoading) {
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSString * tagName = _allTags[indexPath.row];

    if([self.selectedTags containsObject:tagName]) {
      [self setTagCell:cell selected:NO];
      [((NSMutableSet*)self.selectedTags) removeObject:tagName];
    } else {
      [self setTagCell:cell selected:YES];
      [((NSMutableSet*)self.selectedTags) addObject:tagName];
    }
  }
}



-(void) setTagCell:(UITableViewCell*)cell selected:(BOOL) selected {
  cell.imageView.image = [UIImage imageNamed: selected ? @"tagCheckbox_checked" : @"tagCheckbox"];
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return _isLoading ? 1 : _allTags.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell;

  if(_isLoading) {
    cell = [tableView dequeueReusableCellWithIdentifier:@"loadingCell" forIndexPath:indexPath];
    cell.imageView.image = [UIImage animatedImageNamed:@"progress-" duration:1.0];
  } else {
    cell = [tableView dequeueReusableCellWithIdentifier:@"tagCell" forIndexPath:indexPath];
    NSString * tagName = _allTags[indexPath.row];
    cell.textLabel.text = tagName;
    [self setTagCell:cell selected:[self.selectedTags containsObject:tagName]];
  }
  
  return cell;
}

@end
