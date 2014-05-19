//
//  DataPlot.m
//  HearingAid
//
//  Created by Hai Le on 18/5/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import "DataPlot.h"
#import <GraphKit/UIColor+GraphKit.h>

static CGFloat kDefaultMarginBottom = 10.0;

@implementation DataPlot

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self _init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self _init];
    }
    return self;
}

- (void)_init
{
    self.animated = YES;
    self.animationDuration = 1;
    self.lineWidth = 1;
    self.lineColor = [UIColor gk_sunflowerColor];
    self.backgroundColor = [UIColor gk_midnightBlueColor];
    self.clipsToBounds = YES;

}

- (void)setData:(float *)data peaks:(float*)peaks frames:(int)frames {
    _data = data;
    _samples = frames;
    _peaks = peaks;
    // Find max value from data array
    _maxValue = 0.0;
    for (int i = 0; i < frames; i++) {
        if (_data[i] > _maxValue) {
            _maxValue = data[i];
        }
    }
}

- (void)draw {
    self.layer.sublayers = nil;
    // http://stackoverflow.com/questions/19599266/invalid-context-0x0-under-ios-7-0-and-system-degradation
    UIGraphicsBeginImageContext(self.frame.size);
    
    UIBezierPath *path = [self _bezierPathWith:0];
    CAShapeLayer *layer = [self _layerWithPath:path];
    
    layer.strokeColor = [self.lineColor CGColor];
    
    [self.layer addSublayer:layer];
    
    _samplesPerPixel = _samples/self.width;
    
    for (int i = 0; i<= self.width; i++) {
        CGFloat x = i;
        CGFloat y = [self _pointYForIndex:i];
        CGPoint point = CGPointMake(x, y);
        if (i != 0) [path addLineToPoint:point];
        if ([self _peakForIndex:i]) {
            [path addArcWithCenter:point radius:2 startAngle:0 endAngle:2*M_PI clockwise:YES];
            [path fill];
        }
        [path moveToPoint:point];
    }
    
    layer.path = path.CGPath;
    
    if (self.animated) {
        CABasicAnimation *animation = [self _animationWithKeyPath:@"strokeEnd"];
        animation.duration = 1;
        
        [layer addAnimation:animation forKey:@"strokeEndAnimation"];
    }
    
    UIGraphicsEndImageContext();
}

- (UIBezierPath *)_bezierPathWith:(CGFloat)value {
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineCapStyle = kCGLineCapRound;
    path.lineJoinStyle = kCGLineJoinRound;
    path.lineWidth = self.lineWidth;
    return path;
}

- (CAShapeLayer *)_layerWithPath:(UIBezierPath *)path {
    CAShapeLayer *item = [CAShapeLayer layer];
    item.fillColor = [[UIColor blackColor] CGColor];
    item.lineCap = kCALineCapRound;
    item.lineJoin  = kCALineJoinRound;
    item.lineWidth = self.lineWidth;
    //    item.strokeColor = [self.foregroundColor CGColor];
    item.strokeColor = [[UIColor redColor] CGColor];
    item.strokeEnd = 1;
    return item;
}

- (CABasicAnimation *)_animationWithKeyPath:(NSString *)keyPath {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:keyPath];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.duration = self.animationDuration;
    animation.fromValue = @(0);
    animation.toValue = @(1);
    //    animation.delegate = self;
    return animation;
}

- (CGFloat)_pointYForIndex:(NSInteger)index {
    long begin = index * _samplesPerPixel;
    long end   = (index + 1) * _samplesPerPixel;
    end = MIN(end, _samples);
    float average = 0.0;
    for (long i = begin; i < end; i++) {
        average += _data[i];
    }
    average = average / (end - begin);
    int height = self.height - kDefaultMarginBottom;
    return  height * (1 - (average/_maxValue));
}

- (BOOL)_peakForIndex:(NSInteger)index {
    long begin = index * _samplesPerPixel;
    long end   = (index + 1) * _samplesPerPixel;
    end = MIN(end, _samples);
    
    for (long i = begin; i < end; i++) {
        if(_peaks[i] > 0) return YES;
    }
    return NO;
}

@end
