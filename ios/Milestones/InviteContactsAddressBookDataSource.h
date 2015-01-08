//
// Created by Nathan  Pahucki on 1/8/15.
// Copyright (c) 2015 DataParenting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MBContactPicker/MBContactModel.h>
#import <MBContactPicker/MBContactPicker.h>

@interface InviteContact : NSObject <MBContactPickerModelProtocol>

@property(nonatomic, retain) NSString *fullName;
@property(nonatomic, retain) NSString *emailAddress;
@property(nonatomic, retain) UIImage *image;

@end

@interface InviteContactsAddressBookDataSource : NSObject <MBContactPickerDataSource>

@end