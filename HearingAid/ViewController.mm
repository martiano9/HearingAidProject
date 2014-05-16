//
//  ViewController.m
//  HearingAid
//
//  Created by Hai Le on 12/3/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import "ViewController.h"
#import "FDWaveformView.h"
#import "EAFRead.h"
#import "EAFUtilities.h"
#import "Dsp.h"
#import "FilterBank.h"
#import "SVProgressHUD.h"

#define COUNTOF(x) (sizeof(x)/sizeof(*x))
#define k 200
#define h 1.4

@interface ViewController () <FilterBankDelegate> {
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
    // ====================================================================================
    //
    
    // Path for original file
    NSString *inputSound  = [[NSBundle mainBundle] pathForResource:@"01" ofType:@"wav"];
    _originalFile = [NSURL fileURLWithPath:inputSound];
    
    // Time
    startTime = 0.0;    // in seconds
    duration = 10;       // in seconds
    //
    // ====================================================================================
    
    // Wave form setup
    waveform.alpha = 1.0f;
    waveform.audioURL = _originalFile;
    waveform.doesAllowScrubbing = YES;
    waveform.doesAllowStretchAndScroll = YES;
    
    _stepNames = @[@"Frequency filter",
                   @"Envelop extractor",
                   @"Diffirentiator",
                   @"Half-wave rectification",
                   @"Autocorrelation"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Default value
    _step = 1;
    
    // Audio reader
	EAFRead *reader = [[EAFRead alloc] init];
    [reader openFileForRead:_originalFile];
    
    // Allocate original data
    float frames = reader.sampleRate * duration;
    _originalData = AllocateAudioBuffer(2, (int)reader.fileNumFrames);
    [reader readFloatsConsecutive:frames
                        intoArray:_originalData
                       withOffset:startTime*reader.sampleRate];
    
    //
    // Init filter bank1
    //
    bank1 = [[FilterBank alloc] initWithFrames:frames filterType:1 data:_originalData[0]];
    bank1.delegate = self;
    
    //
    // Init filter bank2
    //
    bank2 = [[FilterBank alloc] initWithFrames:frames filterType:2 data:_originalData[0]];
    bank2.delegate = self;
    
    //
    // Init filter bank3
    //
    bank3 = [[FilterBank alloc] initWithFrames:frames filterType:3 data:_originalData[0]];
    bank3.delegate = self;
    
    //
    // Init filter bank4
    //
    bank4 = [[FilterBank alloc] initWithFrames:frames filterType:4 data:_originalData[0]];
    bank4.delegate = self;
    
    //
    // Init filter bank5
    //
    bank5 = [[FilterBank alloc] initWithFrames:frames filterType:5 data:_originalData[0]];
    bank5.delegate = self;
    
    //
    // Init filter bank6
    //
    bank6 = [[FilterBank alloc] initWithFrames:frames filterType:6 data:_originalData[0]];
    bank6.delegate = self;
}

- (void)didFinishCalculateData {
    _finishedCount ++;
   
    if (_finishedCount == 6) {
        int nFrames = [bank6 getNumberOfFrames];
        float* sum = new float[nFrames];
        
        float* bank6Data = [bank6 getNumberSoundData];
        float* bank5Data = [bank5 getNumberSoundData];
        float* bank4Data = [bank4 getNumberSoundData];
        float* bank3Data = [bank3 getNumberSoundData];
        float* bank2Data = [bank2 getNumberSoundData];
        float* bank1Data = [bank1 getNumberSoundData];
        
        for (int i = 0; i<nFrames; i++) {
            sum[i] = bank6Data[i]+bank5Data[i]+bank4Data[i]+bank3Data[i]+bank2Data[i]+bank1Data[i];
        }
        
        [self writeFileName:@"bank1.txt" fromData:bank1Data frames:nFrames];
        [self writeFileName:@"bank2.txt" fromData:bank2Data frames:nFrames];
        [self writeFileName:@"bank3.txt" fromData:bank3Data frames:nFrames];
        [self writeFileName:@"bank4.txt" fromData:bank4Data frames:nFrames];
        [self writeFileName:@"bank5.txt" fromData:bank5Data frames:nFrames];
        [self writeFileName:@"bank6.txt" fromData:bank6Data frames:nFrames];
        [self writeFileName:@"banks.txt" fromData:sum frames:nFrames];
        
        [self computePeak:sum frames:nFrames];
        delete []sum;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showSuccessWithStatus:@"Export Successfully"];
        });
    }
}

- (void)writeFileName:(NSString*)name fromData:(float*)data frames:(int)frames {
    NSMutableString *str = [NSMutableString stringWithString:@"0"];
    
    for (int i = 0; i<frames; i++) {
        [str appendFormat:@"\n%.15f",data[i]];
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *filePath = [path stringByAppendingPathComponent:name];
    [str writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void)computePeak:(float*)data frames:(int)frames {
    float * peaks = new float[frames];
    float peakMax = 0.0;
    
    for (int m = 0; m<frames; m++) {
        
        if (peakMax < data[m]) {
            peakMax = data[m];
        }
        
        float val = [self computeS1:m
                              array:data
                             lenght:frames
                         windowSize:k];
        if (val <= 0) {
            val = 0;
        }
        peaks[m] = val;
    }
    
    // Calculate mean
    float   mean                = 0.0;
    int     countPositiveValue  = 0;
    
    for (int i = 0; i < frames; i++) {
        if (peaks[i] > 0) {
            mean += peaks[i];
            countPositiveValue ++;
        }
    }
    mean = mean / countPositiveValue;
    
    // Calculate standard deviation
    float deviation = 0.0;
    for (int i = 0; i < frames; i++) {
        if (peaks[i] > 0) {
            deviation += powf((peaks[i] - mean),2);
        }
    }
    deviation = sqrtf(deviation / countPositiveValue);
    
    // Remove local peaks which are “small” in global context
    float foo = h * deviation;
    for (int i = 0; i < frames; i++) {
        if (peaks[i] > 0 && (peaks[i] - mean) <= foo) {
            peaks[i] = 0;
        }
    }
    int i = 0;
    int window = 200;
    bool found = NO;
    while (i < frames) {
        int end = i + window;
        if (end >= frames) {
            end = frames - 1;
        }
        if (peaks[i] > 0) {
            found = NO;
            for (int m = i+1; m<=end; m++) {
                if (peaks[m] > peaks[i]) {
                    peaks[i] = 0.0;
                    i = m;
                    found = YES;
                } else {
                    peaks[m] = 0.0;
                }
            }
            if (found == NO) {
                i = i+window;
            }
        } else {
            i++;
        }
    }
    [self writeFileName:@"peaks.txt" fromData:peaks frames:frames];
    
    // Compute mean of pulse array
    
    //    peaks = peaks(banks); %apply peak picking
    //    peaks_index=find(peaks > 0); %find peaks above 0
    //    for i=1:length(peaks_index)
    //        peaks_seconds(i) = peaks_index(i)/27563*10; %transfom peak sample time to seconds (10 seconds)
    //    end
    //    peaks_seconds=peaks_seconds';  %make peaks a column matrix-array
    //    for i=2:length(peaks_seconds)
    //        remainder(i) = mod(peaks_seconds(i+1), peaks_seconds(2));    %estimate the remainder after division of the second peak with the rest of them (seems that first peak is a bug)
    //    end
    //    mean_remainder=mean(remainder); %get the mean of the remainder of the peaks
    //    pulse_index = 1-mean_remainder;   %define pulse index after subtraction with the mean remainder of the peak
    
    float meanRemainder = 0.0;
    int countPeak = 0;
    float secondPeak;
    for (int i = 0; i < frames; i++) {
        if (peaks[i]>0) {
            countPeak ++;
            
            float peakInSecond = (float)i*10/27563;
            
            if (countPeak == 2) {
                secondPeak = peakInSecond;
            } else if (countPeak > 2) {
                float remainder = fmodf(peakInSecond,secondPeak);
                meanRemainder += remainder;
            }
            
        }
    }
    meanRemainder = meanRemainder / (countPeak-1);
    
    
    float pulseIndex = 1 - meanRemainder;
    NSLog(@"Pulse Index: %.15f", pulseIndex);
    
    delete[] peaks;
}

- (float)computeS1:(int)index array:(float*)array lenght:(int)frames windowSize:(float)windowSize {
    float val = 0.0;
    
    float left = 0.0;
    // Calculate the maximum among the signed distances of xi from its k LEFT neighbours
    for (int i = index - 1; i >= index - windowSize; i--) {
        if (i < 0) break;
        
        left = fmaxf(left,array[index] - array[i]);
    }
    
    float right = 0.0;
    // Calculate the maximum among the signed distances of xi from its k RIGHT neighbours
    for (int i = index + 1; i <= index + windowSize; i++) {
        if (i >= frames - 1) break;
        
        right = fmaxf(right,array[index] - array[i]);
        
    }
    
    val = (left + right) * 0.5;
    
    return val;
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
