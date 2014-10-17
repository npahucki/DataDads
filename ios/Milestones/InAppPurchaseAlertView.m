//
//  InAppPurchaseAlertView.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 10/16/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "InAppPurchaseAlertView.h"
#import "WebViewerViewController.h"

const static CGFloat kCustomIOS7MotionEffectExtent = 10.0;

@implementation InAppPurchaseAlertView {
    UIView *_dialogView;
    SKProduct *_product;
    InAppPurchaseChoiceBlock _resultBlock;
}

- (id)init {
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    }
    return self;
}

- (IBAction)didClickReadTermsAndConditions:(id)sender {
    WebViewerViewController *vc = [WebViewerViewController webViewForUrlString:kDDURLTermsAndConditions];
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [window.rootViewController presentViewController:vc animated:YES completion:^{
        if (_resultBlock) _resultBlock(InAppPurchaseChoiceCancel);
    }];
}

- (IBAction)didClickPurchaseNow:(id)sender {
    if (_resultBlock) _resultBlock(InAppPurchaseChoicePurchase);
    [self showProgress:YES];
}

- (IBAction)didClickRestorePurchases:(id)sender {
    if (_resultBlock) _resultBlock(InAppPurchaseChoiceRestore);
    [self showProgress:YES];
}

- (IBAction)didClickCancel:(id)sender {
    if (_resultBlock) _resultBlock(InAppPurchaseChoiceCancel);
    [self showProgress:YES];
}

- (void)showProgress:(BOOL)isInProgress {
    self.purchaseNowButton.enabled =
            self.termsAndConditionsButton.enabled =
                    self.restorePurchaseButton.enabled =
                            self.cancelButton.enabled =
                                    self.progressImageView.hidden = !isInProgress;
    self.progressImageView.image = [UIImage animatedImageNamed:@"progress-" duration:1.0];
}


- (SKProduct *)product {
    return _product;
}

- (void)setProduct:(SKProduct *)product {
    _product = product;
    self.descriptionTextView.attributedText = [self createDescriptionText];
    [self showProgress:NO];
    // Make the bottom of the Text field fade out
    CAGradientLayer *l = [CAGradientLayer layer];
    l.frame = self.fadeView.bounds;
    l.colors = @[(id) [UIColor whiteColor].CGColor, (id) [UIColor clearColor].CGColor];
    l.startPoint = CGPointMake(0.0f, 0.9f);
    l.endPoint = CGPointMake(0.0f, 1.0f);
    self.fadeView.layer.mask = l;

}

- (void)showWithBlock:(InAppPurchaseChoiceBlock)choiceBlock {
    _resultBlock = choiceBlock;

    _dialogView = [[NSBundle mainBundle] loadNibNamed:@"InAppPurchaseView" owner:self options:nil][0];
    [self.purchaseNowButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self showProgress:YES]; // show progress until the product is set

    _dialogView.layer.shouldRasterize = YES;
    _dialogView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    _dialogView.layer.cornerRadius = 7;
    _dialogView.frame = CGRectInset(self.bounds, 20.0, 60.0);

    // For the black background
    self.frame = [UIScreen mainScreen].bounds;

    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = [[UIScreen mainScreen] scale];

    [self applyMotionEffects];

    _dialogView.layer.opacity = 0.5f;
    _dialogView.layer.transform = CATransform3DMakeScale(1.3f, 1.3f, 1.0);

    self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];

    [self addSubview:_dialogView];



    // Attached to the top most window (make sure we are using the right orientation):
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    switch (interfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
            self.transform = CGAffineTransformMakeRotation(M_PI * 270.0 / 180.0);
            break;

        case UIInterfaceOrientationLandscapeRight:
            self.transform = CGAffineTransformMakeRotation(M_PI * 90.0 / 180.0);
            break;

        case UIInterfaceOrientationPortraitUpsideDown:
            self.transform = CGAffineTransformMakeRotation(M_PI * 180.0 / 180.0);
            break;

        default:
            break;
    }

    [[[[UIApplication sharedApplication] windows] firstObject] addSubview:self];
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4f];
                         _dialogView.layer.opacity = 1.0f;
                         _dialogView.layer.transform = CATransform3DMakeScale(1, 1, 1);
                     }
                     completion:NULL
    ];
}



- (NSAttributedString *)createDescriptionText {
    NSAssert(self.product, @"Expected product would be set before show!");
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:self.product.priceLocale];
    NSString *formattedPrice = [numberFormatter stringFromNumber:self.product.price];
    NSString *title = [NSString stringWithFormat:@"Purchase %@ now for %@?", self.product.localizedTitle, formattedPrice];

    NSMutableAttributedString *descriptionAttrString = [[NSMutableAttributedString alloc] init];
    NSAttributedString *lf = [[NSAttributedString alloc] initWithString:@"\n"];

    NSMutableParagraphStyle *centerParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    centerParagraphStyle.alignment = NSTextAlignmentCenter;

    NSAttributedString *titleString = [[NSAttributedString alloc] initWithString:title attributes:@{
            NSFontAttributeName : [UIFont fontForAppWithType:Bold andSize:17.0],
            NSParagraphStyleAttributeName : centerParagraphStyle,
            NSForegroundColorAttributeName : [UIColor blackColor]
    }];
    [descriptionAttrString appendAttributedString:titleString];
    [descriptionAttrString appendAttributedString:lf];
    [descriptionAttrString appendAttributedString:lf];

    NSAttributedString *productDescriptionString = [[NSAttributedString alloc] initWithString:self.product.localizedDescription attributes:@{
            NSFontAttributeName : [UIFont fontForAppWithType:Book andSize:14.0],
            NSForegroundColorAttributeName : [UIColor blackColor]
    }];
    [descriptionAttrString appendAttributedString:productDescriptionString];

    return descriptionAttrString;
}


- (void)close {
    CATransform3D currentTransform = _dialogView.layer.transform;

    CGFloat startRotation = [[_dialogView valueForKeyPath:@"layer.transform.rotation.z"] floatValue];
    CATransform3D rotation = CATransform3DMakeRotation(-startRotation + M_PI * 270.0 / 180.0, 0.0f, 0.0f, 0.0f);

    _dialogView.layer.transform = CATransform3DConcat(rotation, CATransform3DMakeScale(1, 1, 1));
    _dialogView.layer.opacity = 1.0f;

    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         self.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.0f];
                         _dialogView.layer.transform = CATransform3DConcat(currentTransform, CATransform3DMakeScale(0.6f, 0.6f, 1.0));
                         _dialogView.layer.opacity = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         [self removeFromSuperview];
                     }
    ];
}

- (void)applyMotionEffects {

    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        return;
    }

    UIInterpolatingMotionEffect *horizontalEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                                                                    type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalEffect.minimumRelativeValue = @(-kCustomIOS7MotionEffectExtent);
    horizontalEffect.maximumRelativeValue = @( kCustomIOS7MotionEffectExtent);

    UIInterpolatingMotionEffect *verticalEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                                                                  type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalEffect.minimumRelativeValue = @(-kCustomIOS7MotionEffectExtent);
    verticalEffect.maximumRelativeValue = @( kCustomIOS7MotionEffectExtent);

    UIMotionEffectGroup *motionEffectGroup = [[UIMotionEffectGroup alloc] init];
    motionEffectGroup.motionEffects = @[horizontalEffect, verticalEffect];

    [_dialogView addMotionEffect:motionEffectGroup];
}


@end
