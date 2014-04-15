//
//  ViewController.m
//  HearingAid
//
//  Created by Hai Le on 12/3/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import "ViewController.h"
#import "AMAudioFileReader.h"
#import "AMAudioFileWriter.h"
#import "FDWaveformView.h"
#import "EAFRead.h"
#import "EAFWrite.h"
#import "EAFUtilities.h"
#import "Dsp.h"
#import "FilterBank.h"
#import "AMDataPlot.h"

#define COUNTOF(x) (sizeof(x)/sizeof(*x))

@interface ViewController () <EAFWriterDelegate, AMDataPlotDelegate> {
    AVAudioPlayer* _musicPlayer;
    int _finishedCount;
}

@end

@implementation ViewController

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.scrollView layoutIfNeeded];
    self.scrollView.contentSize = self.contentView.bounds.size;
}

- (void)viewDidLoad {
    // Path for original file
    NSString *inputSound  = [[NSBundle mainBundle] pathForResource:@"03" ofType:@"wav"];
    _originalFile = [NSURL fileURLWithPath:inputSound];
    
    // Wave form setup
    waveform.alpha = 1.0f;
    waveform.audioURL = _originalFile;
    waveform.doesAllowScrubbing = YES;
    waveform.doesAllowStretchAndScroll = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //TODO: Change to desired step
    // 1: Frequency filter
    // 2: Envelop extractor
    // 3: Diffirentiator
    // 4: Half-wave rectification
    int step = 5;
    
    // Init audio player
    NSError *error;
    _musicPlayer = [[AVAudioPlayer alloc]
                    initWithContentsOfURL:_originalFile error:&error];
    [_musicPlayer prepareToPlay];
    [_musicPlayer setNumberOfLoops:-1];
    
    waveform1.duration = _musicPlayer.duration;
    waveform2.duration = _musicPlayer.duration;
    waveform3.duration = _musicPlayer.duration;
    waveform4.duration = _musicPlayer.duration;
    waveform5.duration = _musicPlayer.duration;
    waveform6.duration = _musicPlayer.duration;
    waveformSum.duration = _musicPlayer.duration;
    
    // Audio reader
	EAFRead *reader = [[EAFRead alloc] init];
    [reader openFileForRead:_originalFile];
    
    // Allocate original data
    _originalData = AllocateAudioBuffer(2, (int)reader.fileNumFrames);
    [reader readFloatsConsecutive:reader.fileNumFrames intoArray:_originalData];
    
    //
    float frames = reader.fileNumFrames;
    UInt32 channels = reader.numberOfChannels;
    
    //
    // Init filter bank1
    //
    bank1 = [[FilterBank alloc] initWithFrames:frames Channels:channels FilterType:1 Data:_originalData];
    waveform1.delegate = self;
    bank1.waveFormDataView = waveform1;
    [bank1 processToStep:step];
    
    //
    // Init filter bank2
    //
    bank2 = [[FilterBank alloc] initWithFrames:frames Channels:channels FilterType:2 Data:_originalData];
    waveform2.delegate = self;
    bank2.waveFormDataView = waveform2;
    [bank2 processToStep:step];
    
    //
    // Init filter bank3
    //
    bank3 = [[FilterBank alloc] initWithFrames:frames Channels:channels FilterType:3 Data:_originalData];
    waveform3.delegate = self;
    bank3.waveFormDataView = waveform3;
    [bank3 processToStep:step];
    
    //
    // Init filter bank4
    //
    bank4 = [[FilterBank alloc] initWithFrames:frames Channels:channels FilterType:4 Data:_originalData];
    waveform4.delegate = self;
    bank4.waveFormDataView = waveform4;
    [bank4 processToStep:step];
    
    //
    // Init filter bank5
    //
    bank5 = [[FilterBank alloc] initWithFrames:frames Channels:channels FilterType:5 Data:_originalData];
    waveform5.delegate = self;
    bank5.waveFormDataView = waveform5;
    [bank5 processToStep:step];
    
    //
    // Init filter bank6
    //
    bank6 = [[FilterBank alloc] initWithFrames:frames Channels:channels FilterType:6 Data:_originalData];
    waveform6.delegate = self;
    bank6.waveFormDataView = waveform6;
    [bank6 processToStep:step];
}

- (void)didFinishLoadData:(BOOL)success {
    _finishedCount ++;
    if (_finishedCount == 6) {
        int nFrames = [bank6 getNumberOfFrames];
        float* sum = new float[nFrames];
        
        float** bank6Data = [bank6 getNumberSoundData];
        float** bank5Data = [bank5 getNumberSoundData];
        float** bank4Data = [bank4 getNumberSoundData];
        float** bank3Data = [bank3 getNumberSoundData];
        float** bank2Data = [bank2 getNumberSoundData];
        float** bank1Data = [bank1 getNumberSoundData];
        
        for (int i = 0; i<nFrames; i++) {
            sum[i] = bank6Data[0][i]+bank5Data[0][i]+bank4Data[0][i]+bank3Data[0][i]+bank2Data[0][i]+bank1Data[0][i];
        }
        [waveformSum setSamplesCount:nFrames];
        [waveformSum setData:sum];
        
        [_musicPlayer play];
        
        [NSTimer scheduledTimerWithTimeInterval:1/50.0f
                                         target:self
                                       selector:@selector(updateTimer)
                                       userInfo:nil
                                        repeats:YES];
    }
}

- (void)updateTimer {
    float progress =  _musicPlayer.currentTime/_musicPlayer.duration;
    waveform1.progress =  progress;
    waveform2.progress =  progress;
    waveform3.progress =  progress;
    waveform4.progress =  progress;
    waveform5.progress =  progress;
    waveform6.progress =  progress;
    waveformSum.progress =  progress;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
