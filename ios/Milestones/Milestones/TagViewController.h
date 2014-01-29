//
//  TagViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 1/28/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TagViewDelegate <NSObject>

@required

- (void)tagsDidFinishSelection:(NSOrderedSet *) tags;

@end


@interface TagViewController : UIViewController

@property(nonatomic,weak) id<TagViewDelegate> delegate;

@end


NSMutableOrderedSet * selectedTags;
NSArray * tagViews;
