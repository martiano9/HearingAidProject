//
//  FilterBank.m
//  HearingAid
//
//  Created by Hai Le on 19/3/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import "FilterBank.h"
#import "FDWaveformView.h"
#import "AMDataPlot.h"
#import "EAFUtilities.h"

#define AUTOCORR_SAMPLE_RATE 2756 // 44100/16
#define REDUCED_SAMPLE_RATE_TIME 16
#define SECONDS_TO_ANALYZE 5

@implementation FilterBank

@synthesize frames = _frames;

- (id)initWithFrames:(int)frames filterType:(int)bankIndex data:(float*)data
{
    self = [super init];
    if (self) {
        _frames = frames;
        _originalData = data;
        
        _atomReducedTime = 4;
    
        // Switch by bankIndex
        if (bankIndex == 1) {
            _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::LowPass<6>, 1> (1024);
            
            Dsp::Params params;
            params[0] = 44100;  // sample rate
            params[1] = 6;      // order
            params[2] = 200;    // cutoff frequency
            _filter->setParams (params);
        }
        if (bankIndex == 2) {
            _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::BandPass<6>, 1> (1024);
            
            Dsp::Params params;
            params[0] = 44100;  // sample rate
            params[1] = 6;      // order
            params[2] = 300;    // cutoff frequency
            params[3] = 100;    // band width
            _filter->setParams (params);
        }
        if (bankIndex == 3) {
            _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::BandPass<6>, 1> (1024);
            
            Dsp::Params params;
            params[0] = 44100;  // sample rate
            params[1] = 6;      // order
            params[2] = 600;    // cutoff frequency
            params[3] = 200;    // band width
            _filter->setParams (params);
        }
        if (bankIndex == 4) {
            _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::BandPass<6>, 1> (1024);
            
            Dsp::Params params;
            params[0] = 44100;  // sample rate
            params[1] = 6;      // order
            params[2] = 1200;    // cutoff frequency
            params[3] = 400;    // band width
            _filter->setParams (params);
        }
        if (bankIndex == 5) {
            _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::BandPass<6>, 1> (1024);
            
            Dsp::Params params;
            params[0] = 44100;  // sample rate
            params[1] = 6;      // order
            params[2] = 2400;    // cutoff frequency
            params[3] = 1200;    // band width
            _filter->setParams (params);
        }
        if (bankIndex == 6) {
            _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::HighPass<6>, 1> (1024);
            
            Dsp::Params params;
            params[0] = 44100;  // sample rate
            params[1] = 6;      // order
            params[2] = 3200;    // cutoff frequency
            _filter->setParams (params);
        }
        
        // Alloc filter array
        _filteredData = AllocateAudioBuffer(_frames);
        
        // Alloc low pass filter
        _lpFilter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::LowPass<6>, 1> (1024);
        
        Dsp::Params params;
        params[0] = 44100;  // sample rate
        params[1] = 6;      // order
        params[2] = 10;    // cutoff frequency
        _lpFilter->setParams (params);
        
        // Alloc low sample-rate array
        _filteredData16 = new float[_frames/REDUCED_SAMPLE_RATE_TIME];
    }
    return self;
}

- (void)process {
    // Step 1
    int frames16 = _frames/REDUCED_SAMPLE_RATE_TIME;
    
    ClearAudioBuffer(_filteredData, _frames);
    CopyAudioBuffer(_originalData, _filteredData, _frames);
    
    // Step 1
    _filter->process(_frames, &_filteredData);
    
    
    // Step 2
    for (int frame = 0; frame<_frames; frame++) {
        _filteredData[frame] = fabsf(_filteredData[frame]);
    }
    _lpFilter->reset();
    _lpFilter->process(_frames, &_filteredData);
    
    // Step 3
    ClearAudioBuffer(_filteredData16, frames16);
    for (int i = 1; i < frames16; i++) {
        float foo = _filteredData[i*REDUCED_SAMPLE_RATE_TIME]-_filteredData[(i-1)*REDUCED_SAMPLE_RATE_TIME];
        _filteredData16[i] = MAX(0,foo);
    }
    
    // Autocorrelation
    ClearAudioBuffer(_autocorrData, frames16);
    int size = AUTOCORR_SAMPLE_RATE * SECONDS_TO_ANALYZE;
    for (int m = 0; m < size; m++) {
        float sum = 0;
        for (int n = 0; n < size-m ; n++) {
            sum += (_filteredData16[n] * _filteredData16[n+m]);
        }
        _autocorrData[m] = sum;
    }
    
    [self.delegate didFinishCalculateData];
}

- (void)processToStep:(int)step {
    // Assing number of step
    _stepToProceed = step;
    
    if (_filteredData) {
        delete [] _filteredData;
        _filteredData = nil;
    }
    
    int frames16 = _frames/16;
    int size = frames16;
    
    // Copy data from original data
    float* buffer = new float[_frames];
    
    _filteredData = new float[_frames];
    memcpy(_filteredData, _originalData, (size_t)_frames * sizeof(float));
    
    // ================================================================
    // STEP 1:
    // ================================================================
    // Process filter
    _filter->process(_frames, &_filteredData);
    if (step==1) goto writeFile;
    
    // ================================================================
    // STEP 2:
    // ================================================================

    for (int frame = 0; frame<_frames; frame++) {
        _filteredData[frame] = fabsf(_filteredData[frame]);
    }
   
    _lpFilter->reset();
    _lpFilter->process(_frames, &_filteredData);
    
    if (step==2) goto writeFile;
    
    // ================================================================
    // STEP 3:
    // ================================================================
    memcpy(buffer, _filteredData, (size_t)_frames * sizeof(float));
    
    for (int frame = 1; frame<_frames; frame++) {
            float diff = MAX(0,buffer[frame] - buffer[frame-1]);
            _filteredData[frame] = diff;
    }

    // delete old data
    delete [] buffer;
    buffer = nil;
    
    if (step==3) goto writeFile;
    
    // ================================================================
    // STEP 4:
    // ================================================================
    if (_filteredData16) {
        delete [] _filteredData16;
        _filteredData16 = nil;
    }
    _filteredData16 = new float[frames16];
    
    for (int frame = 0; frame<frames16; frame++) {
        _filteredData16[frame] = _filteredData[frame*16];
    }
    
    if (_filteredData) {
        delete [] _filteredData;
        _filteredData = nil;
    }
    
    if (step==4) goto writeFile16;
    
    // ================================================================
    // STEP 5:
    // ================================================================
    if (_atom) {
        delete [] _atom;
        _atom = nil;
    }
    _atom = new float[frames16];
    
    for (int m = 0; m < size; m++) {
        float sum = 0;
        for (int n = 0; n < size-m ; n++) {
            sum += (_filteredData16[n] * _filteredData16[n+m]);
        }
        _atom[m] = sum;
    }
    
    if (step==5) goto writeAutomFile;

    
writeFile:
    [self.delegate didFinishCalculateData];
    return;
writeFile16:
    [self.delegate didFinishCalculateData];
    return;
writeAutomFile:
    [self.delegate didFinishCalculateData];
    return;
    
}

- (float)getNumberOfFrames {
    if (_stepToProceed < 4) {
        return _frames;
    } else if (_stepToProceed == 4) {
        return _frames/16;
    } else {
        return _frames/16;
    }
}
- (float *)getNumberSoundData {
    if (_stepToProceed < 4) {
        return _filteredData;
    } else if (_stepToProceed == 4) {
        return _filteredData16;
    } else {
        return _atom;
    }
}

- (float)getSampleRate {
    return AUTOCORR_SAMPLE_RATE;
}
- (int)getFrames {
    return _frames/REDUCED_SAMPLE_RATE_TIME;
}
- (float*)autocorrData {
    return _autocorrData;
}

@end
