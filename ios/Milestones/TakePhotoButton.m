//
//  TakePhotoButton.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 7/2/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "TakePhotoButton.h"

@implementation TakePhotoButton {
  BOOL _startedAnimation;
  CALayer * _innerShadowLayer;
}

-(void) awakeFromNib {
  [self setBackgroundImage:[UIImage imageNamed:@"camIconWithBorder"] forState:UIControlStateNormal];
  self.layer.masksToBounds = YES;
  self.layer.borderWidth = 1;
  self.layer.borderColor = UIColorFromRGB(0xcedfe2).CGColor;
  self.backgroundColor = UIColorFromRGB(0xF3F9FA);
  self.imageView.contentMode = UIViewContentModeScaleAspectFill;
  self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
  self.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
  self.reversesTitleShadowWhenHighlighted = NO;
  
}

-(void) layoutSubviews {
  [super layoutSubviews];
  [self.layer setCornerRadius:MIN(self.frame.size.width,self.frame.size.height)/2];
  
  if(!_startedAnimation) {
    
    [UIButton animateWithDuration:1.0 delay:0.0 options:
     UIViewAnimationOptionAllowUserInteraction |UIViewAnimationOptionBeginFromCurrentState |UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat
                       animations:^{
                         self.alpha = .75;
                       } completion:nil];
    _startedAnimation = YES;
  }
  
  if(!_innerShadowLayer) {
    _innerShadowLayer = [CALayer layer];
    _innerShadowLayer.hidden = YES; // only show when an image is set.
    _innerShadowLayer.contents = (id)[UIImage imageNamed: @"avatarShadow"].CGImage;
    _innerShadowLayer.contentsCenter = CGRectMake(10.0f/21.0f, 10.0f/21.0f, 1.0f/21.0f, 1.0f/21.0f);
    [self.layer addSublayer:_innerShadowLayer];
  }
  _innerShadowLayer.frame = CGRectInset(self.bounds, -.5, -.5);
}

-(void) setImage:(UIImage *)image forState:(UIControlState)state {
  [self.layer removeAllAnimations];
  self.imageView.contentMode = UIViewContentModeScaleAspectFill;
  [super setImage:image forState:UIControlStateNormal];
  self.alpha = 1.0;
  _innerShadowLayer.hidden = NO;
  self.layer.borderColor = [UIColor appInputBorderNormalColor].CGColor;
}

@end
