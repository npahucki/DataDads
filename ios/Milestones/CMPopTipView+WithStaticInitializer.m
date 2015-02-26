//
// Created by Nathan  Pahucki on 1/22/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "CMPopTipView+WithStaticInitializer.h"


@implementation CMPopTipView (WithStaticInitializer)

+ (CMPopTipView *)instanceWithApplicationLookAndFeelAndMessage:(NSString *)msg {
    CMPopTipView *tipView = [[CMPopTipView alloc] initWithMessage:msg];
    tipView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.80];
    tipView.textColor = [UIColor whiteColor];
    tipView.textFont = [UIFont fontForAppWithType:Medium andSize:16.0];
    tipView.has3DStyle = NO;
    tipView.hasShadow = YES;
    tipView.hasGradientBackground = YES;
    tipView.sidePadding = 8;
    tipView.cornerRadius = 2;
    return tipView;
}


@end