//
//  DataParentingAdView.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 7/9/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "DataParentingAdView.h"
#import "WebViewerViewController.h"


@implementation DataParentingAdView {
  UIButton * _adView;
  BOOL _isShowing;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
      [self initializeWebViewWithFrame:frame];
    }
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if(self) {
    [self initializeWebViewWithFrame:CGRectZero];
  }
  return self;
}

-(void) initializeWebViewWithFrame:(CGRect) frame {
  _adView = [[UIButton alloc] initWithFrame:frame];
  [_adView setTitle:@"Annoying ad now in labor..." forState:UIControlStateNormal];
  [_adView setTitleColor:[UIColor appGreyTextColor] forState:UIControlStateNormal];
  _adView.titleLabel.font = [UIFont fontForAppWithType:BookItalic andSize:17];
  _adView.layer.borderWidth = 1;
  _adView.layer.borderColor = [UIColor appInputBorderNormalColor].CGColor;
  [_adView addTarget:self action:@selector(handleSingleTap) forControlEvents:UIControlEventTouchUpInside];
  
  [self addSubview:_adView];
}


-(void) layoutSubviews {
  _adView.frame = self.bounds;
}

-(void) awakeFromNib {
  [self attemptAdLoad];
}


-(void) scheduleTimeDisplay {
  [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(attemptAdLoad) userInfo:nil repeats:NO];
}

-(void) attemptAdLoad {
  [PFCloud callFunctionInBackground:@"getAdToShow"
                     withParameters:@{@"size": self.size == 1 ? @"medium" : @"small"}
                              block:^(NSDictionary *results, NSError *error) {
                                if(!error) {
                                  /**
                                   {"size":{"width":320,"height":50},"ad":{"imageUrl":"http://dataparentingdev.parseapp.com/ads/320x50/DataDads Noodles2.jpg","linkUrl":"http://http://dataparenting.com/donate/"}}
                                   */
                                  _currentAdImageWidth = ((NSNumber*)results[@"size"][@"width"]).intValue;
                                  _currentAdImageHeight = ((NSNumber*)results[@"size"][@"height"]).intValue;
                                  NSString * imageUrlString = (NSString*) results[@"ad"][@"imageUrl"];
                                  _currentAdLinkURL = [NSURL URLWithString:(NSString*)results[@"ad"][@"linkUrl"]];
                                  _currentAdImageURL = [NSURL URLWithString: [imageUrlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                                  [self performSelectorInBackground:@selector(loadImageData:) withObject:_currentAdImageURL];
                                }
                              }];
}


-(void) handleSingleTap {
  if([self.delegate respondsToSelector:@selector(adClicked)]) {
    [self.delegate adClicked];
  }
  UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
  WebViewerViewController *vc = [sb instantiateViewControllerWithIdentifier:@"webViewController"];
  vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  vc.url = _currentAdLinkURL;
  [self.containingViewController presentViewController:vc animated:YES completion:NULL];
  [UsageAnalytics trackAdClicked:_currentAdImageURL.absoluteString];
}

-(void) loadImageData:(NSURL *) url {
  NSError* error = nil;
  NSData * imageData = [[NSData alloc] initWithContentsOfURL:url options:0 error:&error];
  if(!error) {
    [self performSelectorOnMainThread:@selector(loadImageDataSuceeded:) withObject:imageData waitUntilDone:NO];
  } else {
    [self performSelectorOnMainThread:@selector(loadImageDataFailed:) withObject:error waitUntilDone:NO];
  }
}

-(void) loadImageDataSuceeded:(NSData*) data {
  UIImage * image = [[UIImage alloc] initWithData:data];
  if(image) {
    [_adView setTitle:nil forState:UIControlStateNormal];
    [_adView setBackgroundImage:image  forState:UIControlStateNormal];
    _isShowing = YES;
    [self.delegate displayAdView];
  }
}

-(void) loadImageDataFailed:(NSError*) error {
  NSLog(@"Failed to load Ad data:%@", error);
  _isShowing = false;
  [self.delegate hideAdView];
}




@end