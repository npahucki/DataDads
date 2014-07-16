//
//  HIstoryTableHeaderView.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 6/26/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "HistoryTableHeaderView.h"

@implementation HistoryTableHeaderView {
    BOOL _highlighted;
    NSInteger _position;
    NSInteger _count;
    UILabel *_countLabel;
    UILabel *_titleLabel;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

        self.opaque = YES;
        self.backgroundColor = [UIColor appHeaderBackgroundActiveColor];
        self.layer.borderColor = [UIColor appHeaderBorderNormalColor].CGColor;
        self.layer.borderWidth = 1;

        _countLabel = [[UILabel alloc] init];
        _countLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _countLabel.font = [UIFont fontForAppWithType:Medium andSize:10];
        _countLabel.clipsToBounds = YES;
        _countLabel.textAlignment = NSTextAlignmentCenter;
        _countLabel.layer.borderColor = [UIColor appHeaderBorderNormalColor].CGColor;

        [self addSubview:_countLabel];
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.font = [UIFont fontForAppWithType:Medium andSize:13];
        [self addSubview:_titleLabel];

        [_countLabel addConstraints:@[[NSLayoutConstraint constraintWithItem:_countLabel
                                                                   attribute:NSLayoutAttributeWidth
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:_countLabel
                                                                   attribute:NSLayoutAttributeHeight
                                                                  multiplier:1.0
                                                                    constant:0],
        ]];


        [self addConstraints:@[[NSLayoutConstraint constraintWithItem:_countLabel
                                                            attribute:NSLayoutAttributeCenterY
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self
                                                            attribute:NSLayoutAttributeCenterY
                                                           multiplier:1.0
                                                             constant:0.0],
                [NSLayoutConstraint constraintWithItem:_countLabel
                                             attribute:NSLayoutAttributeLeading
                                             relatedBy:NSLayoutRelationEqual
                                                toItem:self
                                             attribute:NSLayoutAttributeLeft
                                            multiplier:1.0
                                              constant:8.0],
                [NSLayoutConstraint constraintWithItem:_countLabel
                                             attribute:NSLayoutAttributeHeight
                                             relatedBy:NSLayoutRelationEqual
                                                toItem:self
                                             attribute:NSLayoutAttributeHeight
                                            multiplier:1.0
                                              constant:-16],
                [NSLayoutConstraint constraintWithItem:_titleLabel
                                             attribute:NSLayoutAttributeCenterY
                                             relatedBy:NSLayoutRelationEqual
                                                toItem:self
                                             attribute:NSLayoutAttributeCenterY
                                            multiplier:1.0
                                              constant:0.0],
                [NSLayoutConstraint constraintWithItem:_titleLabel
                                             attribute:NSLayoutAttributeLeading
                                             relatedBy:NSLayoutRelationEqual
                                                toItem:_countLabel
                                             attribute:NSLayoutAttributeRight
                                            multiplier:1.0
                                              constant:8.0]
        ]];
    }

    [self setHighlighted:YES];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _countLabel.layer.cornerRadius = _countLabel.bounds.size.width / 2;

}

- (void)setHighlighted:(BOOL)highlighted {
    if (highlighted != _highlighted) {
        _highlighted = highlighted;

        if (highlighted) {
            _countLabel.textColor = [UIColor appHeaderCounterActiveTextColor];
            _countLabel.backgroundColor = [UIColor appHeaderCounterBackgroundActiveColor];
            _countLabel.layer.borderWidth = 0;
            _titleLabel.textColor = [UIColor appHeaderActiveTextColor];
        } else {
            _countLabel.textColor = [UIColor appHeaderCounterNormalTextColor];
            _countLabel.backgroundColor = [UIColor clearColor];
            _countLabel.layer.borderWidth = 1;
            _titleLabel.textColor = [UIColor appHeaderNormalTextColor];

        }
    }
}

- (BOOL)highlighted {
    return _highlighted;
}

- (void)setPosition:(NSInteger)position {
    if (_position != position) {
        _position = position;
        self.frame = CGRectMake(0, position, self.bounds.size.width, self.bounds.size.height);
    }
}

- (NSInteger)position {
    return _position;
}

- (void)setTitle:(NSString *)title {
    _titleLabel.text = title;
    [_titleLabel sizeToFit];
}

- (NSString *)title {
    return _titleLabel.text;
}

- (void)setCount:(NSInteger)count {
    _count = count;
    _countLabel.text = [NSString stringWithFormat:@"%ld", (long) count];
    [_countLabel sizeToFit];
    [self setNeedsLayout];
}

- (NSInteger)count {
    return _count;
}


@end



