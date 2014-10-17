//
//  InAppPurchaseAlertView.h
//  DataParenting
//
//  Created by Nathan  Pahucki on 10/16/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum _InAppPurchaseChoice : NSUInteger {
    InAppPurchaseChoiceCancel = 0,
    InAppPurchaseChoicePurchase,
    InAppPurchaseChoiceRestore
} InAppPurchaseChoice;

typedef void (^InAppPurchaseChoiceBlock)(InAppPurchaseChoice choice);


@interface InAppPurchaseAlertView : UIView

@property(weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property(weak, nonatomic) IBOutlet UIImageView *progressImageView;
@property(strong, nonatomic) SKProduct *product;

- (void)showWithBlock:(InAppPurchaseChoiceBlock)choiceBlock;

- (void)close;
@end
