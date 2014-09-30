//
// Created by Nathan  Pahucki on 9/29/14.
// Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ExternalMediaFile : NSObject<NSURLSessionTaskDelegate, NSURLSessionDelegate>

@property (readonly) NSString *uniqueId;
@property (nonatomic, strong) NSString *mimeType;
@property (readonly) NSNumber *orientation;
@property (readonly) NSNumber *width;
@property (readonly) NSNumber *height;

+ (instancetype)videoFileFromUrl:(NSURL *)videoUrl;

+ (instancetype)mediaFileFromUrl:(NSURL *)mediaUrl;

+ (void)lookupMediaUrl:(NSString *)uniqueId withBlock:(PFStringResultBlock)block;

- (void)saveInBackgroundWithBlock:(PFBooleanResultBlock)block
                    progressBlock:(PFProgressBlock)progressBlock;



@end