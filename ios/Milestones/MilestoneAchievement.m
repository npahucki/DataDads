//
//  StandardMilestoneAchievement.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/31/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "PronounHelper.h"

@implementation SharingOptions
- (NSDictionary *)asDictionary {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"sendToFollowers"] = @(self.sendToFollowers);
    if (self.excludedFollowerEmails) dict[@"excludedFollowerEmails"] = self.excludedFollowerEmails;
    if (self.additionalFollowerEmails) dict[@"additionalFollowerEmails"] = self.additionalFollowerEmails;
    return dict;
}


@end

@implementation MilestoneAchievement

// Since we can't use an inner query based on an object reference (See https://parse.com/questions/trouble-with-nested-query-using-objectid)
// we must include a redundant column which is a string and has the milestoneId included. As such, to make sure this is always set correctly
// we must implement the milestone getter/setter ourselves.
//@dynamic standardMilestone;
@dynamic baby;
@dynamic completionDate;
@dynamic attachment;
@dynamic attachmentType;
@dynamic attachmentThumbnail;
@dynamic attachmentOrientation;
@dynamic attachmentExternalStorageId;
@dynamic attachmentWidth;
@dynamic attachmentHeight;
@dynamic customTitle;
@dynamic comment;
@dynamic isSkipped;
@dynamic isPostponed;
@dynamic sharedVia;

+ (NSString *)parseClassName {
    return @"MilestoneAchievements";
}

- (void)setStandardMilestone:(StandardMilestone *)standardMilestone {
    [self setObject:standardMilestone forKey:@"standardMilestone"];
    [self setObject:standardMilestone.objectId forKey:@"standardMilestoneId"];
}

- (StandardMilestone *)standardMilestone {
    return [self objectForKey:@"standardMilestone"];
}

- (void)setCompletionDate:(NSDate *)completionDate {
    [self setObject:completionDate forKey:@"completionDate"];
    NSInteger days = [self.baby daysSinceDueDate:completionDate];
    [self setObject:@(days) forKey:@"completionDays"]; // Always set, even if negative.
}

- (NSDate *)completionDate {
    return [self objectForKey:@"completionDate"];
}

- (NSString *)displayTitle {
    NSAssert([self.baby.objectId isEqualToString:Baby.currentBaby.objectId], @"Expected achievement baby to be same as current baby");
    if (self.customTitle.length) {
        return [PronounHelper replacePronounTokens:self.customTitle forBaby:Baby.currentBaby];
    } else if (self.standardMilestone) {
        return [self.standardMilestone titleForBaby:Baby.currentBaby];
    } else {
        return @"???";
    }
}

- (void)calculatePercentileRankingWithBlock:(void (^)(float percentile))block {
    NSAssert([self.baby.objectId isEqualToString:Baby.currentBaby.objectId], @"Expected achievement baby to be same as current baby");
    if (self.standardMilestone.canCompare) {
        [PFCloud callFunctionInBackground:@"percentileRanking"
                           withParameters:@{@"milestoneId" : self.standardMilestone.objectId,
                                   @"completionDays" : @([Baby.currentBaby daysSinceDueDate:self.completionDate]),
                                   @"appVersion" : NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"]
                           }
                                    block:^(NSNumber *result, NSError *error) {
                                        if (error) {
                                            NSLog(@"Error trying to calulate percentile: %@", error);
                                            block(-1);
                                        } else {
                                            block([result floatValue]);
                                        }
                                    }];
    } else {
        block(-1);
    }
}

@end
