//
//  AchievementDetailsViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/27/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "AchievementDetailsViewController.h"
#import "WebViewerViewController.h"
#import "NSDate+Utils.m"
#import "PronounHelper.h"
#import "NSDate+HumanizedTime.h"
#import "UIActionSheet+Blocks.h"
#import "UIView+Genie.h"

@interface AchievementDetailsViewController ()

@end

@implementation AchievementDetailsViewController {
    UIDynamicAnimator *_animator;
    CGPoint _percentileMessageCenter;
    BOOL _beganDrag;
    UIView * _backgroundView;
}

// Global for all instances
NSDateFormatter *_dateFormatter;

- (void)awakeFromNib {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    }
}

- (void)viewDidLoad {
    // Capture the screen before the transition
    _backgroundView = [[UIScreen mainScreen] snapshotViewAfterScreenUpdates:NO];
    
    [super viewDidLoad];
    NSAssert(self.achievement, @"Expected Achievement to be set before loading view!");
    
    // Add Extra button on right
    // Add in another button to the right.
    UIBarButtonItem * deleteButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(didClickDeleteButton:)];
    self.navigationItem.rightBarButtonItems = @[self.shareButtonBarItem,deleteButtonItem];
    
    
    self.adView.containingViewController = self;
    self.detailsTextView.delegate = self;
    self.rangleScaleLabel.font = [UIFont fontForAppWithType:Light andSize:11];
    NSDictionary *linkAttributes = @{NSForegroundColorAttributeName : [UIColor appSelectedColor],
            NSUnderlineColorAttributeName : [UIColor appSelectedColor],
            NSUnderlineStyleAttributeName : @(NSUnderlinePatternSolid)};
    self.detailsTextView.linkTextAttributes = linkAttributes; // customizes the appearance of links

    // The references we have when these objects are loaded, do not have all the baby info in them, so we swap them out here.
    if (!self.achievement.baby.isDataAvailable) {
        NSAssert([self.achievement.baby.objectId isEqualToString:Baby.currentBaby.objectId], @"Expected achievements for current baby only!");
        self.achievement.baby = Baby.currentBaby;
    }

    // Start with the thumbnail (if loaded), then load the bigger one later on.
    PFFile *thumbnailImageFile = self.achievement.attachmentThumbnail ? self.achievement.attachmentThumbnail : self.achievement.baby.avatarImageThumbnail;
    [thumbnailImageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        [self.detailsImageButton setImage:[UIImage imageWithData:data] forState:UIControlStateNormal];
        self.detailsImageButton.alpha = (CGFloat) (self.achievement.attachmentThumbnail ? 1.0 : 0.3);
    }];

    self.rangeIndicatorView.rangeScale = 5 * 365;
    self.rangeIndicatorView.rangeReferencePoint = [Baby.currentBaby.birthDate daysDifference:self.achievement.completionDate];

    // TODO: Cloud function to do all this in one shot!
    [self.achievement fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error) {
            // Get achievement details and image
            self.achievement = (MilestoneAchievement *) object;
            BOOL hasImageAttachment = self.achievement.attachment && [self.achievement.attachmentType rangeOfString:@"image"].location != NSNotFound;
            PFFile *imageFile = hasImageAttachment ? self.achievement.attachment : self.achievement.baby.avatarImage;
            if (imageFile) {
                [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                    if (!error) {
                        [self.detailsImageButton setImage:[UIImage imageWithData:data] forState:UIControlStateNormal];
                        self.detailsImageButton.alpha = hasImageAttachment ? 1.0 : 0.3;
                    } else {
                        [UsageAnalytics trackError:error forOperationNamed:@"FetchSingleAchievement" andAdditionalProperties:@{@"id" : self.achievement.objectId}];
                    }
                }];
            }

            // Get the standard milestone data if available
            if (self.achievement.standardMilestone) {
                [self.achievement.standardMilestone fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                    if (!error) {
                        StandardMilestone *milestone = (StandardMilestone *) object;
                        self.rangeIndicatorView.startRange = milestone.rangeLow.integerValue;
                        self.rangeIndicatorView.endRange = milestone.rangeHigh.integerValue;
                        [self updateTitleTextFromAchievement];
                        // Show the percentile
                        if (milestone.canCompare) {
                            [self.achievement calculatePercentileRankingWithBlock:^(float percentile) {
                                if (percentile > 0) {
                                    if (percentile > 50) {
                                        self.statusImageView.image = [UIImage imageNamed:@"completedBest"];
                                    }
                                    [self showPercentileMessage:percentile];
                                }
                            }];
                        }
                    } else {
                        [UsageAnalytics trackError:error forOperationNamed:@"FetchSingleStandardMilestone" andAdditionalProperties:@{@"id" : self.achievement.standardMilestone.objectId}];
                    }
                }];
            }
        }
    }];

    [self updateTitleTextFromAchievement];

}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // Center the text vertically in the TextView
}

- (void)updateTitleTextFromAchievement {
    StandardMilestone *m = self.achievement.standardMilestone;
    NSAttributedString *lf = [[NSAttributedString alloc] initWithString:@"\n"];
    NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] init];
    NSDictionary *dataLabelTextAttributes = @{NSFontAttributeName : [UIFont fontForAppWithType:Medium andSize:13.0], NSForegroundColorAttributeName : [UIColor blackColor]};
    NSDictionary *dataValueTextAttributes = @{NSFontAttributeName : [UIFont fontForAppWithType:Light andSize:13.0], NSForegroundColorAttributeName : [UIColor blackColor]};

    // Title - Always use the custom title if not empty, this way, if later on we link a standard milestone, we still read the text that we entered.
    NSAttributedString *titleString = [[NSAttributedString alloc] initWithString:self.achievement.displayTitle attributes:@{NSFontAttributeName : [UIFont fontForAppWithType:Bold andSize:13.0], NSForegroundColorAttributeName : [UIColor appNormalColor]}];
    [attrText appendAttributedString:titleString];

    // Comments
    if (self.achievement.comment.length) {
        [attrText appendAttributedString:lf];
        NSAttributedString *commentsString = [[NSAttributedString alloc] initWithString:self.achievement.comment attributes:@{NSFontAttributeName : [UIFont fontForAppWithType:Medium andSize:13.0], NSForegroundColorAttributeName : [UIColor appGreyTextColor]}];
        [attrText appendAttributedString:commentsString];
    }

    // Completion date
    NSAttributedString *completedOnLabel = [[NSAttributedString alloc] initWithString:@"Completed on: " attributes:dataLabelTextAttributes];
    NSAttributedString *completedOnValue = [[NSAttributedString alloc] initWithString:[_dateFormatter stringFromDate:self.achievement.completionDate] attributes:dataValueTextAttributes];
    [attrText appendAttributedString:lf];
    [attrText appendAttributedString:lf];
    [attrText appendAttributedString:completedOnLabel];
    [attrText appendAttributedString:completedOnValue];

    if (m.url) {
        [attrText appendAttributedString:lf];
        [attrText appendAttributedString:lf];
        NSMutableAttributedString *readMoreLabel = [[NSMutableAttributedString alloc] initWithString:@"Read More..." attributes:@{
                NSFontAttributeName : [UIFont fontForAppWithType:BoldItalic andSize:17.0],
                NSForegroundColorAttributeName : [UIColor appSelectedColor]
        }];
        [readMoreLabel addAttribute:NSLinkAttributeName value:m.url range:NSMakeRange(0, readMoreLabel.length)];
        [attrText appendAttributedString:readMoreLabel];
    }

    self.detailsTextView.attributedText = attrText;
    CGFloat requiredHeight = [self.detailsTextView sizeThatFits:CGSizeMake(self.detailsTextView.frame.size.width, FLT_MAX)].height;
    if (requiredHeight < self.detailsTextView.frame.size.height) {
        CGFloat offset = self.detailsTextView.frame.size.height - requiredHeight;
        self.detailsTextView.contentInset = UIEdgeInsetsMake(offset / 2, 0, offset / 2, 0);
    } else {
        [self.detailsTextView setContentOffset:CGPointZero animated:NO];
        // Make the bottom of the Text field fade out
        CAGradientLayer *l = [CAGradientLayer layer];
        l.frame = self.detailsTextViewContainerView.bounds;
        l.colors = [NSArray arrayWithObjects:(id) [UIColor whiteColor].CGColor, (id) [UIColor clearColor].CGColor, nil];
        l.startPoint = CGPointMake(0.5f, 0.5f);
        l.endPoint = CGPointMake(0.5f, 1.0f);
        self.detailsTextViewContainerView.layer.mask = l;
    }
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)url inRange:(NSRange)characterRange {
    [self presentViewController:[WebViewerViewController webViewForUrl:url] animated:YES completion:NULL];
    return NO;
}


-(void)didClickDeleteButton:(id) sender {
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"Note that this cannot be undone!"
                                                    delegate:nil
                                           cancelButtonTitle:@"Cancel"
                                      destructiveButtonTitle:@"Delete"
                                           otherButtonTitles:nil];
    
    as.tapBlock = ^(UIActionSheet *actionSheet, NSInteger buttonIndex){
        if(buttonIndex == 0) {
            UIView *trashButton = (UIView *)[self.navigationController.navigationBar.subviews objectAtIndex:2];
            [self.view insertSubview:_backgroundView belowSubview:self.containerView];
            [self.containerView genieInTransitionWithDuration:0.7
                                destinationRect:trashButton.frame
                                destinationEdge:BCRectEdgeBottom
                                     completion:^{
                                         [[NSNotificationCenter defaultCenter] postNotificationName:kAchievementNeedsDeleteAction object:self.achievement];
                                         [self.navigationController popViewControllerAnimated:NO];
                                     }];
        }
    };
    [as showInView:self.view];
}

- (IBAction)didClickActionButton:(id)sender {
    UIImage *image = [self.detailsImageButton imageForState:UIControlStateNormal];
  
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/achievements/%@", VIEW_HOST, self.achievement.objectId]];
    NSString * mainText = [NSString stringWithFormat:@"%@ completed the milestone: '%@' %@!",self.achievement.baby.name, self.achievement.displayTitle,[self.achievement.completionDate stringWithHumanizedTimeDifference]];
    NSMutableArray *items = [NSMutableArray arrayWithObjects:mainText, url, nil];
    if (self.achievement.comment) [items addObject:self.achievement.comment];
    if (image) [items addObject:image];

    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    //[controller setValue:@"My Subject Text" forKey:@"subject"];
    controller.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypePostToVimeo];
    [controller setCompletionHandler:^(NSString *activityType, BOOL completed) {
        if (completed) {
            if ([activityType isEqualToString:UIActivityTypeMail]) {
                self.achievement.sharedVia = self.achievement.sharedVia | SharingMediumEmail;
            } else if ([activityType isEqualToString:UIActivityTypePostToFacebook]) {
                self.achievement.sharedVia = self.achievement.sharedVia | SharingMediumFacebook;
            } else if ([activityType isEqualToString:UIActivityTypePostToTwitter]) {
                self.achievement.sharedVia = self.achievement.sharedVia | SharingMediumTwitter;
            } else if ([activityType isEqualToString:UIActivityTypeMessage]) {
                self.achievement.sharedVia = self.achievement.sharedVia | SharingMediumTextMessage;
            } else {
                self.achievement.sharedVia = self.achievement.sharedVia | SharingMediumOther;
            }
            [self.achievement saveEventually];
        }
    }];
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)showPercentileMessage:(NSInteger)percent {
    UIImage *balloon = [UIImage imageNamed:@"aheadBalloon"];
    UIView *shadowView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 130, 85)];
    shadowView.layer.shadowColor = [UIColor blackColor].CGColor;
    //shadowView.layer.shadowOffset = CGSizeMake(10,10);
    shadowView.layer.shadowOpacity = .5;
    shadowView.alpha = .8;

    UIView *percentileMessageView = [[UIView alloc] initWithFrame:shadowView.frame];
    CALayer *mask = [CALayer layer];
    mask.contents = (id) balloon.CGImage;
    mask.frame = percentileMessageView.frame;
    percentileMessageView.layer.mask = mask;
    percentileMessageView.layer.masksToBounds = YES;
    percentileMessageView.backgroundColor = [UIColor whiteColor];

    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectInset(percentileMessageView.bounds, 5, 5)];

    NSDictionary *messageTextAttributes = @{NSFontAttributeName : [UIFont fontForAppWithType:Medium andSize:13.0], NSForegroundColorAttributeName : [UIColor appGreyTextColor]};
    NSDictionary *percentTextAttributes = @{NSFontAttributeName : [UIFont fontForAppWithType:Bold andSize:18.0], NSForegroundColorAttributeName : [UIColor appHeaderActiveTextColor]};

    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@'s growing up!\n Completed ", [PronounHelper replacePronounTokens:@"${He}" forBaby:Baby.currentBaby]] attributes:messageTextAttributes];
    if (percent >= 50) {
        [string appendAttributedString:[[NSAttributedString alloc] initWithString:@"before " attributes:messageTextAttributes]];
    } else {
        percent = 100 - percent; // flip
        [string appendAttributedString:[[NSAttributedString alloc] initWithString:@"after " attributes:messageTextAttributes]];
    }
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld%%", (long) percent] attributes:percentTextAttributes]];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:@" of data-babies" attributes:messageTextAttributes]];

    messageLabel.attributedText = string;
    messageLabel.numberOfLines = 0;
    messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
    messageLabel.textAlignment = NSTextAlignmentCenter;

    [percentileMessageView addSubview:messageLabel];
    [shadowView addSubview:percentileMessageView];
    [self.containerView addSubview:shadowView];

    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
    [shadowView addGestureRecognizer:panGestureRecognizer];

    shadowView.center = self.rangeIndicatorView.center;
    shadowView.center = CGPointMake(self.detailsImageButton.center.x, -(shadowView.bounds.size.height));

    _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.containerView];
    _animator.delegate = self;
    CGFloat x = self.detailsImageButton.frame.origin.x + self.detailsImageButton.frame.size.width - shadowView.bounds.size.width / 2 - 10;
    CGFloat y = self.detailsImageButton.frame.origin.y + shadowView.bounds.size.height / 2;

    UISnapBehavior *snap = [[UISnapBehavior alloc] initWithItem:shadowView snapToPoint:CGPointMake(x, y)];
    [snap setDamping:1.5];
    [_animator addBehavior:snap];
}

- (void)handlePanFrom:(UIPanGestureRecognizer *)recognizer {

    if (_animator.running) return;

    CGPoint translation = [recognizer translationInView:recognizer.view];
    CGPoint velocity = [recognizer velocityInView:recognizer.view];

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        _beganDrag = YES;
        _percentileMessageCenter = recognizer.view.center;
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (!_beganDrag) return;
        recognizer.view.center = CGPointMake(_percentileMessageCenter.x + translation.x, _percentileMessageCenter.y + translation.y);
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (!_beganDrag) return;
        if ((abs(translation.y) > recognizer.view.bounds.size.height / 3 && abs(velocity.y) > 200.0) ||
                (abs(translation.x) > recognizer.view.bounds.size.width / 3 && abs(velocity.x) > 200.0)) {
            CGFloat velocityScale = .01;
            UIPushBehavior *push = [[UIPushBehavior alloc] initWithItems:@[recognizer.view] mode:UIPushBehaviorModeInstantaneous];
            push.pushDirection = CGVectorMake(velocityScale * velocity.x, velocityScale * velocity.y);
            [_animator addBehavior:push];
        } else {
            UISnapBehavior *snap = [[UISnapBehavior alloc] initWithItem:recognizer.view snapToPoint:_percentileMessageCenter];
            [snap setDamping:.5];
            [_animator addBehavior:snap];
        }
    }
}

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator {
    [animator removeAllBehaviors];
}

//- (UIImage *) lastViewControllerImage {
//    NSInteger numberOfViewControllers = self.navigationController.viewControllers.count;
//    if (numberOfViewControllers < 2)
//        return nil;
//    else {
//        UIView * previousView = ((UIViewController*)  [self.navigationController.viewControllers objectAtIndex:numberOfViewControllers - 2]).view;
//        UIGraphicsBeginImageContextWithOptions(previousView.frame.size, NO, [UIScreen mainScreen].scale);
//        [previousView drawViewHierarchyInRect:previousView.bounds afterScreenUpdates:YES];
//        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
//        return image;
//    }
//}



@end
