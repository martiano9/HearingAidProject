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
#import "SVProgressHUD.h"

#define COUNTOF(x) (sizeof(x)/sizeof(*x))

@interface ViewController () <EAFWriterDelegate, AMDataPlotDelegate, FilterBankDelegate> {
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
    NSString *inputSound  = [[NSBundle mainBundle] pathForResource:@"02" ofType:@"wav"];
    _originalFile = [NSURL fileURLWithPath:inputSound];
    
    // Wave form setup
    waveform.alpha = 1.0f;
    waveform.audioURL = _originalFile;
    waveform.doesAllowScrubbing = YES;
    waveform.doesAllowStretchAndScroll = YES;
    
    _stepNames = @[@"Frequency filter", @"Envelop extractor",
                   @"Diffirentiator", @"Half-wave rectification", @"Autocorrelation"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //TODO: Change to desired step
    // 1: Frequency filter
    // 2: Envelop extractor
    // 3: Diffirentiator
    // 4: Half-wave rectification
    _step = 1;
    //int step = _step;
    
    // Init audio player
    NSError *error;
    _musicPlayer = [[AVAudioPlayer alloc]
                    initWithContentsOfURL:_originalFile error:&error];
    [_musicPlayer prepareToPlay];
    [_musicPlayer setNumberOfLoops:-1];
    
    // Audio reader
	EAFRead *reader = [[EAFRead alloc] init];
    [reader openFileForRead:_originalFile];
    
    // Allocate original data
    
    float frames = reader.fileNumFrames;

    UInt32 channels = reader.numberOfChannels;
    
    _originalData = AllocateAudioBuffer(2, (int)reader.fileNumFrames);
    [reader readFloatsConsecutive:frames intoArray:_originalData];
    [reader readFloatsConsecutive:frames intoArray:_originalData withOffset:20];
    
    
    //
    // Init filter bank1
    //
    bank1 = [[FilterBank alloc] initWithFrames:frames Channels:channels FilterType:1 Data:_originalData];
    bank1.delegate = self;
    bank1.waveFormDataView = waveform1;
    //[bank1 processToStep:step];
    
    //
    // Init filter bank2
    //
    bank2 = [[FilterBank alloc] initWithFrames:frames Channels:channels FilterType:2 Data:_originalData];
    bank2.delegate = self;
    bank2.waveFormDataView = waveform2;
    //[bank2 processToStep:step];
    
    //
    // Init filter bank3
    //
    bank3 = [[FilterBank alloc] initWithFrames:frames Channels:channels FilterType:3 Data:_originalData];
    bank3.delegate = self;
    bank3.waveFormDataView = waveform3;
    //[bank3 processToStep:step];
    
    //
    // Init filter bank4
    //
    bank4 = [[FilterBank alloc] initWithFrames:frames Channels:channels FilterType:4 Data:_originalData];
    bank4.delegate = self;
    bank4.waveFormDataView = waveform4;
    //[bank4 processToStep:step];
    
    //
    // Init filter bank5
    //
    bank5 = [[FilterBank alloc] initWithFrames:frames Channels:channels FilterType:5 Data:_originalData];
    bank5.delegate = self;
    bank5.waveFormDataView = waveform5;
    //[bank5 processToStep:step];
    
    //
    // Init filter bank6
    //
    bank6 = [[FilterBank alloc] initWithFrames:frames Channels:channels FilterType:6 Data:_originalData];
    bank6.delegate = self;
    bank6.waveFormDataView = waveform6;
    //[bank6 processToStep:step];
}

- (void)didFinishCalculateData {
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
        NSMutableString *s1 = [NSMutableString stringWithString:@"0"];
        NSMutableString *s2 = [NSMutableString stringWithString:@"0"];
        NSMutableString *s3 = [NSMutableString stringWithString:@"0"];
        NSMutableString *s4 = [NSMutableString stringWithString:@"0"];
        NSMutableString *s5 = [NSMutableString stringWithString:@"0"];
        NSMutableString *s6 = [NSMutableString stringWithString:@"0"];
        NSMutableString *ss = [NSMutableString stringWithString:@"0"];
        
        for (int i = 0; i<nFrames; i++) {
            sum[i] = bank6Data[0][i]+bank5Data[0][i]+bank4Data[0][i]+bank3Data[0][i]+bank2Data[0][i]+bank1Data[0][i];
            
            [s1 appendFormat:@"\n%.15f",bank1Data[0][i]];
            [s2 appendFormat:@"\n%.15f",bank2Data[0][i]];
            [s3 appendFormat:@"\n%.15f",bank3Data[0][i]];
            [s4 appendFormat:@"\n%.15f",bank4Data[0][i]];
            [s5 appendFormat:@"\n%.15f",bank5Data[0][i]];
            [s6 appendFormat:@"\n%.15f",bank6Data[0][i]];
            [ss appendFormat:@"\n%.15f",sum[i]];
        }
        [waveformSum setSamplesCount:nFrames];
        [waveformSum setData:sum];
        
        [self writeFileName:@"bank1.txt" fromString:s1];
        [self writeFileName:@"bank2.txt" fromString:s2];
        [self writeFileName:@"bank3.txt" fromString:s3];
        [self writeFileName:@"bank4.txt" fromString:s4];
        [self writeFileName:@"bank5.txt" fromString:s5];
        [self writeFileName:@"bank6.txt" fromString:s6];
        [self writeFileName:@"banks.txt" fromString:ss];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showSuccessWithStatus:@"Export Successfully"];
        });
        
//        
//        [_musicPlayer play];
//        
//        [NSTimer scheduledTimerWithTimeInterval:1/50.0f
//                                         target:self
//                                       selector:@selector(updateTimer)
//                                       userInfo:nil
//                                        repeats:YES];
    }
}

- (void)writeFileName:(NSString*)name fromString:(NSMutableString*)str {
    NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *filePath = [path stringByAppendingPathComponent:name];
    [str writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"%@",filePath);
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

#pragma mark - PickerView DataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return _stepNames.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return _stepNames[row];
}

#pragma mark - PickerView Delegate
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row
      inComponent:(NSInteger)component
{
    _step = (int)row + 1;
}

#pragma mark - Actions
- (IBAction)exportClicked:(id)sender {
    _finishedCount = 0;
    [SVProgressHUD showWithStatus:@"Exporting" maskType:SVProgressHUDMaskTypeBlack];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [bank1 processToStep:_step];
        [bank2 processToStep:_step];
        [bank3 processToStep:_step];
        [bank4 processToStep:_step];
        [bank5 processToStep:_step];
        [bank6 processToStep:_step];
    });
    
}

#pragma mark -
#pragma mark Dismiss Methods Sample

- (void)dismiss {
	[SVProgressHUD dismiss];
}

- (void)dismissSuccess {
	
}

- (void)dismissError {
	[SVProgressHUD showErrorWithStatus:@"Failed with Error"];
}

@end
