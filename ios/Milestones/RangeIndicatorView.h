//
//  RangeIndicatorView.h - Used for filling in a pie chart in a rectangle.
//  DataParenting
//
//  Created by Nathan  Pahucki on 6/25/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//



#import <UIKit/UIKit.h>

@interface RangeIndicatorView : UIView

@property NSInteger rangeScale;
@property NSInteger startRange;
@property NSInteger endRange;

@property NSInteger rangeReferencePoint; // If less than 0, not shown.

@end
