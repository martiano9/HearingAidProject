//
//  AMNiceScale.h
//  HearingAid
//
//  Created by Hai Le on 9/4/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AMNiceScale : NSObject

@property (nonatomic, readonly) CGFloat minPoint;
@property (nonatomic, readonly) CGFloat maxPoint;
@property (nonatomic, readonly) CGFloat maxTicks;
@property (nonatomic, readonly) CGFloat tickSpacing;
@property (nonatomic, readonly) CGFloat range;
@property (nonatomic, readonly) CGFloat niceRange;
@property (nonatomic, readonly) CGFloat niceMin;
@property (nonatomic, readonly) CGFloat niceMax;


- (id)initWithMin:(CGFloat)min andMax:(CGFloat)max;
- (id)initWithNSMin:(NSDecimalNumber*)min andNSMax:(NSDecimalNumber*)max;

@end
