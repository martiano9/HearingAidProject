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

#define COUNTOF(x) (sizeof(x)/sizeof(*x))

@interface ViewController () <EAFWriterDelegate>

@end

@implementation ViewController

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.scrollView layoutIfNeeded];
    self.scrollView.contentSize = self.contentView.bounds.size;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    //TODO: Change to desired step
    // 1: Frequency filter
    // 2: Envelop extractor
    // 3: Diffirentiator
    // 4: Half-wave rectification
    int step = 4;
    
    // Path for original file
    NSString *inputSound  = [[NSBundle mainBundle] pathForResource:@"01" ofType:@"wav"];
    _originalFile = [NSURL fileURLWithPath:inputSound];
    
    // Wave form setup
    waveform.alpha = 1.0f;
    waveform.audioURL = _originalFile;
    waveform.doesAllowScrubbing = YES;
    waveform.doesAllowStretchAndScroll = YES;
    
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
    FilterBank *bank1 = [[FilterBank alloc] initWithFrames:frames Channels:channels FilterType:1 Data:_originalData];
    bank1.waveFormView = waveform1;
    [bank1 processToStep:step];
    
    //
    // Init filter bank2
    //
    FilterBank *bank2 = [[FilterBank alloc] initWithFrames:frames Channels:channels FilterType:2 Data:_originalData];
    bank2.waveFormView = waveform2;
    [bank2 processToStep:step];
    
    //
    // Init filter bank3
    //
    FilterBank *bank3 = [[FilterBank alloc] initWithFrames:frames Channels:channels FilterType:3 Data:_originalData];
    bank3.waveFormView = waveform3;
    [bank3 processToStep:step];
    
    //
    // Init filter bank4
    //
    FilterBank *bank4 = [[FilterBank alloc] initWithFrames:frames Channels:channels FilterType:4 Data:_originalData];
    bank4.waveFormView = waveform4;
    [bank4 processToStep:step];
    
    //
    // Init filter bank5
    //
    FilterBank *bank5 = [[FilterBank alloc] initWithFrames:frames Channels:channels FilterType:5 Data:_originalData];
    bank5.waveFormView = waveform5;
    [bank5 processToStep:step];
    
    //
    // Init filter bank6
    //
    FilterBank *bank6 = [[FilterBank alloc] initWithFrames:frames Channels:channels FilterType:6 Data:_originalData];
    bank6.waveFormView = waveform6;
    [bank6 processToStep:step];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
