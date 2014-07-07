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

static BOOL isProduciton;

@implementation UsageAnalytics

+(void) initializeConnection {

# if DEBUG || TARGET_IPHONE_SIMULATOR
  isProduciton = false;
#else
  isProduciton = true;
  [Appsee start:@"0d66ed485f214fdd977275d9de1de7b9"];
  [Heap setAppId:@"714546901"];
  [Heap changeInterval:30];
#endif

}

+(void) idenfity:(ParentUser*) user withBaby:(Baby*) baby {
  if(user) {
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

    if(isProduciton) {
      [Appsee setUserID:user.objectId];
      [Heap identify:props];
    } else {
      NSLog(@"[USAGE ANALYTICS]: Identify - %@", props);
    }
  }
}

+(void) trackError:(NSError*)error forOperationNamed:(NSString*) operation {
  [self trackError:error forOperationNamed:operation andAdditionalProperties:nil];
}

+(void) trackError:(NSError*)error forOperationNamed:(NSString*) operation andAdditionalProperties:(NSDictionary*) props {
  if(isProduciton) {
    NSMutableDictionary *combinedAttributes = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
    if(props) [combinedAttributes addEntriesFromDictionary:props];
    [combinedAttributes setObject:@(error.code) forKey:@"error.id"];
    [combinedAttributes setObject:safe(error.domain) forKey:@"error.domain"];
    [Heap track:[NSString stringWithFormat:@"Error:%@",operation] withProperties:combinedAttributes];
  } else {
    NSLog(@"[USAGE ANALYTICS]: trackError - Operation:%@ Error:%@ Properties:%@", operation,error, props);
  }
}



+(void) trackUserSignup:(ParentUser*) user usingMethod:(NSString*) method {
  if(isProduciton) {
    [Heap track:@"userSignedUp" withProperties:@{
                                               @"user.id" : safe(user.objectId),
                                               @"method" : safe(method)
                                               }];
  } else {
    NSLog(@"[USAGE ANALYTICS]: trackUserSignup - User:%@ Method:%@", user,method);
  }
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
      if(isProduciton) {
        [Heap track:@"userLinkedWithFacebook" withProperties:props];
      } else {
        NSLog(@"[USAGE ANALYTICS]: trackUserLinkedWithFacebook - User:%@ Publish:%d", user,publish);
      }
    }
}

+(void) trackUserSignout:(ParentUser*) user {
  if(isProduciton) {
    [Heap track:@"userSignedOut" withProperties:@{ @"user.id" : safe(user.objectId) }];
  } else {
    NSLog(@"[USAGE ANALYTICS]: trackUserSignout - User:%@", user);
  }
}

+(void) trackAchievementLogged:(MilestoneAchievement *) achievement sharedOnFacebook:(BOOL) shared {
  if(isProduciton) {
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
  } else {
    NSLog(@"[USAGE ANALYTICS]: trackAchievementLogged - Achievement:%@", achievement);
  }
}


+(void) trackMeasurement:(Measurement *) measurement {
  if(isProduciton) {
    [Heap track:@"measurementLogged" withProperties:@{
                                                     @"user.id" : safe(measurement.baby.parentUser.objectId),
                                                     @"baby.id" : safe(measurement.baby.objectId),
                                                     @"measurement.type" : safe(measurement.type)
                                                     }];
  } else {
    NSLog(@"[USAGE ANALYTICS]: trackMeasurement - Measurement:%@", measurement);
  }
}

+(void) trackSearch:(NSString *) filterString {
  if(isProduciton) {
    [Heap track:@"searchExecuted" withProperties:@{ @"filterString" : filterString }];
  } else {
    NSLog(@"[USAGE ANALYTICS]: trackSearch - Filter:%@", filterString);
  }
}



@end
