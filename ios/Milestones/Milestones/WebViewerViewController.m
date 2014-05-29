//
//  WebViewerViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/28/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "WebViewerViewController.h"

@interface WebViewerViewController ()

@end

@implementation WebViewerViewController

- (IBAction)didClickCloseButton:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.webView.delegate = self;
  NSURLRequest *requestObj = [NSURLRequest requestWithURL:[NSURL URLWithString:self.url]];
  [self.webView loadRequest:requestObj];
  self.loadingImage.image = [UIImage animatedImageNamed:@"progress-" duration:1.0];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
  self.loadingImage.hidden = NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  self.loadingImage.hidden = YES;
}

@end
