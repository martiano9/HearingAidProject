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

@interface FilterBank : NSObject {
    Dsp::Filter *_filter;
    float** _originalData;
    
    float** _filteredData;
    float** _filteredData16;
    float** _atom;
    NSURL* _fileURL;
    
    float _atomReducedTime;
    int _stepToProceed;
}

@property (nonatomic) UInt32 numberOfChannels;
@property (nonatomic) float frames;
@property (nonatomic, weak) FDWaveformView* waveFormView;
@property (nonatomic, weak) AMDataPlot* waveFormDataView;


- (id)initWithFrames:(float)frames Channels:(UInt32)channels FilterType:(int)bankIndex Data:(float**)data;
- (void)processToStep:(int)step;
- (float)getNumberOfFrames;
- (float**)getNumberSoundData;

@end
