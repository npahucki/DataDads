//
//  BabyInfoPhotoControllerViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 4/5/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "BabyInfoPhotoViewController.h"


@interface BabyInfoPhotoViewController ()

@end


@implementation BabyInfoPhotoViewController {
    FDTakeController *_takeController;
    NSData *_imageData;
    BOOL _showOptionalSignup;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    NSAssert(self.baby, @"Expected baby would be set before view loads");

    self.theLabel.font = [UIFont fontForAppWithType:Light andSize:31.0];
    self.theLabel.textColor = [UIColor appNormalColor];

    if (self.baby.avatarImage) {
        [self.baby.avatarImage getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (!error) {
                [self.takePhotoButton setImage:[UIImage imageWithData:data] forState:UIControlStateNormal];
            } else {
                NSLog(@"Failed to load image %@", error);
            }
        }];
    }

    self.navigationItem.prompt = [self.navigationItem.prompt stringByAppendingString:@" (Optional)"];
    _showOptionalSignup = ![ParentUser currentUser].isAuthenticated;
}

- (IBAction)didClickNextButton:(id)sender {
    if (_showOptionalSignup) {
        [self performSegueWithIdentifier:kDDSegueShowOptionalSignup sender:self];
    } else {
        [self performSegueWithIdentifier:kDDSegueShowAboutYou sender:self];
    }
}

- (IBAction)didClickPhotoButton:(id)sender {
    _takeController = [[FDTakeController alloc] init];
    _takeController.delegate = self;
    _takeController.viewControllerForPresentingImagePickerController = self;
    _takeController.allowsEditingPhoto = YES;
    _takeController.allowsEditingVideo = NO;
    [_takeController takePhotoOrChooseFromLibrary];
}

#pragma mark - FDTakeDelegate

- (void)takeController:(FDTakeController *)controller didCancelAfterAttempting:(BOOL)madeAttempt {
    // TODO: Log this for user interaction tracking
}

- (void)takeController:(FDTakeController *)controller gotPhoto:(UIImage *)photo withInfo:(NSDictionary *)info {
    _imageData = UIImageJPEGRepresentation(photo, 0.5f);
    [self.takePhotoButton setImage:photo forState:UIControlStateNormal];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (_imageData) { // Don't save blank images
        PFFile *file = [PFFile fileWithData:_imageData];
        self.baby.avatarImage = file;
    }
    [super prepareForSegue:segue sender:sender];
}


@end
