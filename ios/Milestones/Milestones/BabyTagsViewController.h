//
//  BabyTagsViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 4/4/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BabyTagsTableViewController.h"

@interface BabyTagsViewController : UIViewController

@property (strong, nonatomic) Baby *baby;
@property (strong, nonatomic) IBOutlet UITextField *addTagTextField;
@property (strong, nonatomic) IBOutlet UIButton *addTagButton;

@end


