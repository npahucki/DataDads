//
//  IntroScreenViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/15/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "IntroScreenContentViewController.h"

@implementation IntroScreenContentViewController


-(void) viewDidLoad {
  [super viewDidLoad];
  self.titleLabel.font = [UIFont fontForAppWithType:Bold andSize:28.0]; // Very strange, if we don't call this, the NSFontAttrbuteName is not applied!
  NSMutableParagraphStyle *paragrahStyle = [[NSMutableParagraphStyle alloc] init];
  [paragrahStyle setLineSpacing:10];
  [paragrahStyle setAlignment:NSTextAlignmentCenter];
  self.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:self.text attributes:@{
                                                                                                     NSFontAttributeName: [UIFont fontForAppWithType:Book andSize:23.0],
                                                                                                     NSParagraphStyleAttributeName : paragrahStyle,
                                                                                                     NSForegroundColorAttributeName: [UIColor appSelectedColor]
                                                                                                     }];
  [self.titleLabel sizeToFit];
}




@end
