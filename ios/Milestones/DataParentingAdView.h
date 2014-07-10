//
//  DataParentingAdView.h
//  DataParenting
//
//  Created by Nathan  Pahucki on 7/9/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, DataParentingAdViewSize) {
  DataParentingAdViewSizeSmall, // 320x50
  DataParentingAdViewSizeMedium // 213x320
};

@protocol DataParentingAdViewDelegate <NSObject>

@required
-(void) displayAdView;
-(void) hideAdView;

@end

@interface DataParentingAdView : UIView

@property DataParentingAdViewSize size;
@property (strong, nonatomic) id<DataParentingAdViewDelegate> delegate;
@property (weak,nonatomic) UIViewController * containingViewController;

@property (readonly) NSURL * currentAdLinkURL;
@property (readonly) int currentAdImageHeight;
@property (readonly) int currentAdImageWidth;


@end



