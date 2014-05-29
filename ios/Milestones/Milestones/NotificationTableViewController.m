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
  BOOL _needToClearCache;
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
  [self loadObjects];
}

- (PFQuery *)queryForTable {
  
  PFQuery * query = [PFQuery queryWithClassName:[BabyAssignedTip parseClassName]];
  [query includeKey:@"tip"];
  [query whereKey:@"isHidden" equalTo:[NSNumber numberWithBool:NO]];
  [query whereKey:@"baby" equalTo:Baby.currentBaby];
  [query orderByDescending:@"createdOn"];
  query.cachePolicy = kPFCachePolicyCacheThenNetwork;
  query.maxCacheAge = 60; // at max check once a day.

  
  
  TipsFilterQuery * filterQuery = [[TipsFilterQuery alloc] init];
  filterQuery.target = query;
  filterQuery.filter = self.tipFilter;
  filterQuery.exclude = _deleted;
  filterQuery.maxCacheAge = 5;
  filterQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;

  if(_needToClearCache) {
    [filterQuery clearCachedResult];
    filterQuery.cachePolicy = kPFCachePolicyNetworkOnly;
    [query clearCachedResult];
    query.cachePolicy = kPFCachePolicyNetworkOnly;
    [_deleted removeAllObjects];
    _needToClearCache = NO;
  }
  
  return filterQuery;
  
}

#pragma mark UITableViewDelegate
-(PFTableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {

  SWTableViewCell *cell = (SWTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"tipCell" forIndexPath:indexPath];
  __weak SWTableViewCell *weakCell = cell;
  [cell setAppearanceWithBlock:^{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor appNormalColor] title:@"Hide"];
    [rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor appSelectedColor] title:@"Share"];
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
  cell.textLabel.text = tipAssignment.tip.title;
  cell.detailTextLabel.text = [NSString stringWithFormat:@"Delivered %@", [tipAssignment.createdAt stringWithHumanizedTimeDifference]];
  cell.accessoryType = tipAssignment.tip.url.length ? UITableViewCellAccessoryDetailButton : UITableViewCellAccessoryNone;
  
  // TODO: Need graphic for wanring/tip
  
  //cell.imageView.image = [UIImage imageNamed:@"historyNoPic"]; // TODO: tip icon?
  return (PFTableViewCell*)cell; // Hacky!!! Could break!
  
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
    CGFloat newTitleLabelSize = [self getLabelSize:assignment.tip.title andFont:TITLE_FONT];
    CGFloat newDateLabelSize = [self getLabelSize:[assignment.createdAt stringWithHumanizedTimeDifference] andFont:DETAIL_FONT];
    return MAX(newTitleLabelSize + newDateLabelSize + 40, defaultSize);
//  } else {
//    return defaultSize;
//  }
}

-(CGFloat)getLabelSize:(NSString *) text andFont:(UIFont *)font {
  
  NSDictionary *attributesDictionary = @{NSFontAttributeName : font};
  CGRect frame = [text boundingRectWithSize:CGSizeMake(320, 2000.0)
                                          options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:attributesDictionary
                                          context:nil];
  
  CGSize size = frame.size;
  
  return size.height;
}

#pragma mark - SWTableViewDelegate
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)buttonIndex {
  // TODO: rework this to not use PF table view - so we can do animated deletes.
  NSIndexPath * path = [self.tableView indexPathForCell:cell];
  BabyAssignedTip * a = (BabyAssignedTip*)[self objectAtIndexPath:path];
  BOOL deleted = buttonIndex == 0;
  
  if(deleted) {
    a.isHidden = YES;
    [a saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
      _needToClearCache = YES;
      [self loadObjects];
    }];
    [_deleted addObject:a.objectId];
    [self loadObjects];
  }

}



@end
