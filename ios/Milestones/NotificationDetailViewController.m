//
//  NotificationDetailViewController.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 9/3/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "NotificationDetailViewController.h"
#import "NSDate+HumanizedTime.h"

@interface NotificationDetailViewController ()

@end

@implementation NotificationDetailViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO; // kill padding at top

    NSMutableParagraphStyle *centerParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    centerParagraphStyle.alignment = NSTextAlignmentCenter;
    centerParagraphStyle.alignment = NSTextAlignmentCenter;

    NSDictionary *titleAttributes = @{
            NSFontAttributeName : [UIFont fontForAppWithType:Medium andSize:15.0],
            NSForegroundColorAttributeName : [UIColor appHeaderActiveTextColor]
    };
    NSDictionary *bodyAttributes = @{NSFontAttributeName : [UIFont fontForAppWithType:Light andSize:13.0], NSForegroundColorAttributeName : [UIColor blackColor]};
    NSDictionary *metaAttributes = @{NSFontAttributeName : [UIFont fontForAppWithType:Light andSize:12.0], NSForegroundColorAttributeName : [UIColor appGreyTextColor]};
    NSAttributedString *lf = [[NSAttributedString alloc] initWithString:@"\n"];

    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:self.tipAssignment.tip.titleForCurrentBaby attributes:titleAttributes]];
    if (self.tipAssignment.tip.shortDescription) {
        [text appendAttributedString:lf];
        [text appendAttributedString:[[NSAttributedString alloc] initWithString:self.tipAssignment.tip.shortDescriptionForCurrentBaby attributes:bodyAttributes]];
    }

    [text appendAttributedString:lf];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:
                    [NSString stringWithFormat:@"Delivered %@", [self.tipAssignment.assignmentDate stringWithHumanizedTimeDifference]]
                                                                 attributes:metaAttributes]];

    self.detailTextView.attributedText = text;
}

- (IBAction)didClickActionButton:(id)sender {
    NSString *mainText = [NSString stringWithFormat:@"I want to share this cool baby %@ I found on DataParenting:\n\"%@\"\n\n%@\n",
                                                    self.tipAssignment.tip.tipType == TipTypeNormal ? @"tip" : @"game",
                                                    self.tipAssignment.tip.titleForCurrentBaby, self.tipAssignment.tip.shortDescriptionForCurrentBaby];
    NSURL *url = [NSURL URLWithString:@"http://www.dataparenting.com"];
    NSArray *items = @[mainText, url];
    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    [controller setValue:@"Cool baby tip I found on DataParenting." forKey:@"subject"];
    controller.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypePostToVimeo];
//    [controller setCompletionHandler:^(NSString *activityType, BOOL completed) {
//
//    }];
    [self presentViewController:controller animated:YES completion:nil];
}

@end
