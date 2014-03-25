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
    if (_filteredData) {
        for (int i=0; i<_numberOfChannels; i++)
            delete [] _filteredData[i];
        delete [] _filteredData;
    }
    
    int frames16 = _frames/16;
    float aFrames = _frames/8;
    
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
        float lowpassed = fabsf(_filteredData[channel][0]);
        for (int frame = 0; frame<_frames; frame++) {
            float absVal = fabsf(_filteredData[channel][frame]);
            
            lowpassed = (absVal * 0.05) + (lowpassed * (1.0 - 0.05));
            _filteredData[channel][frame] = lowpassed;
            
            //NSLog(@"%f %f",absVal, lowpassed);
        }
    }
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
                float diff = buffer[channel][frame] - buffer[channel][frame-1];
                _filteredData[channel][frame] = diff;
            
            //NSLog(@"%f %f",absVal, lowpassed);
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
    
    if (step==4) goto writeFile16;
    
    // ================================================================
    // STEP 5:
    // ================================================================
    _atom = AllocateAudioBuffer(_numberOfChannels, (int)frames16/2);
    
    for (int channel = 0; channel<_numberOfChannels; channel++) {
        for (int frame = 0; frame<frames16/2; frame++) {
            for (int n = 0; n<(frames16/2)-frame ; n ++) {
                _atom[channel][frame]= _atom[channel][frame]+_filteredData16[channel][n]*_filteredData16[channel][n+frame];
            }
        }
    }
    
    _waveFormView.isMirror = NO;
    if (step==5) goto writeAutomFile;
    
writeFile:
    [self writeToFile:_fileURL withData:_filteredData frames:_frames];
    return;
writeFile16:
    [self writeToFile:_fileURL withData:_filteredData16 frames:frames16];
    return;
writeAutomFile:
    [self writeToFile:_fileURL withData:_atom frames:frames16/2];
    NSLog(@"write");
    return;
    
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
