//
//  PFQueryWithExtendedResultSet.h
//  Milestones
//
//  Created by Nathan  Pahucki on 4/7/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <Parse/Parse.h>


/**
 This is a bit of a hack, so that the PFQueryTableViewController can have items removed or added before a query is done to the backend 
 to improve the visual experience. 
 **/
@interface PFQueryWithExtendedResultSet : PFQuery

// Those items, that if they appear in the original query result will be excluded.
@property NSSet * excludeSet;

// Those items to be added to the front of the query result.
@property NSArray * headIncludeArray;

// Those items to be added to the end of the query result.
@property NSArray * tailIncludeArray;

@end

