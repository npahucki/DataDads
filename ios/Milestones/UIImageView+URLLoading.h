//
// Created by Nathan  Pahucki on 1/7/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIImageView (URLLoading)

- (void)loadImageFromUrlString:(NSString *)urlString;

- (void)loadImageFromUrl:(NSURL *)url;

@end