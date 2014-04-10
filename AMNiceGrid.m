//
//  AMNiceGrid.m
//  HearingAid
//
//  Created by Hai Le on 9/4/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import "AMNiceGrid.h"
#import "AMNiceScale.h"

@implementation AMNiceGrid

int grids = 2;

- (id)initWithFrame:(CGRect)frame gridSize:(CGSize)grid smallGrid:(int)smallGrids {
    self = [super initWithFrame:frame];
    if (self) {
        _gridHeight = grid.height;
        _gridWidth = grid.width;
        _height = frame.size.height;
        _width = frame.size.width;
        [self setNeedsDisplay];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame hScale:(AMNiceScale*)hScale vScale:(AMNiceScale*)vScale bPadding:(float)bPadding{
    self = [self initWithFrame:frame];
    if (self) {
        int numberOfHorizontalGrid = hScale.niceRange/hScale.tickSpacing * grids;
        _gridWidth = frame.size.width / numberOfHorizontalGrid;
        _width = frame.size.width;
        
   
        _height = frame.size.height;
        
        _xScale = hScale;
        _bottom = bPadding;
        
        [self setNeedsDisplay];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect]; 
    [self drawGrid:UIGraphicsGetCurrentContext()];
}

- (void)drawGrid:(CGContextRef)ctx {
    // Setup variables
    float bottomLine = _height - _bottom;
    float number = _xScale.minPoint + _xScale.tickSpacing;
    
    // Enable Antilaiasing to draw small line
    CGContextSetAllowsAntialiasing(ctx, YES);
    CGContextSetShouldAntialias(ctx, YES);
    
    // Draw big vertical lines
	CGContextSetLineWidth(ctx, 0.4);
	CGContextSetStrokeColorWithColor(ctx, [UIColor greenColor].CGColor);
    
	int pos_x = 0;
    
	while (pos_x < _width) {
		CGContextMoveToPoint(ctx, pos_x, 1);
		CGContextAddLineToPoint(ctx, pos_x, bottomLine);
		pos_x += (_gridWidth*grids);
		
		CGContextStrokePath(ctx);
        
        // Draw textc
        CGRect drawRect = CGRectMake(pos_x-10, bottomLine+2, 20, 10);
        NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        textStyle.lineBreakMode = NSLineBreakByWordWrapping;
        textStyle.alignment = NSTextAlignmentCenter;
        UIFont *textFont = [UIFont systemFontOfSize:10];
        
        NSString *text = [NSString stringWithFormat:@"%.0f",number ];
        
        // iOS 7 way
        [text drawInRect:drawRect withAttributes:@{NSFontAttributeName:textFont, NSParagraphStyleAttributeName:textStyle, NSForegroundColorAttributeName: [UIColor greenColor]}];
        number+= _xScale.tickSpacing;
	}
	
    // Draw small vertical lines
    CGContextSetLineWidth(ctx, 0.2);
	pos_x = _gridWidth;
	while (pos_x < _width) {
		CGContextMoveToPoint(ctx, pos_x, 1);
		CGContextAddLineToPoint(ctx, pos_x, bottomLine);
		pos_x += _gridWidth;
		
		CGContextStrokePath(ctx);
	}
    
    // Draw y axis
    CGContextSetLineWidth(ctx, 0.4);
	CGContextSetStrokeColorWithColor(ctx, [UIColor greenColor].CGColor);
    CGPoint points[2] = {
                            CGPointMake(0, bottomLine),
                            CGPointMake(_width, bottomLine)
                        };
    CGContextStrokeLineSegments(ctx, points, 2);

    
}


@end
