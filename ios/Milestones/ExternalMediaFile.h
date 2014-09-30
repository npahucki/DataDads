//
// Created by Nathan  Pahucki on 9/29/14.
// Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MediaFile.h"


@interface ExternalMediaFile : NSObject <NSURLSessionTaskDelegate, NSURLSessionDelegate, MediaFile>

@property (readonly) NSString *uniqueId;

+ (instancetype)videoFileFromUrl:(NSURL *)videoUrl;

+ (instancetype)mediaFileFromUrl:(NSURL *)mediaUrl;

+ (void)lookupMediaUrl:(NSString *)uniqueId withBlock:(PFStringResultBlock)block;


@end