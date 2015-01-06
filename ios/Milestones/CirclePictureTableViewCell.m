//
//  CirclePictureTableViewCell.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 1/6/15.
//  Copyright (c) 2015 DataParenting. All rights reserved.
//

#define CIRCLE_OFFSET 8
#define CIRCLE_COLOR [UIColor appGreyTextColor]
#import "CirclePictureTableViewCell.h"


@implementation CirclePictureTableViewCell {
    UIView *_topLineView;
    UIView *_bottomLineView;
    UIView *_circleView;
}

+ (void)initialize {
    [[UIButton appearanceWhenContainedIn:[SWTableViewCell class], nil] setTitleColor:[UIColor appInputGreyTextColor] forState:UIControlStateNormal];
    [UILabel appearanceWhenContainedIn:[SWTableViewCell class], nil].font = [UIFont fontForAppWithType:Medium andSize:14];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.pictureView.layer.cornerRadius = self.pictureView.bounds.size.width / 2;
    
    _circleView.frame = CGRectInset(self.pictureView.frame, -CIRCLE_OFFSET, -CIRCLE_OFFSET);
    _circleView.layer.cornerRadius = _circleView.frame.size.width / 2;
    _topLineView.frame = CGRectMake(_circleView.frame.origin.x + _circleView.frame.size.width / 2, 0, 1, _circleView.frame.origin.y + 1);
    _bottomLineView.frame = CGRectMake(_circleView.frame.origin.x + _circleView.frame.size.width / 2, (_circleView.frame.origin.y + _circleView.frame.size.height) - 1, 1, (self.frame.size.height - (_circleView.frame.origin.y + _circleView.frame.size.height)) + 1);
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.imageView.hidden = YES;
    self.textLabel.hidden = YES;
    self.detailTextLabel.hidden = YES;
    
    
    self.pictureView.layer.masksToBounds = YES;
    
    _circleView = [[UIView alloc] initWithFrame:CGRectZero];
    _circleView.layer.borderColor = CIRCLE_COLOR.CGColor;
    _circleView.layer.borderWidth = 1;
    [self.contentView addSubview:_circleView];
    
    _topLineView = [[UIView alloc] initWithFrame:CGRectZero];
    _topLineView.backgroundColor = CIRCLE_COLOR;
    [self.contentView addSubview:_topLineView];
    
    _bottomLineView = [[UIView alloc] initWithFrame:CGRectZero];
    _bottomLineView.backgroundColor = CIRCLE_COLOR;
    [self.contentView addSubview:_bottomLineView];
}

- (void)setTopLineHidden:(BOOL)topLineHidden {
    _topLineView.hidden = topLineHidden;
}

- (BOOL)topLineHidden {
    return _topLineView.hidden;
}

- (void)setBottomLineHidden:(BOOL)bottomLineHidden {
    _bottomLineView.hidden = bottomLineHidden;
}

- (BOOL)bottomLineHidden {
    return _bottomLineView.hidden;
}

@end

