//
//  BabyTagsTableViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/4/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "BabyTagsTableViewController.h"

@interface BabyTagsTableViewController ()

@end

@implementation BabyTagsTableViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.selectedTags = [[NSMutableSet alloc] init];
  self.objectsPerPage = 100; // small to load
  [self stylePFLoadingViewTheHardWay];
}

// Hack to customize the inititial loading view
- (void)stylePFLoadingViewTheHardWay
{
  UIColor *labelTextColor = [UIColor blueColor];
  UIColor *labelShadowColor = [UIColor darkGrayColor];
  
  // go through all of the subviews until you find a PFLoadingView subclass
  for (UIView *subview in self.view.subviews)
  {
    if ([subview class] == NSClassFromString(@"PFLoadingView"))
    {
      // find the loading label and loading activity indicator inside the PFLoadingView subviews
      for (UIView *loadingViewSubview in subview.subviews) {
        if ([loadingViewSubview isKindOfClass:[UILabel class]])
        {
          UILabel *label = (UILabel *)loadingViewSubview;
          {
            label.textColor = labelTextColor;
            label.shadowColor = labelShadowColor;
          }
        }
        
        if ([loadingViewSubview isKindOfClass:[UIActivityIndicatorView class]])
        {
          UIImage * image = [UIImage animatedImageNamed:@"progress-" duration:1.0f];
          UIImageView* imageView = [[UIImageView alloc] initWithFrame:CGRectMake(subview.frame.size.width / 2 - image.size.width / 2, subview.frame.size.height / 2 - image.size.height / 2, image.size.width, image.size.height)];
          [imageView setImage:image];
          [loadingViewSubview removeFromSuperview];
          [subview addSubview: imageView];
        }
      }
    }
  }
}

- (PFQuery *)queryForTable {
  NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
  // TODO: Make a query that allows new object to be added or excluded.
  PFQuery * query = [Tag query];
  [query whereKey:@"languageId" equalTo:language]; // select only tags in your language
  [query orderByDescending:@"relevance"];
  PFCachePolicy policy = self.objects.count ? kPFCachePolicyNetworkOnly : kPFCachePolicyCacheThenNetwork;
  query.cachePolicy = policy;
  return query;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
  Tag* tag = (Tag*)[self objectAtIndexPath:indexPath];

  if([self.selectedTags containsObject:tag.tagName]) {
    cell.accessoryType = UITableViewCellAccessoryNone;
    [((NSMutableSet*)self.selectedTags) removeObject:tag.tagName];
  } else {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    [((NSMutableSet*)self.selectedTags) addObject:tag.tagName];
  }
  
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
                        object:(Tag *)tag {
  static NSString *CellIdentifier = @"TagCell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
  cell.textLabel.text = tag.tagName;
  cell.accessoryType = [self.selectedTags containsObject:tag.tagName] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
  return cell;
}

@end
