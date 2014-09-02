//
//  ParentUser.h
//  Milestones
//
//  Created by Nathan  Pahucki on 6/5/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <Parse/Parse.h>

@interface ParentUser : PFUser <PFSubclassing>

@property NSString *screenName;
@property BOOL isMale;
@property BOOL autoPublishToFacebook;
@property BOOL usesMetric;
@property BOOL showHiddenTips;
@property BOOL showIgnoredMilestones;
@property BOOL showPostponedMilestones;
@property BOOL showMilestoneStats;
@property NSInteger launchCount;
@property BOOL shownTutorialPrompt;
@property BOOL suppressLoginPrompt;


+ (void)incrementLaunchCount;


@end

