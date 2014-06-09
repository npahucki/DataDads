//
//  BabyTagsTableViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 4/4/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <Parse/Parse.h>
#import "AppQueryTableViewController.h"
#import "UIViewController+MBProgressHUD.h"

@interface BabyTagsTableViewController : UITableViewController <UITableViewDataSource,UITableViewDelegate>

@property NSSet* selectedTags; // String Tags

-(void) addNewTag: (NSString*) tagText;

@end
