//
//  NSMutableArray+MultiDimensional.h
//  HearingAid
//
//  Created by Hai Le on 24/4/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (MultiDimensional)

+ (NSMutableArray*)arrayOfRow:(NSInteger)row andColumn:(NSInteger)col;
- (id)initWithRow:(NSInteger)row andColumn:(NSInteger)col;

- (id)getObjectAtRow:(int)row andColumn:(int)column;
- (void)setObject:(id)anObject atRow:(int)row andColumn:(int)column;

@end
