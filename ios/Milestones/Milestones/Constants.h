//
//  Contants.h
//  Milestones
//
//  Created by Nathan  Pahucki on 1/27/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#ifndef Milestones_Contants_h
#define Milestones_Contants_h


// User object constants
extern NSString *const kDDUserScreenName;
extern NSString *const kDDUserEmail;


// Segue names for manually activated segues
extern NSString *const kDDSegueEnterScreenName;
extern NSString *const kDDSegueNoteMilestone;

// Notifications
extern NSString *const kDDNotificationCurrentBabyChanged;   // User data is NSDictionary with Baby object keyed by @""
extern NSString *const kDDNotificationMilestoneNoted;       // User data is NSDictionary with StandardMilestone object keyed by @""
#endif
