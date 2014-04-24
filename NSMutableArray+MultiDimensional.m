//
//  NSMutableArray+MultiDimensional.m
//  HearingAid
//
//  Created by Hai Le on 24/4/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import "NSMutableArray+MultiDimensional.h"

@implementation NSMutableArray (MultiDimensional)

+ (NSMutableArray*)arrayOfRow:(NSInteger)row andColumn:(NSInteger)col {
    return [[self alloc] initWithRow:row andColumn:col];
}

- (id)initWithRow:(NSInteger)row andColumn:(NSInteger)col {
    if((self = [self initWithCapacity:row])) {
        for(int i = 0; i < row; i++) {
            NSMutableArray *inner = [NSMutableArray arrayWithCapacity:col];
            for(int j = 0; j < col; j++)
                [inner addObject:[NSNull null]];
            [self addObject:inner];
        }
    }
    return self;
}

- (id)getObjectAtRow:(int)row andColumn:(int)column {
    NSMutableArray *inner = [self objectAtIndex:row];
    return [inner objectAtIndex:column];
}

- (void)setObject:(id)anObject atRow:(int)row andColumn:(int)column {
    NSMutableArray *inner = [self objectAtIndex:row];
    [inner replaceObjectAtIndex:column withObject:anObject];
}

@end
