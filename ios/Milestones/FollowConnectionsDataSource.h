//
// Created by Nathan  Pahucki on 1/15/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _FollowConnectionDataSourceSectionType : NSUInteger {
    FollowConnectionDataSourceSection_WaitingToAccept = 0,
    FollowConnectionDataSourceSection_Connected = 1,
    FollowConnectionDataSourceSection_Pending = 2,

} FollowConnectionDataSourceSection;

@interface FollowConnectionsDataSource : NSObject

// Causes two NSNotifiationCenter events:
// kDDNotificationFollowConnectionsDataSourceWillLoadObjects before the loading starts
// kDDNotificationFollowConnectionsDataSourceDidLoadObjects when the loading is finished, error or not.
// kDDNotificationFollowConnectionsDataSourceDidChange when the loading is finished and there is no error
- (void)loadObjects;


// Causes kDDNotificationFollowConnectionsDataSourceDidChange if an item was removed
- (void)removeConnectionAtIndex:(NSInteger)index inSection:(FollowConnectionDataSourceSection)section;

- (NSArray *)connectionsInSection:(FollowConnectionDataSourceSection)section;


@property(readonly) BOOL isLoading;
@property(readonly) BOOL hadError;
@property(readonly) BOOL hasAnyConnections;
@property(readonly) NSInteger countOfTotalConnections;


@end