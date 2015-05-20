//
// Created by Nathan  Pahucki on 4/29/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Bolts/Bolts.h>

typedef enum _DDApplicationFeatureType : NSUInteger {
    DDApplicationFeatureNone = 0,
    DDApplicationFeatureAdRemoval,
    DDApplicationFeatureVideoSupport
} DDApplicationFeatureType;


@protocol DDApplicationFeature
- (BFTask *)checkForUnlockStatus;
@end

@interface FeatureManager : NSObject

+ (BFTask *)ensureFeatureUnlocked:(DDApplicationFeatureType)featureType;

+ (void)ensureFeatureUnlocked:(DDApplicationFeatureType)featureType withBlock:(PFBooleanResultBlock)block;


@end

