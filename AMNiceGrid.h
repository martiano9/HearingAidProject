//
//  AMNiceGrid.h
//  HearingAid
//
//  Created by Hai Le on 9/4/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AMNiceScale;

@interface AMNiceGrid : UIView {

    int _width;
    int _height;
    int _gridWidth;
    int _gridHeight;
    
    float _bottom;
    
    AMNiceScale* _xScale;
}

- (id)initWithFrame:(CGRect)frame gridSize:(CGSize)grid smallGrid:(int)smallGrids;
- (id)initWithFrame:(CGRect)frame hScale:(AMNiceScale*)hScale vScale:(AMNiceScale*)vScale bPadding:(float)bPadding;

@end
