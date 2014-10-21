//
// Created by Nathan  Pahucki on 9/29/14.
// Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MediaFile.h"

// The maximum number of bytes that Parse allows to be uploaded.
#define MAX_ATTACHMENT_MEGA_BYTES 50
#define MAX_ATTACHMENT_BYTES_SIZE 1024 * 1024 * MAX_ATTACHMENT_MEGA_BYTES
#define MAX_VIDEO_ATTACHMENT_LENGTH_SECS 240


@interface ExternalMediaFile : NSObject <NSURLSessionTaskDelegate, NSURLSessionDelegate, MediaFile>

@property (readonly) NSString *uniqueId;

+ (instancetype)videoFileFromUrl:(NSURL *)videoUrl;

+ (instancetype)mediaFileFromUrl:(NSURL *)mediaUrl;

+ (void)lookupMediaUrl:(NSString *)uniqueId withBlock:(PFStringResultBlock)block;


@end