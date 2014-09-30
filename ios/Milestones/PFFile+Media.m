//
// Created by Nathan  Pahucki on 9/9/14.
// Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <objc/runtime.h>
#import "PFFile+Media.h"


@implementation PFFile (Media)

@dynamic thumbnail;

+ (instancetype)imageFileFromImage:(UIImage *)image {
    NSString *mimeType = @"image/jpg";
    PFFile *file = [PFFile fileWithName:@"photo.jpg" data:UIImageJPEGRepresentation(image, 0.5f) contentType:@"image/jpg"];
    objc_setAssociatedObject(file, "DP.mimeType", mimeType, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(file, "DP.orientation", @(image.imageOrientation), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(file, "DP.dimensions.width", @(image.size.width), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(file, "DP.dimensions.height", @(image.size.height), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return file;
}

- (NSString *)mimeType {
    return objc_getAssociatedObject(self, "DP.mimeType");
}

- (void)setMimeType:(NSString *)mimeType {
    objc_setAssociatedObject(self, "DP.mimeType", mimeType, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImageOrientation)orientation {
    NSNumber *orientation = objc_getAssociatedObject(self, "DP.orientation");
    return (UIImageOrientation) orientation.integerValue;
}

- (CGFloat)width {
    NSNumber *width = objc_getAssociatedObject(self, "DP.dimensions.width");
    return width.floatValue;
}

- (CGFloat)height {
    NSNumber *height = objc_getAssociatedObject(self, "DP.dimensions.height");
    return height.floatValue;
}


@end