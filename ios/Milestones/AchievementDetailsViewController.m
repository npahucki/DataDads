//
//  AchievementDetailsViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/27/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "AchievementDetailsViewController.h"
#import "WebViewerViewController.h"

@interface AchievementDetailsViewController ()

@end

@implementation AchievementDetailsViewController {
  float _percentile;
}

// Global for all instances
NSDateFormatter * _dateFormatter;

-(void) awakeFromNib {
  if(!_dateFormatter) {
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
  }
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  NSAssert(self.achievement,@"Expected Achievement to be set before loading view!");

  //self.detailsImageButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
  self.detailsTextView.delegate = self;
  NSDictionary *linkAttributes = @{NSForegroundColorAttributeName: [UIColor appSelectedColor],
                                   NSUnderlineColorAttributeName: [UIColor appSelectedColor],
                                   NSUnderlineStyleAttributeName: @(NSUnderlinePatternSolid)};
  self.detailsTextView.linkTextAttributes = linkAttributes; // customizes the appearance of links


  self.detailsImageButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
  self.detailsImageButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
  self.detailsImageButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
  
  // The references we have when these objects are loaded, do not have all the baby info in them, so we swap them out here.
  if(!self.achievement.baby.isDataAvailable) {
    NSAssert([self.achievement.baby.objectId isEqualToString:Baby.currentBaby.objectId],@"Expected achievements for current baby only!");
    self.achievement.baby = Baby.currentBaby;
  }
  
  if(!self.isCustom) {
    // Calculate the percentile
    [self.achievement calculatePercentileRankingWithBlock:^(float percentile) {
      if(percentile > 0) {
        _percentile = percentile;
        self.detailsTextView.attributedText = [self createTitleTextFromAchievement];
      }
    }];
  }

  
  // Start with the thumbnail (if loaded), then load the bigger one later on.
  PFFile * thumbnailImageFile = self.achievement.attachmentThumbnail ? self.achievement.attachmentThumbnail : self.achievement.baby.avatarImageThumbnail;
  self.detailsImageButton.alpha = self.achievement.attachmentThumbnail ? 1.0 : 0.3;
  [thumbnailImageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
      [self.detailsImageButton setImage:[UIImage imageWithData:data] forState:UIControlStateNormal];
  }];

  [self.achievement fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
    if(!error) {
      self.achievement = (MilestoneAchievement*) object;
      BOOL hasImageAttachment = self.achievement.attachment && [self.achievement.attachmentType rangeOfString:@"image"].location != NSNotFound;
      self.detailsImageButton.alpha = hasImageAttachment ? 1.0 : 0.3;
      PFFile * imageFile = hasImageAttachment ?  self.achievement.attachment : self.achievement.baby.avatarImage;
      if(imageFile) {
        [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
          if(!error) {
            [self.detailsImageButton setImage:[UIImage imageWithData:data] forState:UIControlStateNormal];
          }
        }];
      }
    }
  }];
  
  // Make the bottom of the Text field fade out
  CAGradientLayer *l = [CAGradientLayer layer];
  l.frame = self.detailsTextViewContainerView.bounds;
  l.colors = [NSArray arrayWithObjects:(id)[UIColor whiteColor].CGColor, (id)[UIColor clearColor].CGColor, nil];
  l.startPoint = CGPointMake(0.5f, 0.5f);
  l.endPoint = CGPointMake(0.5f, 1.0f);
  self.detailsTextViewContainerView.layer.mask = l;
  
  
}

-(BOOL) isCustom {
  return self.achievement.standardMilestone == nil;
}

-(void) viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  [self.detailsImageButton.layer setCornerRadius:self.detailsImageButton.frame.size.width/2];
  self.detailsImageButton.layer.masksToBounds = YES;
  self.detailsImageButton.layer.borderWidth = 1;
  self.detailsTextView.attributedText = [self createTitleTextFromAchievement];
  [self.detailsTextView  setContentOffset:CGPointZero animated:NO];
}

-(NSAttributedString *) createTitleTextFromAchievement {
  StandardMilestone * m = self.achievement.standardMilestone;
  NSAttributedString * lf = [[NSAttributedString alloc] initWithString:@"\n"];
  NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] init];
  NSDictionary *dataLabelTextAttributes = @{NSFontAttributeName: [UIFont fontForAppWithType:Bold andSize:15.0], NSForegroundColorAttributeName: [UIColor blackColor]};
  NSDictionary *dataValueTextAttributes = @{NSFontAttributeName: [UIFont fontForAppWithType:Medium andSize:15.0], NSForegroundColorAttributeName: [UIColor blackColor]};
  
  // Title - Always use the custom title if not empty, this way, if later on we link a standard milestone, we still read the text that we enetered.
  NSAttributedString * titleString = [[NSAttributedString alloc] initWithString:self.achievement.displayTitle attributes:@{NSFontAttributeName: [UIFont fontForAppWithType:Bold andSize:15.0], NSForegroundColorAttributeName: [UIColor appNormalColor]}];
  [attrText appendAttributedString:titleString];
  [attrText appendAttributedString:lf];
  
//  // Desscription
//  if(_shortDescription) {
//    NSAttributedString * descriptionString = [[NSAttributedString alloc] initWithString:_shortDescription attributes:@{NSFontAttributeName: [UIFont fontForAppWithType:Medium andSize:14.0], NSForegroundColorAttributeName: [UIColor appGreyTextColor]}];
//    [attrText appendAttributedString:descriptionString];
//    [attrText appendAttributedString:lf];
//  }

  // TODO: Figure out relative score
  if(_percentile > 0) {
    NSString * msg;
    if(_percentile > 70) {
      msg = [NSString stringWithFormat:@"Congrats! %@ is ahead of %.02f%% of other babies for this milestone!", self.achievement.baby.name,_percentile];
    } else {
      msg = [NSString stringWithFormat:@"%@ is in the %.02fth percentile for this milestone.", self.achievement.baby.name,_percentile];
    }
    NSAttributedString * placementString = [[NSAttributedString alloc] initWithString:msg attributes:@{NSFontAttributeName: [UIFont fontForAppWithType:BoldItalic andSize:15.0], NSForegroundColorAttributeName: [UIColor appSelectedColor]}];
    [attrText appendAttributedString:lf];
    [attrText appendAttributedString:placementString];
    [attrText appendAttributedString:lf];
  }
  
  // Comments
  if(self.achievement.comment.length) {
    NSAttributedString * commentsLabel = [[NSAttributedString alloc] initWithString:@"Comments: " attributes:dataLabelTextAttributes];
    NSAttributedString * commentsValue = [[NSAttributedString alloc] initWithString:self.achievement.comment attributes:dataValueTextAttributes];
    [attrText appendAttributedString:lf];
    [attrText appendAttributedString:commentsLabel];
    [attrText appendAttributedString:commentsValue];
    [attrText appendAttributedString:lf];
  }
  
  // Completion date
  NSAttributedString * completedOnLabel = [[NSAttributedString alloc] initWithString:@"Completed On: " attributes:dataLabelTextAttributes];
  NSAttributedString * completedOnValue = [[NSAttributedString alloc] initWithString:[_dateFormatter stringFromDate:self.achievement.completionDate]  attributes:dataValueTextAttributes];
  [attrText appendAttributedString:lf];
  [attrText appendAttributedString:completedOnLabel];
  [attrText appendAttributedString:completedOnValue];
  [attrText appendAttributedString:lf];
  
  // Range
  if(!self.isCustom) {
    NSAttributedString * rangeLabel = [[NSAttributedString alloc] initWithString:@"Typical Completion Range: " attributes:dataLabelTextAttributes];
    NSAttributedString * rangeValue = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ to %@ days",m.rangeLow,m.rangeHigh] attributes:dataValueTextAttributes];
    [attrText appendAttributedString:rangeLabel];
    [attrText appendAttributedString:rangeValue];
    [attrText appendAttributedString:lf];
  }
  
  if(m.url) {
    [attrText appendAttributedString:lf];
    NSMutableAttributedString *readMoreLabel = [[NSMutableAttributedString alloc] initWithString:@"Read More..." attributes:@{
                                                                                                                              NSFontAttributeName: [UIFont fontForAppWithType:BoldItalic andSize:17.0],
                                                                                                                              NSForegroundColorAttributeName: [UIColor appSelectedColor]
                                                                                                                              }];
    [readMoreLabel addAttribute:NSLinkAttributeName value:m.url range:NSMakeRange(0, readMoreLabel.length)];
    [attrText appendAttributedString:readMoreLabel];
  }

  
  return attrText;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)url inRange:(NSRange)characterRange {
  [self presentViewController:[WebViewerViewController webViewForUrl:url] animated:YES completion:NULL];
  return NO;
}









@end
