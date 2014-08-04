//
//  TutorialBubbleView.h
//  DataParenting
//
//  Created by Nathan  Pahucki on 8/4/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TutorialBubbleView : UIView
@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *arrowHConstraint;
@property CGPoint arrowTip;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImage;

-(void) showInView:(UIView *) view withText:(NSString*) text;



@end
