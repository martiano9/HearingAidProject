//
//  AMNiceScale.m
//  HearingAid
//
//  Created by Hai Le on 9/4/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import "AMNiceScale.h"

@implementation AMNiceScale

@synthesize minPoint = _minPoint;
@synthesize maxPoint = _maxPoint;
@synthesize maxTicks = _maxTicks;
@synthesize tickSpacing = _tickSpacing;
@synthesize range = _range;
@synthesize niceRange = _niceRange;
@synthesize niceMin = _niceMin;
@synthesize niceMax = _niceMax;

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (id) initWithMin: (CGFloat) min andMax: (CGFloat) max {
    
    if (self) {
        _maxTicks = 10;
        _minPoint = min;
        _maxPoint = max;
        [self calculate];
    }
    return [self init];
}

- (id) initWithNSMin: (NSDecimalNumber*) min andNSMax: (NSDecimalNumber*) max {
    
    if (self) {
        _maxTicks = 10;
        _minPoint = [min doubleValue];
        _maxPoint = [max doubleValue];
        [self calculate];
    }
    return [self init];
}


/**
 * Calculate and update values for tick spacing and nice minimum and maximum
 * data points on the axis.
 */

- (void) calculate {
    _range = [self niceNumRange: (_maxPoint-_minPoint) roundResult:NO];
    _tickSpacing = [self niceNumRange: (_range / (_maxTicks - 1)) roundResult:YES];
    _niceMin = floor(_minPoint / _tickSpacing) * _tickSpacing;
    _niceMax = ceil(_maxPoint / _tickSpacing) * _tickSpacing;
    
    _niceRange = _niceMax - _niceMin;
}


/**
 * Returns a "nice" number approximately equal to range Rounds the number if
 * round = true Takes the ceiling if round = false.
 *
 * @param range
 *            the data range
 * @param round
 *            whether to round the result
 * @return a "nice" number to be used for the data range
 */
- (CGFloat) niceNumRange:(CGFloat) aRange roundResult:(BOOL) round {
    CGFloat exponent;
    CGFloat fraction;
    CGFloat niceFraction;
    
    exponent = floor(log10(aRange));
    fraction = aRange / pow(10, exponent);
    
    if (round) {
        if (fraction < 1.5) {
            niceFraction = 1;
        } else if (fraction < 3) {
            niceFraction = 2;
        } else if (fraction < 7) {
            niceFraction = 5;
        } else {
            niceFraction = 10;
        }
        
    } else {
        if (fraction <= 1) {
            niceFraction = 1;
        } else if (fraction <= 2) {
            niceFraction = 2;
        } else if (fraction <= 5) {
            niceFraction = 2;
        } else {
            niceFraction = 10;
        }
    }
    
    return niceFraction * pow(10, exponent);
}

- (NSString*) description {
    return [NSString stringWithFormat:@"NiceScale [minPoint=%.10f, maxPoint=%.10f, maxTicks=%.10f, tickSpacing=%.10f, range=%.10f, niceMin=%.10f, niceMax=%.10f]", _minPoint, _maxPoint, _maxTicks, _tickSpacing, _range, _niceMin, _niceMax ];
}

@end
