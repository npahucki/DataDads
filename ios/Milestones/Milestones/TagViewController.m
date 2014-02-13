//
//  TagViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/28/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "TagViewController.h"
#import "HPLTagCloudGenerator.h"
#import "MBProgressHUD.h"
#import "Tag.h"

@interface TagViewController ()

@end

@implementation TagViewController

@synthesize delegate;

-(id)initWithCoder:(NSCoder *)aDecoder {
  selectedTags = [[NSMutableOrderedSet alloc] init];
  return [super initWithCoder:aDecoder];
}

-(void) viewDidLoad {
  [super viewDidLoad];
  MBProgressHUD * hud = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
  hud.dimBackground = YES;
  hud.labelText = NSLocalizedString(@"Loading tags", nil);
  
  NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
  PFQuery * query = [Tag query];
  [query whereKey:@"languageId" equalTo:language]; // select only tags in your language 
  query.cachePolicy = kPFCachePolicyNetworkOnly;
  [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    // Can get called twice, once for
    if (!error) {
      NSMutableDictionary * tagDict = [[NSMutableDictionary alloc] initWithCapacity:[objects count]];
      for(Tag *tag in objects) {
        [tagDict setObject:tag.relevance forKey:tag.tagName];
      }
      [self setTagDictionary:tagDict];
      [MBProgressHUD hideHUDForView:self.view animated:NO];
    } else {
      if(error.code != kPFErrorCacheMiss) {
        [MBProgressHUD hideHUDForView:self.view animated:NO];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not load the tag cloud. Please make sure that you are conencted to a network and try again." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
        [alert show];
        NSLog(@"Could not load the tag cloud, must try later %@", error);
      }
    }
  }];
}


-(void) setTagDictionary:(NSDictionary *)tagDictionary {
  HPLTagCloudGenerator *tagGenerator = [[HPLTagCloudGenerator alloc] init];
  // TOOD: size based on number of tags? Also include categories?
  tagGenerator.size = CGSizeMake(self.view.frame.size.width *2, self.view.frame.size.height*2);
  self.scrollView.contentSize = tagGenerator.size;
  tagGenerator.tagDict = tagDictionary;
  tagViews = [tagGenerator generateTagViews]; // assign to retain
  for(UILabel *v in tagViews) {
    v.userInteractionEnabled = YES;
    v.highlightedTextColor = [UIColor blueColor];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapLabelWithGesture:)];
    [v addGestureRecognizer:tapGesture];
    [self.scrollView addSubview:v];
  }
  [self.scrollView scrollRectToVisible:CGRectMake(tagGenerator.size.width / 4, tagGenerator.size.height / 4, self.view.frame.size.width, self.view.frame.size.height) animated:NO];
}

- (IBAction)didClickDoneButton:(id)sender {
  [self.delegate tagsDidFinishSelection:selectedTags];
}



- (void)didTapLabelWithGesture:(UITapGestureRecognizer *)tapGesture {
  UILabel * label = ((UILabel*) tapGesture.view);
  if([selectedTags containsObject:[label text]]) {
    // Already in the list, take it out
    [selectedTags removeObject:[label text]];
    label.highlighted = NO;
  } else {
    [selectedTags addObject:[label text]];
    label.highlighted = YES;
  }
}



@end
