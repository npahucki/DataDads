//
//  SettingsViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/1/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>`
#import "SettingsViewController.h"
#import "Baby.h"

@implementation SettingsViewController


-(void) viewDidLoad {
  [super viewDidLoad];
  NSAssert(Baby.currentBaby.name, @"Expected a current baby would be set before setting invoked");
  self.babyNameLabel.font = [UIFont fontWithName:@"GothamRounded-Bold" size:21.0];
  self.babyNameLabel.text = Baby.currentBaby.name;
  self.ageLabel.font = [UIFont fontWithName:@"GothamRounded-Medium" size:18.0];
  self.ageLabel.text = [self ageFormatedAsNiceString:Baby.currentBaby.daysSinceBirth];
}

-(void) viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  [self.babyAvatar.layer setCornerRadius:self.babyAvatar.frame.size.width/2];
  self.babyAvatar.layer.masksToBounds = YES;
  self.babyAvatar.layer.borderWidth = 1;
}

-(void) viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
}


- (IBAction)doneButtonClicked:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)accountButtonClicked:(id)sender {
}

- (IBAction)historyButtonClicked:(id)sender {
}

-(NSString*) ageFormatedAsNiceString: (NSInteger) days {
  return [NSString stringWithFormat:@"%ld days old",days];
//  if(days >= 365){
//    float years = round(days / 365) / 2.0f;
//    period = (years > 1) ? @"years" : @"year";
//    formatted = [NSString stringWithFormat:@"about %i %@ ago", years, period];
//  } else if(days < 365 && days >= 30) {
//    float months = round(days / 30) / 2.0f;
//    period = (months > 1) ? @"months" : @"month";
//    formatted = [NSString stringWithFormat:@"about %i %@ ago", months, period];
//  } else if(days < 30 && days >= 2) {
//    period = @"days";
//    formatted = [NSString stringWithFormat:@"about %i %@ ago", days, period];
//  } else if(days == 1){
//    period = @"day";
//    formatted = [NSString stringWithFormat:@"about %i %@ ago", days, period];
//  } else if(days < 1 && minutes > 60) {
//    period = (hours > 1) ? @"hours" : @"hour";
//    formatted = [NSString stringWithFormat:@"about %i %@ ago", hours, period];
//  } else {
//    period = (minutes < 60 && minutes > 1) ? @"minutes" : @"minute";
//    formatted = [NSString stringWithFormat:@"about %i %@ ago", minutes, period];
//    if(minutes < 1){
//      formatted = @"a moment ago";
//    }
//  }
//  return formatted;
}

//-(void) drawBabyAvatar {
//  UIImage *originalImage = [UIImage imageNamed:[NSString stringWithFormat:@"IMG_0691.jpg"]];
//  CGFloat oImageWidth = originalImage.size.width;
//  CGFloat oImageHeight = originalImage.size.height;
//  // Draw the original image at the origin
//  CGRect oRect = CGRectMake(0, 0, oImageWidth, oImageHeight);
//  [originalImage drawInRect:oRect];
//  
//  // Set the newRect to half the size of the original image
//  CGRect newRect = CGRectMake(0, 0, oImageWidth/2, oImageHeight/2);
//  UIImage *newImage = [self circularScaleNCrop:originalImage :newRect];
//  
//  CGFloat nImageWidth = newImage.size.width;
//  CGFloat nImageHeight = newImage.size.height;
//  
//  //Draw the scaled and cropped image
//  CGRect thisRect = CGRectMake(oImageWidth+10, 0, nImageWidth, nImageHeight);
//  [newImage drawInRect:thisRect];
//}
//
//- (UIImage*)circularScaleNCrop:(UIImage*)image withRect:(CGRect) rect{
//  // This function returns a newImage, based on image, that has been:
//  // - scaled to fit in (CGRect) rect
//  // - and cropped within a circle of radius: rectWidth/2
//  
//  //Create the bitmap graphics context
//  UIGraphicsBeginImageContextWithOptions(CGSizeMake(rect.size.width, rect.size.height), NO, 0.0);
//  CGContextRef context = UIGraphicsGetCurrentContext();
//  
//  //Get the width and heights
//  CGFloat imageWidth = image.size.width;
//  CGFloat imageHeight = image.size.height;
//  CGFloat rectWidth = rect.size.width;
//  CGFloat rectHeight = rect.size.height;
//  
//  //Calculate the scale factor
//  CGFloat scaleFactorX = rectWidth/imageWidth;
//  CGFloat scaleFactorY = rectHeight/imageHeight;
//  
//  //Calculate the centre of the circle
//  CGFloat imageCentreX = rectWidth/2;
//  CGFloat imageCentreY = rectHeight/2;
//  
//  // Create and CLIP to a CIRCULAR Path
//  // (This could be replaced with any closed path if you want a different shaped clip)
//  CGFloat radius = rectWidth/2;
//  CGContextBeginPath (context);
//  CGContextAddArc (context, imageCentreX, imageCentreY, radius, 0, 2*M_PI, 0);
//  CGContextClosePath (context);
//  CGContextClip (context);
//  
//  //Set the SCALE factor for the graphics context
//  //All future draw calls will be scaled by this factor
//  CGContextScaleCTM (context, scaleFactorX, scaleFactorY);
//  
//  // Draw the IMAGE
//  CGRect myRect = CGRectMake(0, 0, imageWidth, imageHeight);
//  [image drawInRect:myRect];
//  
//  UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
//  UIGraphicsEndImageContext();
//  
//  return newImage;
//}

@end
