//
//  UIAlertView+BlockSupport.h
//  Milestones
//
//  Created by Nathan  Pahucki on 6/5/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^UIAlertViewResultBlock)(NSInteger buttonIndex);

@interface UIAlertView (BlockSupport) <UIAlertViewDelegate>


- (void)showWithButtonBlock:(UIAlertViewResultBlock)block;

- (void)showEmailPromptWithBlock:(PFStringResultBlock)block;


@end
