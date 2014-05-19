//
//  DataPlot.h
//  HearingAid
//
//  Created by Hai Le on 18/5/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FrameAccessor/FrameAccessor.h>

@interface DataPlot : UIView {
    float _maxValue;
    int _samplesPerPixel;
}

@property (nonatomic)               float           *data;
@property (nonatomic)               float           *peaks;
@property (nonatomic, readonly)     int             samples;
@property (nonatomic, strong)       UIColor         *lineColor;
@property (nonatomic, assign)       BOOL            animated;
@property (nonatomic, assign)       CFTimeInterval  animationDuration;
@property (nonatomic, assign)       CGFloat         lineWidth;

- (void)setData:(float *)data peaks:(float*)peaks frames:(int)frames;
- (void)draw;

@end
