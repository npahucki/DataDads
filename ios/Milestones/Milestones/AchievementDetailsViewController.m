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

@implementation AchievementDetailsViewController

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
  if(!self.isCustom && !self.achievement.standardMilestone.shortDescription) {
    // Load the description field, since this was defered for the table load.
    PFQuery * query = [StandardMilestone query];
    [query selectKeys:@[@"shortDescription"]];
    [query getObjectInBackgroundWithId:self.achievement.standardMilestone.objectId block:^(PFObject *object, NSError *error) {
      if(!error) {
        self.achievement.standardMilestone.shortDescription  = ((StandardMilestone *) object).shortDescription;
        [self.view layoutSubviews];
        //self.detailsTextView.attributedText = [self createTitleTextFromAchievement];
      }
    }];
  }
  
  PFFile * imageFile = (self.achievement.attachment && [self.achievement.attachmentType rangeOfString : @"image"].location != NSNotFound) ?
  self.achievement.attachment : Baby.currentBaby.avatarImage;
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
  //[self.detailsTextView scrollRectToVisible:self.detailsTextView.frame animated:NO]; // scroll to top
}

//-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//  ((FullPhotoViewController*)segue.destinationViewController).imageView.file = self.achievement.attachment;
//}

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
  if(m.shortDescription) {
    NSAttributedString * descriptionString = [[NSAttributedString alloc] initWithString:m.shortDescription attributes:@{NSFontAttributeName: [UIFont fontForAppWithType:Medium andSize:14.0], NSForegroundColorAttributeName: [UIColor appGreyTextColor]}];
    [attrText appendAttributedString:descriptionString];
    [attrText appendAttributedString:lf];
  }

  // TODO: Figure out relative score
  if(!self.isCustom) {
    // Note: the baby that is loaded into the standard milestones is minimal and does not include the name, thus we use the name from currentBaby which should always be the same as
    // the achievement.
    NSAssert([self.achievement.baby.objectId isEqual:Baby.currentBaby.objectId],@"Expected only acheivements for the current baby!");
    NSAttributedString * placementString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Congrats! %@ is ahead of 89%% of other babys for this milestone!",Baby.currentBaby.name] attributes:@{NSFontAttributeName: [UIFont fontForAppWithType:BoldItalic andSize:15.0], NSForegroundColorAttributeName: [UIColor appSelectedColor]}];
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
