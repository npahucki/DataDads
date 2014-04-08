//
//  BabyInfoPhotoControllerViewController.h
//  Milestones
//
//  Created by Nathan  Pahucki on 4/5/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "UIViewControllerWithHUDProgress.h"
#import "FDTakeController.h"


@interface BabyInfoPhotoControllerViewController : UIViewControllerWithHUDProgress <FDTakeDelegate>

@property (strong, nonatomic) IBOutlet UIButton *takePhotoButton;
@property (strong, nonatomic) IBOutlet UILabel *theLabel;
@property (strong, nonatomic) Baby *baby;




@end

FDTakeController* _takeController;
NSData * _imageData;

