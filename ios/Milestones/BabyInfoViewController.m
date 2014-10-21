//
//  BabyInfoViewController.m
//  Milestones
//
//  Created by Nathan  Pahucki on 1/21/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "BabyInfoViewController.h"
#import "NSDate+Utils.h"
#import "Mixpanel/MPTweakInline.h"

#define MIN_DUE_BEFORE -60
#define MAX_DUE_AFTER 21


@interface BabyInfoViewController ()

@end

@implementation BabyInfoViewController {
    BOOL _dueDateDirty;
}


- (void)viewDidLoad {
    BOOL willShowOptionalSignup = ![ParentUser currentUser].isAuthenticated && MPTweakValue(@"ShowOptionalSignupDuringOnBoarding", NO);
    self.totalSteps = willShowOptionalSignup ? 4 : 3;
    self.currentStepNumber = 1;

    [super viewDidLoad];
    self.maleLabel.highlightedTextColor = self.femaleLabel.highlightedTextColor = [UIColor appNormalColor];
    self.maleLabel.font = self.femaleLabel.font = [UIFont fontForAppWithType:Bold andSize:17];
    self.maleLabel.textColor = self.femaleLabel.textColor = [UIColor appInputGreyTextColor];

    // Needed to dimiss the keyboard once a user clicks outside the text boxes
    UITapGestureRecognizer *viewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.view addGestureRecognizer:viewTap];
    self.babyName.delegate = self;
    self.dobTextField.maximumDate = [NSDate date];

    if (self.baby) {
        self.babyName.text = self.baby.name;
        self.dobTextField.date = self.baby.birthDate;
        self.dueDateTextField.date = self.baby.dueDate;
        if (self.baby.isMale)
            [self didClickMaleButton:self];
        else
            [self didClickFemaleButton:self];

    } else {
        self.baby = [Baby object];
    }
}

- (void)handleSingleTap:(UITapGestureRecognizer *)sender {
    [self.view endEditing:NO];
}

- (IBAction)didClickMaleButton:(id)sender {
    [self.view endEditing:NO];
    self.maleButton.selected = YES;
    self.maleLabel.highlighted = YES;
    self.femaleButton.selected = NO;
    self.femaleLabel.highlighted = NO;
    [self updateNextButtonState];
}

- (IBAction)didClickFemaleButton:(id)sender {
    [self.view endEditing:NO];
    self.femaleButton.selected = YES;
    self.femaleLabel.highlighted = YES;
    self.maleButton.selected = NO;
    self.maleLabel.highlighted = NO;
    [self updateNextButtonState];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)didChangeBabyName:(id)sender {
    [self updateNextButtonState];
    NSString * name = self.babyName.text.length ? self.babyName.text : @"Your baby";
    self.birthDateLabel.text = [NSString stringWithFormat:@"%@ was born on:", name];
    self.dueDateLabel.text = [NSString stringWithFormat:@"%@ was due on:", name];
    self.genderLabel.text = [NSString stringWithFormat:@"%@ is a:", name];
}


- (void)textFieldEditingDidEnd:(UITextField *)sender {
    if (sender == self.dueDateTextField) _dueDateDirty = YES;

    if (sender == self.dobTextField) {
        self.dueDateTextField.maximumDate = [self.dobTextField.date dateByAddingDays:MAX_DUE_AFTER];
        self.dueDateTextField.minimumDate = [self.dobTextField.date dateByAddingDays:MIN_DUE_BEFORE];
        if (!_dueDateDirty)
            self.dueDateTextField.date = self.dobTextField.date;
    }
    [self updateNextButtonState];
}

- (void)updateNextButtonState {
    self.nextButton.enabled = self.dueDateTextField.text.length && self.dobTextField.text.length && self.babyName.text.length > 1 && (self.maleButton.isSelected || self.femaleButton.isSelected);
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    self.baby.name = self.babyName.text;
    self.baby.isMale = self.maleButton.isSelected;
    self.baby.birthDate = ((UIDatePicker *) self.dobTextField.inputView).date;
    self.baby.dueDate = ((UIDatePicker *) self.dueDateTextField.inputView).date;
    [super prepareForSegue:segue sender:sender];
}

- (IBAction)didClickCancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
