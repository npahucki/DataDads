//
//  UITextDateTextField.h
//  Milestones
//
//  Created by Nathan  Pahucki on 5/9/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDateField : UITextField

@property (readonly) NSDateFormatter * dateFormatter;
@property (strong, nonatomic) NSDate * date;
@property NSDate * maximumDate;
@property NSDate * minimumDate;

@end
