//
//  BabyTagsTableViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 4/4/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <Parse/Parse.h>
#import "UIViewController+MBProgressHUD.h"

@interface BabyTagsTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>

@property NSSet *selectedTags; // String Tags

- (void)addNewTag:(NSString *)tagText;

@end
