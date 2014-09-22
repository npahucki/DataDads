//
// Created by Nathan  Pahucki on 9/9/14.
// Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PFFile (Media)

@property(readonly, nonatomic) NSString *mimeType;

+ (instancetype)videoFileFromUrl:(NSURL *)videoUrl;

+ (instancetype)imageFileFromImage:(UIImage *)image;


- (NSString *)mimeType;

- (UIImageOrientation)orientation;

- (CGFloat)width;

- (CGFloat)height;

// May return nil if not implemented
- (UIImage *)generateThumbImage;
@end