//
// Created by Nathan  Pahucki on 9/9/14.
// Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>
#import "PFFile+Media.h"

// The maximum number of bytes that Parse allows to be uploaded.
#define MAX_ATTACHMENT_BYTES_SIZE 10485760
#define MAX_VIDEO_ATTACHMENT_LENGTH_SECS 120


@implementation PFFile (Media)

+ (instancetype)videoFileFromUrl:(NSURL *)videoUrl {

    NSError *error = nil;
    NSDictionary *properties = [[NSFileManager defaultManager] attributesOfItemAtPath:videoUrl.path error:&error];
    if (error) {
        [[[UIAlertView alloc] initWithTitle:@"Problem With Video" message:@"The selected video file can not be used" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        [UsageAnalytics trackError:error forOperationNamed:@"lookupVideoURL"];
        return nil;
    }

    NSNumber *size = properties[NSFileSize];
    NSLog(@"Video is %@ bytes", size);
    if (size.integerValue >= MAX_ATTACHMENT_BYTES_SIZE) {
        NSString *msg = [NSString stringWithFormat:@"Your video is %.02fMB. Please edit the video so that it is smaller than 10 MB.", (size.integerValue / (1024.0 * 1024.0))];
        [[[UIAlertView alloc] initWithTitle:@"Video Too Big" message:msg delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        return nil;
    }

    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    NSTimeInterval durationInSeconds = CMTimeGetSeconds(asset.duration);
    NSLog(@"Video is %.02f seconds", durationInSeconds);
    if (durationInSeconds >= MAX_VIDEO_ATTACHMENT_LENGTH_SECS) {
        [[[UIAlertView alloc] initWithTitle:@"Video Too Long" message:[NSString stringWithFormat:@"Please edit the video so that it is less than %d seconds", MAX_VIDEO_ATTACHMENT_LENGTH_SECS] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        return nil;
    }

    AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
    CGSize dimensions = [videoTrack naturalSize];
    CGAffineTransform txf = [videoTrack preferredTransform];
    UIImageOrientation orientation;
    if (dimensions.width == txf.tx && dimensions.height == txf.ty)
        orientation = UIImageOrientationDown;
    else if (txf.tx == 0 && txf.ty == 0)
        orientation = UIImageOrientationUp;
    else if (txf.tx == 0 && txf.ty == dimensions.width)
        orientation = UIImageOrientationLeft;
    else
        orientation = UIImageOrientationRight;

    PFFile *file = [PFFile fileWithName:@"video.mov" contentsAtPath:videoUrl.path];
    objc_setAssociatedObject(file, "DP.videoFile", videoUrl, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(file, "DP.mimeType", @"video/mov", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(file, "DP.orientation", @(orientation), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(file, "DP.dimensions.width", @(dimensions.width), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(file, "DP.dimensions.height", @(dimensions.height), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return file;
}

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

- (UIImage *)generateThumbImage {
    NSURL *url = objc_getAssociatedObject(self, "DP.videoFile");
    NSAssert(url != nil, @"Must set video URL before trying to get thumbnail");
    AVAsset *asset = [AVAsset assetWithURL:url];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    CMTime time = [asset duration];
    time.value = 0;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);  // CGImageRef won't be released by ARC
    return thumbnail;
}


@end