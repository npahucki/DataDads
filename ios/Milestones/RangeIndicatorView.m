//
//  RangeIndicatorView.m
//  DataParenting
//
//  Created by Nathan  Pahucki on 6/25/14.
//  Copyright (c) 2014 DataParenting. All rights reserved.
//

#import "RangeIndicatorView.h"

#define DEGREES_TO_RADIANS(degrees)  (( M_PI * degrees) / 180)

#define SELECTED_BORDER_COLOR [UIColor appSelectedColor].CGColor
#define SELECTED_FILL_COLOR [UIColor appNormalColor].CGColor
#define BORDER_COLOR [UIColor appGreyTextColor].CGColor
#define BORDER_WITDH 3

@interface PieSliceLayer : CALayer
@property (nonatomic) CGFloat startAngle;
@property (nonatomic) CGFloat endAngle;
@end

@implementation PieSliceLayer

@dynamic startAngle, endAngle;

-(CABasicAnimation *)makeAnimationForKey:(NSString *)key {
	CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:key];
	anim.fromValue = [[self presentationLayer] valueForKey:key];
	anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
	anim.duration = .5;
  
	return anim;
}

-(id<CAAction>)actionForKey:(NSString *)event {
  if ([event isEqualToString:@"startAngle"] ||
      [event isEqualToString:@"endAngle"]) {
    return [self makeAnimationForKey:event];
  }
  
  return [super actionForKey:event];
}

- (id)init {
  self = [super init];
  if (self) {
		[self setNeedsDisplay];
  }
  return self;
}

- (id)initWithLayer:(id)layer {
  if (self = [super initWithLayer:layer]) {
    if ([layer isKindOfClass:[PieSliceLayer class]]) {
      PieSliceLayer *other = (PieSliceLayer *)layer;
      self.startAngle = other.startAngle;
      self.endAngle = other.endAngle;
    }
  }
  
  return self;
}

+ (BOOL)needsDisplayForKey:(NSString *)key {
  if ([key isEqualToString:@"startAngle"] || [key isEqualToString:@"endAngle"]) {
    return YES;
  }
  
  return [super needsDisplayForKey:key];
}

-(void)drawInContext:(CGContextRef)ctx {
  
  // Create the path
  CGPoint center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
  CGFloat radius = MIN(center.x, center.y);
  
  CGContextBeginPath(ctx);
  CGContextMoveToPoint(ctx, center.x, center.y);
  
  //CGPoint p1 = CGPointMake(center.x + radius * cosf(self.startAngle), center.y + radius * sinf(self.startAngle));
  ///CGContextAddLineToPoint(ctx, p1.x, p1.y);
  
  int clockwise = self.startAngle > self.endAngle;
  CGContextAddArc(ctx, center.x, center.y, radius - BORDER_WITDH, self.startAngle, self.endAngle, clockwise);
  
  CGContextClosePath(ctx);
  
  // Color it
  CGContextSetFillColorWithColor(ctx, SELECTED_FILL_COLOR);
  CGContextSetStrokeColorWithColor(ctx, SELECTED_BORDER_COLOR);
  CGContextSetLineWidth(ctx, BORDER_WITDH);
  
  CGContextDrawPath(ctx, kCGPathFillStroke);
}

@end



@implementation RangeIndicatorView {
  PieSliceLayer * _shapeLayer;
  NSInteger _startRange;
  NSInteger _endRange;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
  
    if (self) {
      _shapeLayer = [[PieSliceLayer alloc] init];
      _shapeLayer.frame = self.bounds;
      _shapeLayer.contentsScale = [[UIScreen mainScreen] scale];
      [self.layer addSublayer:_shapeLayer];
    }
    return self;
}

-(NSInteger) startRange {
  return _startRange;
}
-(NSInteger) endRange {
  return _endRange;
}

-(void) setStartRange:(NSInteger)startRange {
  NSAssert(_rangeScale > 0,@"Expected rangeScale to be set first!");
  NSAssert(startRange >= 0,@"startRange(%d) must be greater than 0", startRange);
  _startRange = startRange;
  
  // Get ratio of start range to max
  float ratio = (float)_startRange / (float) _rangeScale;
  _shapeLayer.startAngle = (2 * M_PI * ratio) - M_PI / 2; // Quarter turn left
}

-(void) setEndRange:(NSInteger)endRange {
  NSAssert(_rangeScale > 0,@"Expected rangeScale to be set first!");
  NSAssert(endRange <= _rangeScale,@"endRange(%d) can not be greater than rangeScale(%d)", endRange, _rangeScale);
  _endRange = endRange;
  float ratio = (float)endRange / (float) _rangeScale;
  _shapeLayer.endAngle = (2 * M_PI * ratio) - M_PI / 2; // Quarter turn left
}

-(void)willMoveToSuperview:(UIView *)newSuperview {
  _shapeLayer.frame = self.bounds;
	
  CAShapeLayer *circleLayer = [CAShapeLayer layer];
	circleLayer.path = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(self.bounds,BORDER_WITDH,BORDER_WITDH)].CGPath;
	circleLayer.fillColor = [UIColor clearColor].CGColor;
  circleLayer.strokeColor = BORDER_COLOR;
  circleLayer.lineWidth = BORDER_WITDH;
	[self.layer insertSublayer:circleLayer below:_shapeLayer];
}


@end
