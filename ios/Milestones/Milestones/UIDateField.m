//
//  UITextDateTextField.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/9/14.
//  Copyright (c) 2014 Nathan  Pahucki. All rights reserved.
//

#import "UIDateField.h"



@implementation UIDateField

// Global for all instances
NSDateFormatter * _dateFormatter;

-(void) awakeFromNib {

  if(!_dateFormatter) {
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [_dateFormatter setDoesRelativeDateFormatting:YES];
  }

  _picker = [[UIDatePicker alloc]init];
  _picker.datePickerMode = UIDatePickerModeDate;
  _picker.date = [NSDate date];
  _picker.maximumDate = _picker.date; // default
  [_picker addTarget:self action:@selector(updateTextField:) forControlEvents:UIControlEventValueChanged];
  UIToolbar* datePickerToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, _picker.frame.size.width, 50)];
  datePickerToolbar.items = @[
                              [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                              [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(doneWithDatePicker)]
                              ];
  [datePickerToolbar sizeToFit];
  self.inputView = _picker;
  self.inputAccessoryView = datePickerToolbar;
  [self updateTextField:_picker];
  [super awakeFromNib];
  
}



-(void) updateTextField: (id) sender {
  self.text = [_dateFormatter stringFromDate:((UIDatePicker*) sender).date];
}

-(void) doneWithDatePicker {
  [self resignFirstResponder];
}

-(void) setDate:(NSDate*) date {
  ((UIDatePicker*)self.inputView).date = date;
  [self updateTextField:self.inputView];
}

-(NSDate*) date {
  return ((UIDatePicker*)self.inputView).date;
}



@end
