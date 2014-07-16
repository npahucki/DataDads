//
//  UITextDateTextField.m
//  Milestones
//
//  Created by Nathan  Pahucki on 5/9/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "UIDateField.h"


@implementation UIDateField {
    NSDate *_date;                 // Need to be able to store a full date, and DatePicker seems to erase the time part of the date
    UIDatePicker *_picker;
}

// Global for all instances
NSDateFormatter *s_dateFormatter;

+ (void)initialize {
    s_dateFormatter = [[NSDateFormatter alloc] init];
    s_dateFormatter.timeZone = [NSTimeZone localTimeZone];
    [s_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [s_dateFormatter setDoesRelativeDateFormatting:YES];
}

- (void)awakeFromNib {
    _date = [NSDate date];
    _dateFormatter = s_dateFormatter;
    self.text = [_dateFormatter stringFromDate:_date];

    _picker = [[UIDatePicker alloc] init];
    _picker.date = _date;
    _picker.datePickerMode = UIDatePickerModeDate;
    _picker.timeZone = [NSTimeZone localTimeZone];
    _picker.maximumDate = _picker.date; // default
    [_picker addTarget:self action:@selector(pickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    UIToolbar *datePickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, _picker.frame.size.width, 50)];
    datePickerToolbar.items = @[
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
            [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(doneWithDatePicker)]
    ];
    [datePickerToolbar sizeToFit];
    self.inputView = _picker;

    self.inputAccessoryView = datePickerToolbar;
    [super awakeFromNib];

}

- (void)pickerValueChanged:(id)sender {
    _date = ((UIDatePicker *) sender).date;
    self.text = [_dateFormatter stringFromDate:_date];
}

- (void)doneWithDatePicker {
    [self resignFirstResponder];
}

- (void)setDate:(NSDate *)date {
    UIDatePicker *picker = ((UIDatePicker *) self.inputView);
    _date = date;
    picker.date = _date;
    self.text = [_dateFormatter stringFromDate:_date];
}

- (NSDate *)date {
    return _date;
}

- (NSDate *)maximumDate {
    return _picker.maximumDate;
}

- (void)setMaximumDate:(NSDate *)maximumDate {
    _picker.maximumDate = maximumDate;
}

- (NSDate *)minimumDate {
    return _picker.minimumDate;
}

- (void)setMinimumDate:(NSDate *)minimumDate {
    _picker.minimumDate = minimumDate;
}


@end
