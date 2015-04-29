//
// Created by Nathan  Pahucki on 4/29/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Bolts/Bolts.h>

@protocol DDApplicationFeature
- (BFTask *)checkForUnlockStatus;
@end


@interface FeatureManager : NSObject


+ (void)ensureFeatureUnlocked:(id <DDApplicationFeature>)feature withBlock:(PFBooleanResultBlock)block;


@end