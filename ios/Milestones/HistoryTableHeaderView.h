//
//  HIstoryTableHeaderView.h
//  DataParenting
//
//  Created by Nathan  Pahucki on 6/26/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HistoryTableHeaderView : UIView


@property (strong, nonatomic) NSString * title;
@property NSInteger count;
@property BOOL highlighted;
@property NSInteger position;

@end

