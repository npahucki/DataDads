//
//  InAppPurchaseView.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 10/16/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "InAppPurchaseView.h"

@implementation InAppPurchaseView

- (void)awakeFromNib {
    [super awakeFromNib];
    for (UIView *subview in self.subviews) {
        if ([subview.restorationIdentifier isEqualToString:@"purchaseNow"]) {
            [((UIButton *) subview) setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        }
    }
}


@end
