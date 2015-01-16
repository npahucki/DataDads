//
// Created by Nathan  Pahucki on 1/16/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "ViewControllerWithBabyInfoButton.h"
#import "UIImage+FX.h"


@implementation ViewControllerWithBabyInfoButton {
    UIButton *_babyButton;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(babyUpdated:) name:kDDNotificationCurrentBabyChanged object:nil];

    _babyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _babyButton.frame = CGRectMake(0, 0, 38, 38);
    [_babyButton addTarget:self action:@selector(didClickBabyMenuButton) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_babyButton];

    [self updateBabyInfo:Baby.currentBaby];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _babyButton.enabled = Baby.currentBaby != nil;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didClickBabyMenuButton {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    UINavigationController *vc = [sb instantiateViewControllerWithIdentifier:@"babyInfoNavigationController"];
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:vc animated:YES completion:NULL];
}

- (void)babyUpdated:(NSNotification *)notification {
    Baby *baby = notification.object;
    [self updateBabyInfo:baby];
}

- (void)updateBabyInfo:(Baby *)baby {
    _babyButton.enabled = baby != nil;

    PFFile *imageFile = baby.avatarImageThumbnail ? baby.avatarImageThumbnail : baby.avatarImage;
    if (imageFile) {
        [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (!error) {
                UIImage *image = [[UIImage alloc] initWithData:data];
                if (image) {
                    [_babyButton setImage:image forState:UIControlStateNormal];
                    [_babyButton setImage:[image imageWithAlpha:.70] forState:UIControlStateHighlighted];
                    _babyButton.layer.borderColor = [UIColor appNormalColor].CGColor;

                    CALayer *innerShadowLayer = [CALayer layer];
                    innerShadowLayer.contents = (id) [UIImage imageNamed:@"avatarButtonShadow"].CGImage;
                    innerShadowLayer.contentsCenter = CGRectMake(10.0f / 21.0f, 10.0f / 21.0f, 1.0f / 21.0f, 1.0f / 21.0f);
                    innerShadowLayer.frame = CGRectInset(_babyButton.bounds, 2.5, 2.5);
                    [_babyButton.layer addSublayer:innerShadowLayer];
                    _babyButton.layer.borderWidth = 3;
                    _babyButton.layer.cornerRadius = _babyButton.bounds.size.width / 2;
                    _babyButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
                    _babyButton.clipsToBounds = YES;
                    _babyButton.showsTouchWhenHighlighted = YES;
                }
            }
        }];
    } else {
        [_babyButton setImage:[UIImage imageNamed:@"avatarButtonDefault"] forState:UIControlStateNormal];
        [_babyButton setImage:[UIImage imageNamed:@"avatarButtonDefault_pressed"] forState:UIControlStateHighlighted];
    }
}


@end