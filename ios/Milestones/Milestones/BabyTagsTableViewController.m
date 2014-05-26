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
  NSMutableArray * _addedTags;
}


- (void)viewDidLoad
{
  [super viewDidLoad];
  [self networkReachabilityChanged:nil]; // set the initial loading based on connectivity
  _addedTags = [NSMutableArray array]; // holds any added tag objects.
  self.selectedTags = [[NSMutableSet alloc] init];
  self.objectsPerPage = 100; // small to load
  self.pullToRefreshEnabled = NO;
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkReachabilityChanged:) name:kReachabilityChangedNotification object:nil];
}

-(void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

-(void) networkReachabilityChanged:(NSNotification*)notification {
  if([Reachability isParseCurrentlyReachable]) {
    self.loadingImageView.image = [UIImage animatedImageNamed:@"progress-" duration:1.0f];
    self.loadingTextLabel.text = @"Loading...";
  } else {
    self.loadingImageView.image = [UIImage imageNamed:@"error-9"];
    self.loadingTextLabel.text = @"No Network";
  }
  [self loadObjects:0 clear:YES];
}

-(void) addNewTag: (NSString*) tagText {
  Tag * tag = [Tag object];
  tag.tagName = tagText;
  tag.objectId = tagText;
  [_addedTags insertObject:tag atIndex:0];
  [((NSMutableSet*)self.selectedTags) addObject:tagText]; // automatically select
  [self loadObjects];
}



- (PFQuery *)queryForTable {
  if([Reachability isParseCurrentlyReachable]) {
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    // TODO: Make a query that allows new object to be added or excluded.
    PFQueryWithExtendedResultSet * query = [[PFQueryWithExtendedResultSet alloc] initWithClassName:@"Tags"];
    [query whereKey:@"languageId" equalTo:language]; // select only tags in your language
    [query orderByDescending:@"relevance"];
    PFCachePolicy policy = kPFCachePolicyCacheElseNetwork;
    query.cachePolicy = policy;
    query.headIncludeArray = _addedTags;
    return query;
  } else {
    return nil;
  }
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
  Tag* tag = (Tag*)[self objectAtIndexPath:indexPath];

  if([self.selectedTags containsObject:tag.tagName]) {
    [self setTagCell:cell selected:NO];
    [((NSMutableSet*)self.selectedTags) removeObject:tag.tagName];
  } else {
    [self setTagCell:cell selected:YES];
    [((NSMutableSet*)self.selectedTags) addObject:tag.tagName];
  }
}



-(void) setTagCell:(UITableViewCell*)cell selected:(BOOL) selected {
  cell.imageView.image = [UIImage imageNamed: selected ? @"tagCheckbox_checked" : @"tagCheckbox"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
                        object:(Tag *)tag {
  static NSString *CellIdentifier = @"TagCell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
  cell.textLabel.text = tag.tagName;
  [self setTagCell:cell selected:[self.selectedTags containsObject:tag.tagName]];
  return cell;
}

@end
