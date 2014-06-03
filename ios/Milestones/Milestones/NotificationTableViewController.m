//
//  NotificationTableViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/28/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "NotificationTableViewController.h"
#import "SWTableViewCell.h"
#import "NSDate+HumanizedTime.h"
#import "WebViewerViewController.h"

#define TITLE_FONT [UIFont fontForAppWithType:Book andSize:14]
#define DETAIL_FONT [UIFont fontForAppWithType:Book andSize:12]

@interface TipsFilterQuery : PFQuery
@property TipType filter;
@property PFQuery *target;
@property NSMutableArray *exclude;
@end

@implementation TipsFilterQuery

-(NSString*) parseClassName {
  return _target.parseClassName;
}

/*!
 Icky Hack to be able to filter based on the filter criteria since parse does not let you specify a whereKey on a pointed to object.
 */
- (void)findObjectsInBackgroundWithBlock:(PFArrayResultBlock)queryBlock {
  if(queryBlock) {
    _target.skip = self.skip;
    _target.limit = self.limit;
    [_target findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
      if(!error) {
        if(_filter || _exclude.count) {
          NSMutableArray * newArray = [NSMutableArray arrayWithCapacity:objects.count];
          for(BabyAssignedTip* a in objects) {
            if((!_filter || a.tip.tipType.integerValue == _filter) && ![_exclude containsObject:a.objectId]) {
              [newArray addObject:a];
            }
          }
          objects = newArray;
        }
      }
      queryBlock(objects, error);
    }];
  }
}

@end


@implementation NotificationTableViewController {
  NSIndexPath * _selectedPath;
  TipType _tipFilter;
  BOOL _loadBecauseChangedFilter;
  NSMutableArray * _deleted;
}

-(void) viewDidLoad {
  [super viewDidLoad];
  _deleted = [NSMutableArray arrayWithCapacity:5];
}

-(TipType) tipFilter {
  return _tipFilter;
}

-(void) setTipFilter:(TipType) tipFilter {
  _tipFilter = tipFilter;
  _loadBecauseChangedFilter = YES;
  [self loadObjects];
}

- (PFQuery *)queryForTable {
  
  PFQuery * query = [PFQuery queryWithClassName:[BabyAssignedTip parseClassName]];
  [query includeKey:@"tip"];
  [query whereKey:@"isHidden" equalTo:[NSNumber numberWithBool:NO]];
  [query whereKey:@"baby" equalTo:Baby.currentBaby];
  [query orderByDescending:@"createdOn"];
  query.cachePolicy = kPFCachePolicyCacheThenNetwork;
  query.maxCacheAge = 60 * 60 * 24; // at max check once a day.
  
  TipsFilterQuery * filterQuery = [[TipsFilterQuery alloc] init];
  filterQuery.target = query;
  filterQuery.filter = self.tipFilter;
  filterQuery.exclude = _deleted;
  filterQuery.maxCacheAge = 5;
  filterQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;

  if(_loadBecauseChangedFilter) {
    // In this case we dont want to hit network again
    filterQuery.cachePolicy = kPFCachePolicyCacheOnly;
    query.cachePolicy = kPFCachePolicyCacheOnly;
    _loadBecauseChangedFilter = NO;
  }
  
  return filterQuery;
  
}

#pragma mark UITableViewDelegate


-(PFTableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {

  SWTableViewCell *cell = (SWTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"tipCell" forIndexPath:indexPath];
  __weak SWTableViewCell *weakCell = cell;
  [cell setAppearanceWithBlock:^{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor appSelectedColor] title:@"Share"];
    [rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor redColor] title:@"Hide"];
    weakCell.rightUtilityButtons = rightUtilityButtons;
    
    weakCell.textLabel.font = TITLE_FONT;
    weakCell.textLabel.textColor = [UIColor appNormalColor];
    weakCell.detailTextLabel.font = DETAIL_FONT;
    weakCell.detailTextLabel.textColor = [UIColor appGreyTextColor];
    weakCell.containingTableView = tableView;
    weakCell.delegate = self;
  } force:NO];
  
  BabyAssignedTip* tipAssignment = (BabyAssignedTip*)[self objectAtIndexPath:indexPath];
  
  [cell setCellHeight:cell.frame.size.height];
  cell.textLabel.text = tipAssignment.tip.titleForCurrentBaby;
  cell.detailTextLabel.text = [NSString stringWithFormat:@"Delivered %@", [tipAssignment.assignmentDate stringWithHumanizedTimeDifference]];
  cell.accessoryType = tipAssignment.tip.url.length ? UITableViewCellAccessoryDetailButton : UITableViewCellAccessoryNone;
  
  // TODO: Need graphic for wanring/tip
  
  return (PFTableViewCell*)cell; // Hacky!!! Could break!
  
}

-(void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
  [self performSegueWithIdentifier:kDDSegueShowWebView sender:[self objectAtIndexPath:indexPath]];
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if([segue.identifier isEqualToString:kDDSegueShowWebView]) {
    WebViewerViewController * webView = (WebViewerViewController *)segue.destinationViewController;
    BabyAssignedTip * assignment = (BabyAssignedTip *)sender;
    NSAssert(assignment.tip.url.length, @"This should only be called on a tip with a URL");
    webView.url = [NSURL URLWithString:assignment.tip.url] ;
  }
}

// LOOKS COOL, BUT HAS ALL SORTS OF RENDERING ISSUES, MAYBE LATER!

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//  
//  SWTableViewCell* previousCell = _selectedPath ? (SWTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath] : nil;
//  
//  _selectedPath = indexPath;
//  SWTableViewCell* cell = (SWTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
//
//  [UIView beginAnimations:@"expandAnimationId" context:nil];
//  [UIView setAnimationDuration:0.3]; // Set duration here
//  [CATransaction begin];
//  [CATransaction setCompletionBlock:^{
//    // This is needed otherwise the cell does not draw it self correctly.
//    if(previousCell) {
//      previousCell.textLabel.numberOfLines = 2;
//      previousCell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
//      [previousCell sizeToFit];
//    }
//
//    cell.textLabel.numberOfLines = 0; // Allow all the content to be shown.
//    [cell.textLabel sizeToFit];
//    [cell setCellHeight:cell.frame.size.height];
//  }];
//  [self.tableView beginUpdates];
//  [self.tableView endUpdates];
//  [CATransaction commit];
//  [UIView commitAnimations];
//
//
//
//}

#pragma mark - private methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

  
  CGFloat defaultSize = [super tableView:tableView heightForRowAtIndexPath:indexPath];
  if(indexPath.row > self.objects.count -1) {
    return defaultSize;
  }
  
  //  if([indexPath isEqual:_selectedPath]) {
    BabyAssignedTip* assignment = (BabyAssignedTip*)[self objectAtIndexPath:indexPath];
    int width = assignment.tip.url.length ? self.tableView.frame.size.width - 44 : self.tableView.frame.size.width;
    CGFloat newTitleLabelSize = [self getLabelSize:assignment.tip.titleForCurrentBaby andFont:TITLE_FONT withMaxWidth:width];
    CGFloat newDateLabelSize = [self getLabelSize:[assignment.createdAt stringWithHumanizedTimeDifference] andFont:DETAIL_FONT withMaxWidth:width];
    return MAX(newTitleLabelSize + newDateLabelSize + 40, defaultSize);
//  } else {
//    return defaultSize;
//  }
}

-(CGFloat)getLabelSize:(NSString *) text andFont:(UIFont *)font withMaxWidth:(int) width {
  
  NSDictionary *attributesDictionary = @{NSFontAttributeName : font};
  CGRect frame = [text boundingRectWithSize:CGSizeMake(width, 2000.0)
                                          options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:attributesDictionary
                                          context:nil];
  
  CGSize size = frame.size;
  
  return size.height;
}

-(void) hideNotification:(BabyAssignedTip*) notificaiton withIndexPath:(NSIndexPath*) path {
  notificaiton.isHidden = YES;
  [notificaiton saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    [self loadObjects];
  }];
  [_deleted addObject:notificaiton.objectId];
  [self loadObjects];
}

-(void) shareNotification:(BabyAssignedTip*) notificaiton withIndexPath:(NSIndexPath*) path {
  [[[UIAlertView alloc] initWithTitle:@"Keep your pants on!" message:@"This feature is scheduled for next sprint!" delegate:nil cancelButtonTitle:@"Yeah, I got it" otherButtonTitles:nil, nil] show];
}

#pragma mark - SWTableViewDelegate
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)buttonIndex {
  // TODO: rework this to not use PF table view - so we can do animated deletes.
  NSIndexPath * path = [self.tableView indexPathForCell:cell];
  BabyAssignedTip * a = (BabyAssignedTip*)[self objectAtIndexPath:path];
  if(buttonIndex == 0) {
    [self shareNotification:a withIndexPath:path];
  } else if(buttonIndex == 1) {
    [self hideNotification:a withIndexPath:path];
  }
}

- (BOOL)swipeableTableViewCell:(SWTableViewCell *)cell canSwipeToState:(SWCellState)state {
  if(state != kCellStateCenter) {
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
  return YES;
}


// Work around a bug where the accessory view is on top of the slide cell.
- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state {
  if(state == kCellStateCenter) {
    // Back to normal. Must use delay to not interfere with scroll animation.
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
      NSIndexPath * path = [self.tableView indexPathForCell:cell];
      BabyAssignedTip * tipAssignment = (BabyAssignedTip*)[self objectAtIndexPath:path];
      cell.accessoryType = tipAssignment.tip.url.length ? UITableViewCellAccessoryDetailButton : UITableViewCellAccessoryNone;
    });
  }
}



@end
