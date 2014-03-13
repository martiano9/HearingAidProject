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
    
    // Path for original file
    NSString *inputSound  = [[NSBundle mainBundle] pathForResource:@"01" ofType:@"wav"];
    _originalFile = [NSURL fileURLWithPath:inputSound];
    
    // Path for band 1 file
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"band1.aif",
                               nil];
	_filterdFile1 = [NSURL fileURLWithPathComponents:pathComponents];
    
    // Path for band 2 file
    pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"band2.aif",
                               nil];
	_filterdFile2 = [NSURL fileURLWithPathComponents:pathComponents];
    
    // Audio reader
	EAFRead *reader = [[EAFRead alloc] init];
    [reader openFileForRead:_originalFile sr:44100 channels:2];
    _originalData = AllocateAudioBuffer(2, (int)reader.fileNumFrames);
    [reader readFloatsConsecutive:reader.fileNumFrames intoArray:_originalData];
    
    // copy new data array
    _filteredData1 = AllocateAudioBuffer(2, (int)reader.fileNumFrames);
    for(int i = 0 ;i < COUNTOF(_originalData) ; i++)
        memcpy(_filteredData1[i], _originalData[i], (size_t)reader.fileNumFrames * sizeof(float));
    
    _filteredData2 = AllocateAudioBuffer(2, (int)reader.fileNumFrames);
    for(int i = 0 ;i < COUNTOF(_originalData) ; i++)
        memcpy(_filteredData2[i], _originalData[i], (size_t)reader.fileNumFrames * sizeof(float));
    
    Dsp::SimpleFilter <Dsp::Butterworth::LowPass <6>, 2> f1;
    f1.setup(6, 44100, 200);
    f1.process ((int)reader.fileNumFrames, _filteredData1);
    
    // Eliptic but not working
//    Dsp::SimpleFilter <Dsp::Elliptic::LowPass <6>, 2> f1;
//    f1.setup(6, 44100,200, 3, 40);
//    f1.process ((int)reader.fileNumFrames, _filteredData1);
    
    Dsp::SimpleFilter <Dsp::Butterworth::BandPass <6>, 2> f2;
    f2.setup(6, 44100, 300, 100);
    f2.process ((int)reader.fileNumFrames, _filteredData2);
    
    // Audio writer
    [self writeToFile:_filterdFile1 withData:_filteredData1 frames:(long)reader.fileNumFrames];
    [self writeToFile:_filterdFile2 withData:_filteredData2 frames:(long)reader.fileNumFrames];
}

- (void)writerDidFinish:(BOOL)success {
    NSLog(@"Finished write to file");
    // Wave form setup
    waveform.alpha = 1.0f;
    waveform.audioURL = _originalFile;
    waveform.doesAllowScrubbing = YES;
    waveform.doesAllowStretchAndScroll = YES;
    
    // Wave form setup
    waveform1.alpha = 1.0f;
    waveform1.audioURL = _filterdFile1;
    waveform1.doesAllowScrubbing = YES;
    waveform1.doesAllowStretchAndScroll = YES;
    
    // Wave form setup
    waveform2.alpha = 1.0f;
    waveform2.audioURL = _filterdFile2;
    waveform2.doesAllowScrubbing = YES;
    waveform2.doesAllowStretchAndScroll = YES;
}

- (void) writeToFile:(NSURL*) url withData:(float**)data frames:(long)frames {
    EAFWrite* writer = [[EAFWrite alloc] init];
    writer.delegate = self;
    // Write filterd (2) data to file
    [writer openFileForWrite:url sr:44100 channels:2 wordLength:16 type:kAudioFileAIFFType];
    [writer writeFloats:frames fromArray:data];
}

@end
