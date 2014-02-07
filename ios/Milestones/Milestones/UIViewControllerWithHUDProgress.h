//
//  UIViewControllerWithHUDProgressViewController.h - A view controller that has some common HUD Progress capabilities built in.
//  Milestones
//
//  A View

//  Created by Nathan  Pahucki on 2/7/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"


@interface UIViewControllerWithHUDProgress : UIViewController

@property MBProgressHUD * hud;

/*
  SHos the HUD Progress view added to the ViewController's main view.
 */
-(void) showHUD: (BOOL) animated;

/*
  SHows the HUD Progress view added to the ViewController's main view, and sets the lablel text.
 */
-(void) showHUDWithMessage:(NSString*) msg andAnimation:(BOOL) animated;

/*
 Used for indicaitng that the data was saved sucessfully and then dismissing the dialog.
*/
-(void) showSaveSuccessAndDismissDialog;

/*
 Used for showing error messages when saving an object (usually to Parse).
 Hides and HUD that is active, logs the error and shows the given message in a UIAlertView with an error title. Also appends text to the message 
 indicating that the user should make sure that he is connected to the network and try again.
 */
-(void) showSaveError:(NSError*) error withMessage:(NSString*) msg;

/*
 Shows a general alert with a dismiss button. This can be used for errors or validation messages.
 */
-(void) showGeneralAlert:(NSString*) title withMessage:(NSString*) msg;

/*
  Saves a PFObject in the background while showing a progress dialog. If the save was successful, then an indication is shown 
  and the dialog is dismissed. If there is an error, then the provided error message is displayed and the error logged, the dialog is not dimissed. 
*/
-(void) saveObject:(PFObject*) object withTitle:(NSString*) title andFailureMessage:(NSString*)msg;



@end

