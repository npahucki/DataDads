//
//  ParentUser.m
//  Milestones
//
//  Created by Nathan  Pahucki on 6/5/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

@implementation ParentUser

@dynamic fullName;
@dynamic isMale;
@dynamic usesMetric;
@dynamic launchCount;
@dynamic supportScience;

- (void)setEmail:(NSString *)email {
    [super setEmail:[email lowercaseString]];
}

- (void)setUsername:(NSString *)username {
    [super setUsername:[username lowercaseString]];
}

- (BOOL)showHiddenTips {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"showHiddenTips"];
}

- (void)setShowHiddenTips:(BOOL)showHiddenTips {
    [[NSUserDefaults standardUserDefaults] setBool:showHiddenTips forKey:@"showHiddenTips"];
}

- (BOOL)showIgnoredMilestones {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"showIgnoredMilestones"];
}

- (void)setShowIgnoredMilestones:(BOOL)showIgnoredMilestones {
    [[NSUserDefaults standardUserDefaults] setBool:showIgnoredMilestones forKey:@"showIgnoredMilestones"];
}

- (BOOL)showPostponedMilestones {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"showPostponedMilestones"];
}

- (void)setShowPostponedMilestones:(BOOL)showPostponedMilestones {
    [[NSUserDefaults standardUserDefaults] setBool:showPostponedMilestones forKey:@"showPostponedMilestones"];
}

- (BOOL)showMilestoneStats {
    NSNumber *show = [self objectForKey:@"showMilestoneStats"];
    return show == nil || show.boolValue; // default to yes
}

- (void)setShowMilestoneStats:(BOOL)showMilestoneStats {
    [self setObject:@(showMilestoneStats) forKey:@"showMilestoneStats"];
}

- (void)setAutoPublishToFacebook:(BOOL)autoPublishToFacebook {
    [[NSUserDefaults standardUserDefaults] setBool:autoPublishToFacebook forKey:@"autoPublishToFacebook"];
}

- (BOOL)autoPublishToFacebook {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"autoPublishToFacebook"];
}


- (void)setSuppressAutoShowNoteMilestoneShareScreen:(BOOL)autoPublishToFacebook {
    [[NSUserDefaults standardUserDefaults] setBool:autoPublishToFacebook forKey:@"suppressAutoShowNoteMilestoneShareScreen"];
}

- (BOOL)suppressAutoShowNoteMilestoneShareScreen {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"suppressAutoShowNoteMilestoneShareScreen"];
}




- (BOOL)shownTutorialPrompt {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"shownTutorialPrompt"];
}

- (void)setShownTutorialPrompt:(BOOL)shownTutorialPrompt {
    [[NSUserDefaults standardUserDefaults] setBool:shownTutorialPrompt forKey:@"shownTutorialPrompt"];
}

- (BOOL)suppressLoginPrompt {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"suppressLoginPrompt"];
}

- (void)setSuppressLoginPrompt:(BOOL)suppressLoginPrompt {
    [[NSUserDefaults standardUserDefaults] setBool:suppressLoginPrompt forKey:@"suppressLoginPrompt"];
}

- (BOOL)hasEmail {
    return self.email.length > 0;
}

- (BOOL)isLinkedWithFacebook {
    return [PFFacebookUtils isLinkedWithUser:self];
}

- (BOOL)isLoggedIn {
    return ![PFAnonymousUtils isLinkedWithUser:self] && self.isAuthenticated;
}

+ (void)incrementLaunchCount {
    [self.currentUser incrementKey:@"launchCount"];
    [self.currentUser saveEventually:^(BOOL succeeded, NSError *error) {
        if (succeeded) [ParentUser.currentUser fetchInBackgroundWithBlock:nil];
    }];
}


+ (NSString *)nameFromCurrentDevice {
    return [self nameFromDeviceName:[UIDevice currentDevice].name];
}

+ (NSString *)nameFromDeviceName:(NSString *)deviceName {
    NSError *error;
    static NSString *expression = (@"^(?:iPhone|phone|iPad|iPod)\\s+(?:de\\s+)?|"
            "(\\S+?)(?:['’]?s)?(?:\\s+(?:iPhone|phone|iPad|iPod))?$|"
            "(\\S+?)(?:['’]?的)?(?:\\s*(?:iPhone|phone|iPad|iPod))?$|"
            "(\\S+)\\s+");
    static NSRange RangeNotFound = (NSRange) {.location=NSNotFound, .length=0};
    NSMutableArray *names = [[NSMutableArray alloc] init];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:expression
                                                                           options:(NSRegularExpressionCaseInsensitive)
                                                                             error:&error];
    for (NSTextCheckingResult *result in [regex matchesInString:deviceName
                                                        options:0
                                                          range:NSMakeRange(0, deviceName.length)]) {
        for (NSUInteger i = 1; i < result.numberOfRanges; i++) {
            if (!NSEqualRanges([result rangeAtIndex:i], RangeNotFound)) {
                NSString *namePart = [deviceName substringWithRange:[result rangeAtIndex:i]];
                if ([namePart isEqualToString:@"iPhone"] ||
                        [namePart isEqualToString:@"iPad"] ||
                        [namePart isEqualToString:@"iPod"] ||
                        [namePart isEqualToString:@"phone"]) {
                    return nil; // Failed to parse out name
                }
                [names addObject:namePart.capitalizedString];
            }
        }
    }
    return names.count ? [names componentsJoinedByString:@" "] : nil;
}

@end
