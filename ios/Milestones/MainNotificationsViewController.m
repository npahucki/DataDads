//
//  NotificationsViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/23/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "MainNotificationsViewController.h"
#import "NotificationTableViewController.h"
#import "NoConnectionAlertView.h"
#import "UIImage+FX.h"

@interface MainNotificationsViewController ()

@end

@implementation MainNotificationsViewController {
    NotificationTableViewController *_tableController;
}

//- (IBAction)didChangeFilter:(id)sender {
//    UISegmentedControl *ctl = (UISegmentedControl *) sender;
//    switch (ctl.selectedSegmentIndex) {
//        case 0:
//            _tableController.tipFilter = TipTypeNormal;
//            break;
//        case 1:
//            _tableController.tipFilter = TipTypeWarning;
//            break;
//        default:
//            _tableController.tipFilter = TipTypeAll;
//            break;
//    }
//}


- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(babyUpdated:) name:kDDNotificationCurrentBabyChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotPushNotification:) name:kDDNotificationPushReceieved object:nil];

    [NoConnectionAlertView createInstanceForController:self];

    // Since controller loads after baby is set, we need to run the code to update the button icon.
    [self updateBabyInfo:Baby.currentBaby];

}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //self.menuButton.enabled = Baby.currentBaby != nil;
    // Hack work around a double segue bug, caused by touching the cell too long

    BOOL isAnonymous = !PFUser.currentUser.email;
    self.containerView.hidden = isAnonymous;
    self.signUpContainerView.hidden = !isAnonymous;
}

- (void)appEnterForeground:(NSNotification *)notice {
    [_tableController loadObjects];
}

- (void)gotPushNotification:(NSNotification *)notice {
    [_tableController loadObjects];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // The only segue is the embed
    if ([segue.destinationViewController isKindOfClass:[NotificationTableViewController class]]) {
        _tableController = (NotificationTableViewController *) segue.destinationViewController;
    }
}

- (void)babyUpdated:(NSNotification *)notification {
    Baby *baby = (Baby *) notification.object;
    [self updateBabyInfo:baby];
}

- (void)updateBabyInfo:(Baby *)baby {
    self.babyMenuButton.enabled = baby != nil;

    PFFile *imageFile = baby.avatarImageThumbnail ? baby.avatarImageThumbnail : baby.avatarImage;
    if (imageFile) {
        [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (!error) {
                UIImage *image = [[UIImage alloc] initWithData:data];
                if (image) {
                    [self.babyMenuButton setImage:image forState:UIControlStateNormal];
                    [self.babyMenuButton setImage:[image imageWithAlpha:.70] forState:UIControlStateHighlighted];
                    self.babyMenuButton.layer.borderColor = [UIColor appNormalColor].CGColor;

                    CALayer *innerShadowLayer = [CALayer layer];
                    innerShadowLayer.contents = (id) [UIImage imageNamed:@"avatarButtonShadow"].CGImage;
                    innerShadowLayer.contentsCenter = CGRectMake(10.0f / 21.0f, 10.0f / 21.0f, 1.0f / 21.0f, 1.0f / 21.0f);
                    innerShadowLayer.frame = CGRectInset(self.babyMenuButton.bounds, 2.5, 2.5);
                    [self.babyMenuButton.layer addSublayer:innerShadowLayer];
                    self.babyMenuButton.layer.borderWidth = 3;
                    self.babyMenuButton.layer.cornerRadius = self.babyMenuButton.bounds.size.width / 2;
                    self.babyMenuButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
                    self.babyMenuButton.clipsToBounds = YES;
                    self.babyMenuButton.showsTouchWhenHighlighted = YES;
                }
            }
        }];
    }
}


@end
