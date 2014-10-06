//
// Created by Nathan  Pahucki on 9/29/14.
// Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>

// The maximum number of bytes that Parse allows to be uploaded.
#define MAX_ATTACHMENT_MEGA_BYTES 50
#define MAX_ATTACHMENT_BYTES_SIZE 1024 * 1024 * MAX_ATTACHMENT_MEGA_BYTES
#define MAX_VIDEO_ATTACHMENT_LENGTH_SECS 240


@implementation ExternalMediaFile {
    NSString *_externalUrl;
    NSURL *_localUrl;
    NSURLSession *_session;
    NSMutableDictionary *_responsesData;
}

@synthesize height = _height;
@synthesize width = _width;
@synthesize orientation = _orientation;
@synthesize mimeType = _mimeType;
@synthesize thumbnail = _thumbnail;

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
        NSString *msg = [NSString stringWithFormat:@"Your video is %.02fMB. Please edit the video so that it is smaller than %d MB.", (size.integerValue / (1024.0 * 1024.0)), MAX_ATTACHMENT_MEGA_BYTES];
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

    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    CMTime time = [asset duration];
    time.value = 0;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);  // CGImageRef won't be released by ARC


    ExternalMediaFile *file = [[ExternalMediaFile alloc] init];
    file->_localUrl = videoUrl;
    file->_mimeType = @"video/mov";
    file->_orientation = orientation;
    file->_width = dimensions.width;
    file->_height = dimensions.height;
    file->_thumbnail = thumbnail;
    file->_uniqueId = [file->_uniqueId stringByAppendingString:@"-video.mov"];
    return file;
}

+ (instancetype)mediaFileFromUrl:(NSURL *)mediaUrl {
    ExternalMediaFile *file = [[ExternalMediaFile alloc] init];
    file->_localUrl = mediaUrl;
    return file;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _mimeType = @"application/octet-stream";
        _uniqueId = [[NSUUID UUID] UUIDString];
    }
    return self;
}


+ (void)lookupMediaUrl:(NSString *)uniqueId withBlock:(PFStringResultBlock)block {
    [self lookupMediaUrl:uniqueId forMethod:@"GET" andContentType:nil withBlock:block];
}

+ (void)lookupMediaUrl:(NSString *)uniqueId forMethod:(NSString *)method andContentType:(NSString *)contentType withBlock:(PFStringResultBlock)block {
    NSAssert(uniqueId, @"Unique ID must be set before url can be looked up");
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:
            @{@"uniqueId" : uniqueId,
                    @"method" : method,
                    @"appVersion" : NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"]}];
    if (contentType) params[@"contentType"] = contentType;
    [PFCloud callFunctionInBackground:@"fetchStorageUploadUrl"
                       withParameters:params
                                block:^(NSDictionary *results, NSError *error) {
                                    if (error) {
                                        block(nil, error);
                                    } else {
                                        block(results[@"url"], nil);
                                    }
                                }];

}

- (void)saveInBackgroundWithBlock:(PFBooleanResultBlock)block progressBlock:(PFProgressBlock)progressBlock atUrl:(NSString *)url {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"PUT"];
    [request setValue:_mimeType forHTTPHeaderField:@"Content-Type"];

    if (!_session) {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfig.allowsCellularAccess = YES;
        sessionConfig.timeoutIntervalForRequest = 10.0;
        sessionConfig.timeoutIntervalForResource = 360.0;
        sessionConfig.HTTPMaximumConnectionsPerHost = 1;
        _session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    }

    NSURLSessionUploadTask *task = [_session uploadTaskWithRequest:request fromFile:_localUrl];
    task.taskDescription = url;
    objc_setAssociatedObject(task, "DP.progressBlock", progressBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(task, "DP.block", block, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [task resume];
}

- (void)saveInBackgroundWithBlock:(PFBooleanResultBlock)block progressBlock:(PFProgressBlock)progressBlock {
    if (_externalUrl) {
        [self saveInBackgroundWithBlock:block progressBlock:progressBlock atUrl:_externalUrl];
    } else {
        [ExternalMediaFile lookupMediaUrl:_uniqueId forMethod:@"PUT" andContentType:_mimeType withBlock:^(NSString *url, NSError *error) {
            if (error) {
                block(NO, error);
            } else {
                _externalUrl = url;
                NSAssert([_externalUrl length] > 0, @"Expected a URL to be returned from cloud service");
                [self saveInBackgroundWithBlock:block progressBlock:progressBlock atUrl:_externalUrl];
            }
        }];
    }
}

- (void)cancel {
    [_session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        for (NSURLSessionTask *task in uploadTasks) {
            [task cancel];
        }
        for (NSURLSessionTask *task in downloadTasks) {
            [task cancel];
        }
        for (NSURLSessionTask *task in dataTasks) {
            [task cancel];
        }
    }];
}


/* Sent periodically to notify the delegate of upload progress.  This
 * information is also available as properties of the task.
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent
          totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    PFProgressBlock progressBlock = objc_getAssociatedObject(task, "DP.progressBlock");
    if (progressBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            progressBlock((int) (100.0 * ((double) totalBytesSent / (double) totalBytesExpectedToSend)));
        });
    }
}

/* Sent as the last message related to a specific task.  Error may be
 * nil, which implies that no error occurred and this task is complete.
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *) task.response;
    PFBooleanResultBlock block = objc_getAssociatedObject(task, "DP.block");
    PFProgressBlock progressBlock = objc_getAssociatedObject(task, "DP.progressBlock");

    BOOL success = NO;
    if (!error) {
        success = httpResp.statusCode == 200;
        if (!success) {
            NSMutableData *responseData = _responsesData[@(task.taskIdentifier)];
            NSLog(@"Error Code:%ld Response:%@", (long) httpResp.statusCode, [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }
    } else {
        if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
            // Canceled at user's request
            success = NO;
            error = nil;
        } else {
            // If reachable, retry, if not, show a message
            if ([Reachability isParseCurrentlyReachable]) {
                // Retry...
                _externalUrl = nil; // Get a new external URL, since this other one may have timed out.
                [self saveInBackgroundWithBlock:block progressBlock:progressBlock];
                NSLog(@"Retrying after error uploading video. Error:%@", error);
                return; // don't call block, we retried
            }
        }
    }
    [_responsesData removeObjectForKey:@(task.taskIdentifier)];
    if (block) {
        dispatch_async(dispatch_get_main_queue(), ^{
            block(success, error);
        });
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if (!_responsesData) {
        _responsesData = [NSMutableDictionary dictionary];
    }

    NSMutableData *responseData = _responsesData[@(dataTask.taskIdentifier)];
    if (!responseData) {
        responseData = [NSMutableData dataWithData:data];
        _responsesData[@(dataTask.taskIdentifier)] = responseData;
    } else {
        [responseData appendData:data];
    }
}


@end