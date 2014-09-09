//
// Created by Nathan  Pahucki on 9/9/14.
// Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PFFile (Video)

@property(readonly, nonatomic) NSString *mimeType;

+ (instancetype)videoFileFromUrl:(NSURL *)videoUrl;


- (UIImage *)generateThumbImage;
@end