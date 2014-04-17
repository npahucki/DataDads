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
  self.pullToRefreshEnabled = YES;
  self.paginationEnabled = YES;
}

-(void) viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  [self stylePFLoadingViewTheHardWay];
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

-(void) objectsWillLoad {
  [super objectsWillLoad];
  for (UIView *subview in self.view.subviews)
  {
    if ([subview class] == NSClassFromString(@"UIRefreshControl")) {
    
    }

  }
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
  NSAssert([indexPath row] <= self.objects.count - 1, @"Did not expect click on Load More Cell");
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
  
  // go through all of the subviews until you find a PFLoadingView subclass
  UILabel * label;
  UIImageView* imageView;
  
  for (UIView *subview in self.view.subviews)
  {
    if ([subview class] == NSClassFromString(@"PFLoadingView"))
    {
      for (UIView *loadingViewSubview in subview.subviews) {
        if ([loadingViewSubview isKindOfClass:[UILabel class]]) {
          label = (UILabel *)loadingViewSubview;
          label.textColor = labelTextColor;
          label.font = [UIFont fontForAppWithType:Bold andSize:27];
          [label sizeToFit];
        }
        if ([loadingViewSubview isKindOfClass:[UIActivityIndicatorView class]]) {
          [loadingViewSubview removeFromSuperview];
          UIImage * image = [UIImage animatedImageNamed:@"progress-" duration:1.0f];
          UIImageView* imageView = [[UIImageView alloc] initWithImage:image];
          [subview addSubview: imageView];
        }
        if ([loadingViewSubview isKindOfClass:[UIImageView class]]) {
          imageView = (UIImageView*) loadingViewSubview;
        }
        imageView.frame = CGRectMake((subview.frame.size.width - imageView.image.size.width) / 2, label.frame.origin.y - imageView.image.size.height - 15 , imageView.image.size.width, imageView.image.size.height);
      }
    }
  }





}



@end
