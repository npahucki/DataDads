//
//  BabyTagsTableViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 4/4/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <Parse/Parse.h>

@interface BabyTagsTableViewController : PFQueryTableViewController

@property NSSet* selectedTags; // String Tags

-(void) addNewTag: (NSString*) tagText;

@end


// Tag objects to be added to the list.
NSMutableArray * _addedTags;