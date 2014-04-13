//
//  AppQueryTableViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/13/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "AppQueryTableViewController.h"

@interface AppQueryTableViewController ()

@end

@implementation AppQueryTableViewController




-(void) viewDidLoad {
  [super viewDidLoad];
  [self stylePFLoadingViewTheHardWay];
  self.pullToRefreshEnabled = YES;
  self.paginationEnabled = YES;
}

// Since we are going to load more items as we get near the bottom, we will return a cell saying more is loading
- (PFTableViewCell *)tableView:(UITableView *)tableView cellForNextPageAtIndexPath:(NSIndexPath *)indexPath {
    PFTableViewCell * cell = [[PFTableViewCell alloc] init];
    cell.imageView.image = [UIImage animatedImageNamed:@"progress-" duration:1.0f];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    //cell.imageView.frame = CGRectMake(0,0,50,50);
    cell.textLabel.text = @"Loading more...";
    cell.textLabel.font = [UIFont fontForAppWithType:Bold andSize:15.0];
    cell.userInteractionEnabled = NO;
    return cell;
}

-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row > _lastPageTriggeredBy.row && self.objects.count > 1 && indexPath.row == self.objects.count - 1 && !self.isLoading) {
    _lastPageTriggeredBy = indexPath;
    [self loadNextPage];
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [super tableView:tableView didSelectRowAtIndexPath:indexPath];
  // We disabled user interaction above!
  NSAssert([indexPath row] <= self.objects.count -1, @"Did not expect click on Load More Cell");
}


-(void) loadObjects {
  [super loadObjects];
  // Must be reset so that more can load again.
  _lastPageTriggeredBy =  0;
}

// Hack to customize the inititial loading view
- (void)stylePFLoadingViewTheHardWay
{
  UIColor *labelTextColor = [UIColor appBlueColor];
  UIColor *labelShadowColor = [UIColor appGreyTextColor];
  
  // go through all of the subviews until you find a PFLoadingView subclass
  for (UIView *subview in self.view.subviews)
  {
    if ([subview class] == NSClassFromString(@"PFLoadingView"))
    {
      // find the loading label and loading activity indicator inside the PFLoadingView subviews
      for (UIView *loadingViewSubview in subview.subviews) {
        if ([loadingViewSubview isKindOfClass:[UILabel class]])
        {
          //[loadingViewSubview removeFromSuperview];
          UILabel *label = (UILabel *)loadingViewSubview;
          label.textColor = labelTextColor;
          label.shadowColor = labelShadowColor;
        }
        
        if ([loadingViewSubview isKindOfClass:[UIActivityIndicatorView class]])
        {
          UIImage * image = [UIImage animatedImageNamed:@"progress-" duration:1.0f];
          UIImageView* imageView = [[UIImageView alloc] initWithFrame:CGRectMake(subview.frame.size.width / 2 - image.size.width / 2, self.view.frame.size.height / 2 - image.size.height * 2 + 10 , image.size.width, image.size.height)];
          [imageView setImage:image];
          [loadingViewSubview removeFromSuperview];
          [subview addSubview: imageView];
        }
      }
    }
  }
}



@end
