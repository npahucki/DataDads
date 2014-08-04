//
//  TutorialBubbleView.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 8/4/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "TutorialBubbleView.h"

@implementation TutorialBubbleView {
    CGPoint _arrowTip;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.textLabel.font = [UIFont fontForAppWithType:Medium andSize:17];
    self.translatesAutoresizingMaskIntoConstraints = NO;

}

- (void)showInView:(UIView *)view withText:(NSString *)text {
    self.alpha = 0;
    [view addSubview:self];
    [self.closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.textLabel.text = text;

    CGFloat inset = 20;
    CGFloat textWidth = view.bounds.size.width - inset * 2 - self.closeButton.bounds.size.width;
    CGRect r = [text boundingRectWithSize:CGSizeMake(textWidth, 0)
                                  options:NSStringDrawingUsesLineFragmentOrigin
                               attributes:@{NSFontAttributeName : self.textLabel.font}
                                  context:nil];
    self.frame = CGRectMake(inset, _arrowTip.y, view.frame.size.width - inset * 2, r.size.height + self.arrowImage.frame.size.height + 30);
    CGFloat arrowOffset = _arrowTip.x - (inset + self.arrowImage.frame.size.width / 2);
    self.arrowHConstraint.constant = arrowOffset < 0 ? 0 : arrowOffset;
    [self setNeedsLayout];
    [self layoutIfNeeded];
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 1.0;
    }                completion:nil];
}

- (IBAction)didClickCloseButton:(id)sender {
    [UIView animateWithDuration:0.2
                     animations:^{
        self.alpha = 0.0;
    }
                     completion:^(BOOL finished){
        [self removeFromSuperview];
    }];
}

- (void)setArrowTip:(CGPoint)arrowTip {
    _arrowTip = arrowTip;
}

- (CGPoint)arrowTip {
    return _arrowTip;
}

@end
