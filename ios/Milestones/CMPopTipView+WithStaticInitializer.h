//
// Created by Nathan  Pahucki on 1/22/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CMPopTipView.h"

@interface CMPopTipView (WithStaticInitializer)

+ (CMPopTipView *)instanceWithApplicationLookAndFeelAndMessage:(NSString *)msg;

@end