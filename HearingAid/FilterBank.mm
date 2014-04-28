//
//  FilterBank.m
//  HearingAid
//
//  Created by Hai Le on 19/3/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import "FilterBank.h"
#import "EAFWrite.h"
#import "FDWaveformView.h"
#import "AMDataPlot.h"
#import "EAFUtilities.h"

@interface FilterBank (Private) <EAFWriterDelegate> {
    
}

@end

@implementation FilterBank

@synthesize frames = _frames;
@synthesize numberOfChannels = _numberOfChannels;

- (id)initWithFrames:(float)frames Channels:(UInt32)channels FilterType:(int)bankIndex Data:(float**)data
{
    self = [super init];
    if (self) {
        _frames = frames;
        _numberOfChannels = channels;
        _originalData = data;
        
        _atomReducedTime = 4;
//        // Path for saved file
//        NSString *pathString = [NSString stringWithFormat:@"bank%d.aif",bankIndex];
//        NSArray *pathComponents = [NSArray arrayWithObjects:
//                                   [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
//                                   pathString,
//                                   nil];
//        _fileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
        // Switch by bankIndex
        if (bankIndex == 1 || bankIndex == 9) {
            if (_numberOfChannels == 1)
                _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::LowPass<6>, 1> (1024);
            else
                _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::LowPass<6>, 2> (1024);
            
            Dsp::Params params;
            params[0] = 44100;  // sample rate
            params[1] = 6;      // order
            params[2] = 200;    // cutoff frequency
            _filter->setParams (params);
        }
        if (bankIndex == 2) {
            if (_numberOfChannels == 1)
                _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::BandPass<6>, 1> (1024);
            else
                _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::BandPass<6>, 2> (1024);
            
            Dsp::Params params;
            params[0] = 44100;  // sample rate
            params[1] = 6;      // order
            params[2] = 300;    // cutoff frequency
            params[3] = 100;    // band width
            _filter->setParams (params);
        }
        if (bankIndex == 3) {
            if (_numberOfChannels == 1)
                _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::BandPass<6>, 1> (1024);
            else
                _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::BandPass<6>, 2> (1024);
            
            Dsp::Params params;
            params[0] = 44100;  // sample rate
            params[1] = 6;      // order
            params[2] = 600;    // cutoff frequency
            params[3] = 200;    // band width
            _filter->setParams (params);
        }
        if (bankIndex == 4) {
            if (_numberOfChannels == 1)
                _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::BandPass<6>, 1> (1024);
            else
                _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::BandPass<6>, 2> (1024);
            
            Dsp::Params params;
            params[0] = 44100;  // sample rate
            params[1] = 6;      // order
            params[2] = 1200;    // cutoff frequency
            params[3] = 400;    // band width
            _filter->setParams (params);
        }
        if (bankIndex == 5) {
            if (_numberOfChannels == 1)
                _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::BandPass<6>, 1> (1024);
            else
                _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::BandPass<6>, 2> (1024);
            
            Dsp::Params params;
            params[0] = 44100;  // sample rate
            params[1] = 6;      // order
            params[2] = 2400;    // cutoff frequency
            params[3] = 1200;    // band width
            _filter->setParams (params);
        }
        if (bankIndex == 6) {
            if (_numberOfChannels == 1)
                _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::HighPass<6>, 1> (1024);
            else
                _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::HighPass<6>, 2> (1024);
            
            Dsp::Params params;
            params[0] = 44100;  // sample rate
            params[1] = 6;      // order
            params[2] = 3200;    // cutoff frequency
            _filter->setParams (params);
        }
    }
    return self;
}

- (void)processToStep:(int)step {
    // Assing number of step
    _stepToProceed = step;
    
    if (_filteredData) {
        for (int i=0; i<_numberOfChannels; i++)
            delete [] _filteredData[i];
        delete [] _filteredData;
        _filteredData = nil;
    }
    
    if (_filteredData16) {
        for (int i=0; i<_numberOfChannels; i++)
            delete [] _filteredData16[i];
        delete [] _filteredData16;
        _filteredData16 = nil;
    }
    
    if (_atom) {
        for (int i=0; i<_numberOfChannels; i++)
            delete [] _atom[i];
        delete [] _atom;
        _atom = nil;
    }
    
    int frames16 = _frames/16;
    
    // Copy data from original data
    float** buffer = AllocateAudioBuffer(_numberOfChannels, (int)_frames);
    
    _filteredData = AllocateAudioBuffer(_numberOfChannels, (int)_frames);
    for(int i = 0; i < _numberOfChannels; i++) {
        memcpy(_filteredData[i], _originalData[i], (size_t)_frames * sizeof(float));
    }
    
    // ================================================================
    // STEP 1:
    // ================================================================
    // Process filter
    _filter->process(_frames, _filteredData);
    _waveFormView.isMirror = YES;
    if (step==1) goto writeFile;
    
    // ================================================================
    // STEP 2:
    // ================================================================
    for (int channel = 0; channel<_numberOfChannels; channel++) {
        for (int frame = 0; frame<_frames; frame++) {
            _filteredData[channel][frame] = fabsf(_filteredData[channel][frame]);
            //NSLog(@"%f %f",absVal, lowpassed);
        }
    }
    if (!_filter1) {
        if (_numberOfChannels == 1)
            _filter1 = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::LowPass<6>, 1> (1024);
        else
            _filter1 = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::LowPass<6>, 2> (1024);
    }
    
    
    Dsp::Params params;
    params[0] = 44100;  // sample rate
    params[1] = 6;      // order
    params[2] = 10;    // cutoff frequency
    _filter1->setParams (params);
    _filter1->process(_frames, _filteredData);
    
    _waveFormView.isMirror = NO;
    if (step==2) goto writeFile;
    
    // ================================================================
    // STEP 3:
    // ================================================================
    
    for(int i = 0; i < _numberOfChannels; i++) {
        memcpy(buffer[i], _filteredData[i], (size_t)_frames * sizeof(float));
    }
    
    for (int channel = 0; channel<_numberOfChannels; channel++) {
        
        for (int frame = 1; frame<_frames; frame++) {
                float diff = fabsf(buffer[channel][frame] - buffer[channel][frame-1]);
                _filteredData[channel][frame] = diff;
        }
    }
    
    // delete old data
    if (buffer) {
        for (int i=0; i<_numberOfChannels; i++)
            delete [] buffer[i];
        delete [] buffer;
    }
    
    _waveFormView.isMirror = NO;
    if (step==3) goto writeFile;
    
    // ================================================================
    // STEP 4:
    // ================================================================
    _filteredData16 = AllocateAudioBuffer(_numberOfChannels, (int)frames16);
    for (int channel = 0; channel<_numberOfChannels; channel++) {
        for (int frame = 0; frame<frames16; frame++) {
            _filteredData16[channel][frame] = MAX(0, _filteredData[channel][frame*16]);
        }
    }
    _waveFormView.isMirror = NO;
    
    if (_filteredData) {
        for (int i=0; i<_numberOfChannels; i++)
            delete [] _filteredData[i];
        delete [] _filteredData;
    }
    _filteredData = nil;
    
    if (step==4) goto writeFile16;
    
    // ================================================================
    // STEP 5:
    // ================================================================
    _atom = AllocateAudioBuffer(_numberOfChannels, (int)frames16/_atomReducedTime);
    
    for (int channel = 0; channel<_numberOfChannels; channel++) {
        for (int m = 0; m<frames16/_atomReducedTime; m++) {
            for (int n = 0; n<(frames16/_atomReducedTime)-m ; n++) {
                int x = _atomReducedTime;
                _atom[channel][m] = _atom[channel][m]
                                        + (_filteredData16[channel][n*x]
                                        * _filteredData16[channel][(n+m)*x]);
            }
        }
    }
    
    _waveFormView.isMirror = NO;
    if (step==5) goto writeAutomFile;
    
writeFile:
    [_waveFormDataView setSamplesCount:_frames];
    [_waveFormDataView setData:_filteredData[0]];
    [self.delegate didFinishCalculateData];
    return;
writeFile16:
    [_waveFormDataView setSamplesCount:frames16];
    [_waveFormDataView setData:_filteredData16[0]];
    [self.delegate didFinishCalculateData];
    return;
writeAutomFile:
    [_waveFormDataView setSamplesCount:frames16/_atomReducedTime];
    [_waveFormDataView setData:_atom[0]];
    [self.delegate didFinishCalculateData];
    return;
    
}

- (float)getNumberOfFrames {
    if (_stepToProceed < 4) {
        return _frames;
    } else if (_stepToProceed == 4) {
        return _frames/16;
    } else {
        return _frames/16/_atomReducedTime;
    }
}
- (float **)getNumberSoundData {
    if (_stepToProceed < 4) {
        return _filteredData;
    } else if (_stepToProceed == 4) {
        return _filteredData16;
    } else {
        return _atom;
    }
}

@end
