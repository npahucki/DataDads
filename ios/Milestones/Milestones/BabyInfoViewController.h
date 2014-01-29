//
//  BabyInfoViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TagViewController.h"
#import "Baby.h"

@interface BabyInfoViewController : UIViewController <TagViewDelegate>
@property (strong, nonatomic) IBOutlet UITextField *dobTextField;
@property (strong, nonatomic) IBOutlet UITextField *dueDateTextField;
@property (strong, nonatomic) IBOutlet UITextField *babyName;
@property (strong, nonatomic) IBOutlet UISegmentedControl *genderControl;
@property (strong, nonatomic) IBOutlet UITextView *tagsTextField;


@end


// Need to retain this with 'strong' otherwise it gets released since there is no other strong reference to it. 
TagViewController * tagViewController;

Baby * baby;