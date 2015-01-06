//
//  CirclePictureTableViewCell.h
//  DataParenting
//
//  Created by Nathan  Pahucki on 1/6/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#import "SWTableViewCell.h"

/// A table cell with a picture and a circle arround it and optionally lines extending up and down to connect the circles.

@interface CirclePictureTableViewCell : SWTableViewCell

@property(weak, nonatomic) IBOutlet UIImageView *pictureView;
@property BOOL topLineHidden;
@property BOOL bottomLineHidden;

@end
