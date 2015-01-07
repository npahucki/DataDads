//
// Created by Nathan  Pahucki on 1/7/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "UIImageView+URLLoading.h"


@implementation UIImageView (URLLoading)

- (void)loadImageFromUrlString:(NSString *)urlString {
    if (urlString.length) {
        [self loadImageFromUrl:[NSURL URLWithString:urlString]];
    }
}

- (void)loadImageFromUrl:(NSURL *)url {
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url]
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                               if (httpResponse.statusCode == 200 && [httpResponse.MIMEType hasPrefix:@"image"]) {
                                   self.image = [UIImage imageWithData:data];
                               }
                           }];
}

@end