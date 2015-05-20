//
//  WebViewerViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/28/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "WebViewerViewController.h"

@interface WebViewerViewController ()

@end

@implementation WebViewerViewController

+ (WebViewerViewController *)webViewForUrlString:(NSString *)url {
    return [self webViewForUrl:[NSURL URLWithString:url]];
}

+ (WebViewerViewController *)webViewForUrl:(NSURL *)url {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    WebViewerViewController *vc = [sb instantiateViewControllerWithIdentifier:@"webViewController"];
    vc.url = url;
    vc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    return vc;
}


- (IBAction)didClickCloseButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.webView.delegate = self;
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:self.url];
    [self.webView loadRequest:requestObj];
    self.loadingImage.image = [UIImage animatedImageNamed:@"progress-" duration:1.0];
    self.closeButton.hidden = !self.showCloseButton;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [UIView transitionWithView:self.loadingImage
                      duration:0.5
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:nil];
    self.loadingImage.hidden = NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [UIView transitionWithView:self.loadingImage
                      duration:0.2
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:nil];
    self.loadingImage.hidden = YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    int count = 9;
    NSMutableArray *images = [[NSMutableArray alloc] initWithCapacity:count];
    for (int i = 0; i < count; i++) {
        [images addObject:[UIImage imageNamed:[NSString stringWithFormat:@"error-%d.png", i]]];
    }
    self.loadingImage.animationImages = images;
    self.loadingImage.animationDuration = .75;
    self.loadingImage.animationRepeatCount = 1;
    self.loadingImage.image = [images lastObject];
    [self.loadingImage startAnimating];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
