//
//  UsageAnalytics.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 6/21/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "UsageAnalytics.h"
#import "Heap.h"
#import "Appsee/Appsee.h"

static id safe(id object) {
  return object ?: [NSNull null];
}

@implementation UsageAnalytics

+(void) initializeConnection {

# if DEBUG || TARGET_IPHONE_SIMULATOR
#else
  [Appsee start:@"0d66ed485f214fdd977275d9de1de7b9"];
  [Heap setAppId:@"714546901"];
  [Heap changeInterval:30];
#endif

}

+(void) idenfity:(ParentUser*) user withBaby:(Baby*) baby {
  if(user) {
    [Appsee setUserID:user.objectId];
    NSDictionary * props = @{
                               @"handle" : safe(user.objectId),
                               @"email" : safe(user.email),
                               @"user.id" : safe(user.objectId),
                               @"user.anonymous" : user.email ? @"N" : @"Y",
                               @"user.screenName" : safe(user.screenName),
                               @"user.linkedToFacebook" : [PFFacebookUtils isLinkedWithUser:user] ? @"Y" : @"N",
                               @"user.emailVerified" : [user objectForKey:@"emailVerified"] ? @"Y" : @"N" ,
                               @"user.sex" : user.isMale ? @"M" : @"F",
                               };
    if(baby) {
      NSMutableDictionary *combinedAttributes = [NSMutableDictionary dictionaryWithDictionary:props];
      [combinedAttributes setObject:safe(baby.objectId) forKey:@"baby.id"];
      [combinedAttributes setObject:baby.isMale ? @"M" : @"F" forKey:@"baby.sex"];
      props = combinedAttributes;
    }
    [Heap identify:props];
  }
}

+(void) trackError:(NSError*)error forOperationNamed:(NSString*) operation {
  [self trackError:error forOperationNamed:operation andAdditionalProperties:nil];
}

+(void) trackError:(NSError*)error forOperationNamed:(NSString*) operation andAdditionalProperties:(NSDictionary*) props {
  NSMutableDictionary *combinedAttributes = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
  if(props) [combinedAttributes addEntriesFromDictionary:props];
  [combinedAttributes setObject:@(error.code) forKey:@"error.id"];
  [combinedAttributes setObject:safe(error.domain) forKey:@"error.domain"];
  [Heap track:[NSString stringWithFormat:@"Error:%@",operation] withProperties:combinedAttributes];
}



+(void) trackUserSignup:(ParentUser*) user usingMethod:(NSString*) method {
  [Heap track:@"userSignedUp" withProperties:@{
                                             @"user.id" : safe(user.objectId),
                                             @"method" : safe(method)
                                             }];
}

+(void) trackUserSignupError:(NSError *)error usingMethod:(NSString *)method {
  [self trackError:error forOperationNamed:@"userSignup"];
}

+(void) trackUserLinkedWithFacebook:(ParentUser*) user forPublish:(BOOL)publish withError:(NSError *)error {
  NSDictionary * props = @{ @"user.id" : safe(user.objectId),
                            @"forPublish" : publish ? @"Y" : @"N",
                          };
  
  if(error) {
    [self trackError:error forOperationNamed:@"userLinkedWithFacebook" andAdditionalProperties:props];
  } else {
    [Heap track:@"userLinkedWithFacebook" withProperties:props];
  }
}

+(void) trackUserSignout:(ParentUser*) user {
  [Heap track:@"userSignedOut" withProperties:@{ @"user.id" : safe(user.objectId) }];
}

+(void) trackAchievementLogged:(MilestoneAchievement *) achievement sharedOnFacebook:(BOOL) shared {

  if(achievement.isPostponed) {
    [Heap track:@"milestonePostponed" withProperties:@{
                                                     @"user.id" : safe(achievement.baby.parentUser.objectId),
                                                     @"baby.id" : safe(achievement.baby.objectId),
                                                     @"milestoneId" : safe(achievement.standardMilestone.objectId)
                                                     }];
  } else if(achievement.isSkipped) {
    [Heap track:@"milestoneSkipped" withProperties:@{
                                                      @"user.id" : safe(achievement.baby.parentUser.objectId),
                                                      @"baby.id" : safe(achievement.baby.objectId),
                                                      @"milestoneId" : safe(achievement.standardMilestone.objectId)
                                                      }];
  } else {
    [Heap track:@"achievementLogged" withProperties:@{
                                                      @"user.id" : safe(achievement.baby.parentUser.objectId),
                                                      @"baby.id" : safe(achievement.baby.objectId),
                                                      @"achievement.isStandard" : achievement.standardMilestone ? @"Y" : @"N",
                                                      @"achievement.standardMilestoneId" : safe(achievement.standardMilestone.objectId),
                                                      @"achievement.attachmentType" : safe(achievement.attachmentType),
                                                      @"achievement.hasAttachment" : achievement.attachmentType ? @"Y" : @"N",
                                                      @"achievement.hasCustomTitle" : achievement.customTitle ? @"Y" : @"N",
                                                      @"achievement.hasComment" : achievement.comment ? @"Y" : @"N",
                                                      @"sharedOnFacebook" : shared ? @"Y" : @"N"
                                                      }];
  }
}


+(void) trackMeasurement:(Measurement *) measurement {
  [Heap track:@"measurementLogged" withProperties:@{
                                                   @"user.id" : safe(measurement.baby.parentUser.objectId),
                                                   @"baby.id" : safe(measurement.baby.objectId),
                                                   @"measurement.type" : safe(measurement.type)
                                                   }];
  
}


@end
