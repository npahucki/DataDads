//
//  StandardMilestoneAchievement.h
//  Milestones
//
//  Created by Nathan  Pahucki on 1/31/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Baby.h"
#import "StandardMilestone.h"

// Designed to be ORed together.
typedef NS_ENUM(NSInteger, SharingMedium) {
    SharingMediumNotShared = 0,
    SharingMediumFacebook = 1,
    SharingMediumTwitter = 2,
    SharingMediumEmail = 4,
    SharingMediumTextMessage = 8,
    SharingMediumFollow = 16,
    SharingMediumOther = 128

};

@interface SharingOptions : NSObject
@property BOOL sendToFollowers;
@property NSArray *excludedFollowerEmails;
@property NSArray *additionalFollowerEmails;

- (NSDictionary *)asDictionary;
@end

@interface MilestoneAchievement : PFObject <PFSubclassing>

@property Baby *baby;
@property StandardMilestone *standardMilestone; // optional, could be custom in which case customTitle and customDescription should be set
@property NSDate *completionDate;
@property PFFile *attachment;
@property PFFile *attachmentThumbnail;
@property NSString *attachmentExternalStorageId;
@property UIImageOrientation attachmentOrientation;
@property CGFloat attachmentHeight;
@property CGFloat attachmentWidth;
@property NSString *attachmentType;
@property NSString *customTitle;      // optional, should be set if milestone is nil
@property NSString *comment;
@property BOOL isSkipped;
@property BOOL isPostponed;
@property SharingMedium sharedVia;
@property NSDictionary *sharingOptions;

// Derives a title from the customTitle or Milestone title.
@property(readonly) NSString *displayTitle;

/*!
 * Calls the provided block back with a a float for the percentile. A negative value means there
 * was an error OR there was not enough data to calculate the percentile.
 */
- (void)calculatePercentileRankingWithBlock:(void (^)(float percentile))block;


@end
