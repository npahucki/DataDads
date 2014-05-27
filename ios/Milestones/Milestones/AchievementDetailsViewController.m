//
//  AchievementDetailsViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/27/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "AchievementDetailsViewController.h"

@interface AchievementDetailsViewController ()

@end

@implementation AchievementDetailsViewController {
  NSString * _shortDescription;
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

  // The references we have when these objects are loaded, do not have all the baby info in them, so we swap them out here.
  if(!self.achievement.baby.isDataAvailable) {
    NSAssert([self.achievement.baby.objectId isEqualToString:Baby.currentBaby.objectId],@"Expected achievements for current baby only!");
    self.achievement.baby = Baby.currentBaby;
  }
  
  if(!self.isCustom) {
    
    // Load the description since it was not included in the original milestone (for brevity)
    if(self.achievement.standardMilestone.shortDescription) {
      _shortDescription = self.achievement.standardMilestone.shortDescription;
    } else {
      // Load the description field, since this was defered for the table load.
      PFQuery * query = [StandardMilestone query];
      [query selectKeys:@[@"shortDescription"]];
      [query getObjectInBackgroundWithId:self.achievement.standardMilestone.objectId block:^(PFObject *object, NSError *error) {
        if(!error) {
          _shortDescription  = ((StandardMilestone *) object).shortDescription;
          self.detailsTextView.attributedText = [self createTitleTextFromAchievement];
        }
      }];
    }
    
    // Calculate the percentile
    [self.achievement calculatePercentileRankingWithBlock:^(float percentile) {
      if(percentile > 0) {
        _percentile = percentile;
        self.detailsTextView.attributedText = [self createTitleTextFromAchievement];
      }
    }];
  }
  
  // Load the image
  PFFile * imageFile = (self.achievement.attachment && [self.achievement.attachmentType rangeOfString : @"image"].location != NSNotFound) ?
  self.achievement.attachment : self.achievement.baby.avatarImage;
  if(imageFile) {
    [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
      if(!error) {
        [self.detailsImageButton setImage:[UIImage imageWithData:data] forState:UIControlStateNormal];
        self.detailsImageButton.contentMode = UIViewContentModeCenter;
      }
    }];
  }
  self.detailsImageButton.alpha = imageFile == self.achievement.attachment ? 1.0 : 0.3;
  
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
  
  // Title
  NSAttributedString * titleString = [[NSAttributedString alloc] initWithString:m ? m.title : self.achievement.customTitle attributes:@{NSFontAttributeName: [UIFont fontForAppWithType:Bold andSize:15.0], NSForegroundColorAttributeName: [UIColor appNormalColor]}];
  [attrText appendAttributedString:titleString];
  [attrText appendAttributedString:lf];
  
  // Desscription
  if(_shortDescription) {
    NSAttributedString * descriptionString = [[NSAttributedString alloc] initWithString:_shortDescription attributes:@{NSFontAttributeName: [UIFont fontForAppWithType:Medium andSize:14.0], NSForegroundColorAttributeName: [UIColor appGreyTextColor]}];
    [attrText appendAttributedString:descriptionString];
    [attrText appendAttributedString:lf];
  }

  // TODO: Figure out relative score
  if(_percentile > 0) {
    NSString * msg;
    if(_percentile > 70) {
      msg = [NSString stringWithFormat:@"Congrats! %@ is ahead of %.02f%% of other babys for this milestone!", self.achievement.baby.name,_percentile];
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
    NSAttributedString * rangeLabel = [[NSAttributedString alloc] initWithString:@"Completion Range: " attributes:dataLabelTextAttributes];
    NSAttributedString * rangeValue = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ to %@ days",m.rangeLow,m.rangeHigh] attributes:dataValueTextAttributes];
    [attrText appendAttributedString:rangeLabel];
    [attrText appendAttributedString:rangeValue];
    [attrText appendAttributedString:lf];
  }
  return attrText;
}

  






@end
