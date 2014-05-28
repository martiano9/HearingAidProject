//
//  FilterBank.h
//  HearingAid
//
//  Created by Hai Le on 19/3/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Dsp.h"
#import "Filter.h"

@class FDWaveformView;
@class AMDataPlot;
@protocol FilterBankDelegate;

@interface FilterBank : NSObject {
    Dsp::Filter *_filter;
    Dsp::Filter *_lpFilter;
    float* _originalData;
    
    float* _filteredData;
    float* _filteredData16;
    float* _autocorrData;
    
    NSURL* _fileURL;
}

@property (nonatomic) int frames;
@property (nonatomic, weak) id<FilterBankDelegate> delegate;


- (id)initWithFrames:(int)frames filterType:(int)bankIndex data:(float*)data;
- (void)process;
//- (void)processToStep:(int)step;
//- (float)getNumberOfFrames;
//- (float*)getNumberSoundData;

- (float)getSampleRate;
- (int)getFrames;
- (float*)getAutocorrData;

@end

@protocol FilterBankDelegate <NSObject>
@optional
- (void)didFinishCalculateData;
@end
