//
// Created by Nathan  Pahucki on 1/15/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "FollowConnectionsDataSource.h"
#import "PFCloud+Cache.h"

#define MAX_LOAD_COUNT 50


@implementation FollowConnectionsDataSource {
    NSMutableArray *_allConnections;
    BOOL _hadError;
    BOOL _isLoading;
}

- (void)loadObjects {
    // Even though we don't depend on the baby being set, we do need the Parse libs to have finished initializing.
    [self loadObjectsWithLimit:MAX_LOAD_COUNT];
}

- (void)loadObjectsWithLimit:(NSInteger)limit {
    _isLoading = YES;
    _hadError = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationFollowConnectionsDataSourceWillLoadObjects object:self];
    [PFCloud callFunctionInBackground:@"queryMyFollowConnections"
                       withParameters:@{@"appVersion" : NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"],
                               @"limit" : [@(limit) stringValue]}
                          cachePolicy:[self hasAnyConnections] ? kPFCachePolicyNetworkOnly : kPFCachePolicyCacheThenNetwork
                                block:^(NSArray *objects, NSError *error) {
                                    _hadError = error != nil;
                                    if (!_hadError) {
                                        [self resetAllConnections];
                                        // Go through and sort the follow connections into buckets
                                        for (FollowConnection *conn in objects) {
                                            if (conn.inviteAcceptedOn) {
                                                [_allConnections[FollowConnectionDataSourceSection_Connected] addObject:conn];
                                            } else if (conn.isInviter) {
                                                [_allConnections[FollowConnectionDataSourceSection_Pending] addObject:conn];
                                            } else {
                                                [_allConnections[FollowConnectionDataSourceSection_WaitingToAccept] addObject:conn];
                                            }
                                        }
                                    }
                                    _isLoading = NO;
                                    [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationFollowConnectionsDataSourceDidLoadObjects object:self];
                                    [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationFollowConnectionsDataSourceDidChange object:self];
                                }];
}

- (void)removeConnectionAtIndex:(NSInteger)index inSection:(FollowConnectionDataSourceSection)section {
    NSMutableArray *sa = _allConnections[section];
    NSInteger oldCount = sa.count;
    [sa removeObjectAtIndex:(NSUInteger) index];
    if (sa.count < oldCount) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kDDNotificationFollowConnectionsDataSourceDidChange object:self];
    }
}

- (BOOL)hadError {
    return _hadError;
}

- (BOOL)isLoading {
    return _isLoading;
}

- (NSArray *)connectionsInSection:(FollowConnectionDataSourceSection)section {
    return (NSArray *) _allConnections[section];
}

- (BOOL)hasAnyConnections {
    for (NSArray *array in _allConnections) {
        if (array.count > 0) return YES;
    }
    return NO;
}

- (NSInteger)countOfTotalConnections {
    NSInteger count = 0;
    for (NSArray *array in _allConnections) {
        count += array.count;
    }
    return count;
}

- (void)resetAllConnections {
    NSMutableArray *allConnections = [[NSMutableArray alloc] initWithCapacity:3];
    [allConnections addObject:[[NSMutableArray alloc] init]];
    [allConnections addObject:[[NSMutableArray alloc] init]];
    [allConnections addObject:[[NSMutableArray alloc] init]];
    _allConnections = allConnections;
}


@end