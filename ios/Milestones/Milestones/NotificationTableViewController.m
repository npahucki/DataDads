//
//  NotificationTableViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/28/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "NotificationTableViewController.h"
#import "SWTableViewCell.h"


@implementation NotificationTableViewController {
  NSIndexPath * _selectedPath;
  TipType _tipFilter ;
}

-(TipType) tipFilter {
  return _tipFilter;
}

-(void) setTipFilter:(TipType) tipFilter {
  _tipFilter = tipFilter;
  [self loadObjects];
}

-(void) viewDidLoad {
  [super viewDidLoad];
  _tipFilter = TipTypeNormal;
}

- (PFQuery *)queryForTable {
  PFQuery * query = [Baby.currentBaby relationForKey:@"currentTips"].query;
  [query selectKeys:@[@"title",@"shortDescription",@"url",@"tipType"]];
  query.cachePolicy = kPFCachePolicyCacheThenNetwork;
  if(_tipFilter) {
    [query whereKey:@"tipType" equalTo:@(_tipFilter)];
  }
  return query;
}


-(PFTableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {

  SWTableViewCell *cell = (SWTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"tipCell" forIndexPath:indexPath];
  __weak SWTableViewCell *weakCell = cell;
  [cell setAppearanceWithBlock:^{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor: [UIColor appNormalColor] title:@"Delete"];
    weakCell.rightUtilityButtons = rightUtilityButtons;
    
    weakCell.textLabel.font = [UIFont fontForAppWithType:Book andSize:14];
    weakCell.textLabel.textColor = [UIColor appNormalColor];
    weakCell.detailTextLabel.font = [UIFont fontForAppWithType:Book andSize:12];
    weakCell.detailTextLabel.textColor = [UIColor appGreyTextColor];
    weakCell.containingTableView = tableView;
  } force:NO];
  
  Tip* tip = (Tip*)[self objectAtIndexPath:indexPath];
  
  [cell setCellHeight:cell.frame.size.height];
  cell.textLabel.text = tip.title;
  cell.detailTextLabel.text = tip.shortDescription;
  cell.accessoryType = tip.url ? UITableViewCellAccessoryDetailButton : UITableViewCellAccessoryNone;
  
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

  
  CGFloat defaultSize = [super tableView:tableView heightForRowAtIndexPath:indexPath];
  if(indexPath.row > self.objects.count -1) {
    return defaultSize;
  }
  
  //  if([indexPath isEqual:_selectedPath]) {
    Tip* tip = (Tip*)[self objectAtIndexPath:indexPath];
    CGFloat newLabelSize = [self getLabelSize:tip.title andFont:[UIFont fontForAppWithType:Book andSize:15]] + 30;
    return MAX(newLabelSize, defaultSize);
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


@end
