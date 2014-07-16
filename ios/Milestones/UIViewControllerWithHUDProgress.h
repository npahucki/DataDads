//
//  UIViewControllerWithHUDProgressViewController.h - A view controller that has some common HUD Progress capabilities built in.
//  Milestones
//
//  A View

//  Created by Nathan  Pahucki on 2/7/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewController+MBProgressHUD.h"


@interface UIViewControllerWithHUDProgress : UIViewController


/*
 Dimisses the current view either by poping to the root controller (if in Nav Controller) or dimissing modally
 */
- (void)dismiss;

/*
  Saves a PFObject in the background while showing a progress dialog. If the save was successful, then an indication is shown 
  and the dialog is dismissed. If there is an error, then the provided error message is displayed and the error logged, the dialog is not dimissed. 
*/
- (void)saveObject:(PFObject *)object withTitle:(NSString *)title andFailureMessage:(NSString *)msg andBlock:(void (^)(NSError *))block;


@end



