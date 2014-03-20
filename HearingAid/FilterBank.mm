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
        
        // Path for saved file
        NSString *pathString = [NSString stringWithFormat:@"bank%d.aif",bankIndex];
        NSArray *pathComponents = [NSArray arrayWithObjects:
                                   [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                                   pathString,
                                   nil];
        _fileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
        // Switch by bankIndex
        if (bankIndex == 1) {
            if (_numberOfChannels == 1) _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::LowPass<6>, 1> (1024);
            else _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::LowPass<6>, 2> (1024);
            
            Dsp::Params params;
            params[0] = 44100;  // sample rate
            params[1] = 6;      // order
            params[2] = 200;    // cutoff frequency
            _filter->setParams (params);
        }
        if (bankIndex == 2) {
            if (_numberOfChannels == 1) _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::BandPass<6>, 1> (1024);
            else _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::BandPass<6>, 2> (1024);
            
            Dsp::Params params;
            params[0] = 44100;  // sample rate
            params[1] = 6;      // order
            params[2] = 300;    // cutoff frequency
            params[3] = 100;    // band width
            _filter->setParams (params);
        }
        if (bankIndex == 3) {
            if (_numberOfChannels == 1) _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::BandPass<6>, 1> (1024);
            else _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::BandPass<6>, 2> (1024);
            
            Dsp::Params params;
            params[0] = 44100;  // sample rate
            params[1] = 6;      // order
            params[2] = 600;    // cutoff frequency
            params[3] = 200;    // band width
            _filter->setParams (params);
        }
        if (bankIndex == 4) {
            if (_numberOfChannels == 1) _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::BandPass<6>, 1> (1024);
            else _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::BandPass<6>, 2> (1024);
            
            Dsp::Params params;
            params[0] = 44100;  // sample rate
            params[1] = 6;      // order
            params[2] = 1200;    // cutoff frequency
            params[3] = 400;    // band width
            _filter->setParams (params);
        }
        if (bankIndex == 5) {
            if (_numberOfChannels == 1) _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::BandPass<6>, 1> (1024);
            else _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::BandPass<6>, 2> (1024);
            
            Dsp::Params params;
            params[0] = 44100;  // sample rate
            params[1] = 6;      // order
            params[2] = 2400;    // cutoff frequency
            params[3] = 1200;    // band width
            _filter->setParams (params);
        }
        if (bankIndex == 6) {
            if (_numberOfChannels == 1) _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::HighPass<6>, 1> (1024);
            else _filter = new Dsp::SmoothedFilterDesign<Dsp::Butterworth::Design::HighPass<6>, 2> (1024);
            
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
    if (_filteredData) {
        for (int i=0; i<_numberOfChannels; i++)
            delete [] _filteredData[i];
        delete [] _filteredData;
    }
    
    // Copy data from original data
    _filteredData = AllocateAudioBuffer(_numberOfChannels, (int)_frames);
    for(int i = 0; i < _numberOfChannels; i++) {
        memcpy(_filteredData[i], _originalData[i], (size_t)_frames * sizeof(float));
    }
    // Process filter
    _filter->process(_frames, _filteredData);
    
    if (step<=1) {
        // Path for band 1 file
        [self writeToFile:_fileURL withData:_filteredData frames:_frames];
        return;
    }
}

- (void) writeToFile:(NSURL*) url withData:(float**)data frames:(long)frames {
    EAFWrite* writer = [[EAFWrite alloc] init];
    writer.delegate = self;
    // Write filterd (2) data to file
    [writer openFileForWrite:url sr:44100 channels:_numberOfChannels wordLength:16 type:kAudioFileAIFFType];
    [writer writeFloats:frames fromArray:data];
}

- (void)writerDidFinish:(BOOL)success {
    // Wave form setup
    _waveFormView.alpha = 1.0f;
    _waveFormView.audioURL = _fileURL;
    _waveFormView.doesAllowScrubbing = YES;
    _waveFormView.doesAllowStretchAndScroll = YES;
}

@end
