//
//  PFQueryWithExtendedResultSet.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/7/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "PFQueryWithExtendedResultSet.h"

@implementation PFQueryWithExtendedResultSet



- (void)findObjectsInBackgroundWithBlock:(PFArrayResultBlock)queryBlock {
  [super findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error){
    if(!error) {
      // TODO: do exclude.
//      for(PFObject* obj in results) {
//        if([self.excludeSet containsObject:obj]) {
//          
//        }
//      }
      
      results = self.headIncludeArray ? results = [self.headIncludeArray arrayByAddingObjectsFromArray:results] : results;
      if(self.tailIncludeArray) results = [results arrayByAddingObjectsFromArray:self.tailIncludeArray];
    }
    queryBlock(results, error);
  }];
}


@end
