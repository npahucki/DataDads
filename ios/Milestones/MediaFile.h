//
// Created by Nathan  Pahucki on 9/30/14.
// Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/PFConstants.h>

@protocol MediaFile <NSObject>

@property(readonly) UIImageOrientation orientation;
@property(readonly) CGFloat width;
@property(readonly) CGFloat height;
@property(readonly) UIImage *thumbnail;
@property(nonatomic, strong) NSString *mimeType;

- (void)saveInBackgroundWithBlock:(PFBooleanResultBlock)block
                    progressBlock:(PFProgressBlock)progressBlock;

// Cancel any ongoing data transfer.
- (void)cancel;
@end