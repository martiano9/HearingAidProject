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
#import "DataPlot.h"
#import <RMPickerViewController/RMPickerViewController.h>
#import <GraphKit/UIColor+GraphKit.h>

#define COUNTOF(x) (sizeof(x)/sizeof(*x))
#define k 400
#define h 1.5

@interface ViewController () <FilterBankDelegate, RMPickerViewControllerDelegate> {
    NSArray *songsName;
    int _finishedCount;
    NSTimer *_timer;
    BOOL _playing;
}

@end

@implementation ViewController
//
//- (void)viewDidLayoutSubviews {
//    [super viewDidLayoutSubviews];
//    [self.scrollView layoutIfNeeded];
//    self.scrollView.contentSize = self.contentView.bounds.size;
//}

- (void)viewDidLoad {
    // ====================================================================================
    //
    
    // Path for original file
    NSString *inputSound  = [[NSBundle mainBundle] pathForResource:@"01 - Beats" ofType:@"wav"];
    songsName = [NSArray arrayWithObjects: @"01 - Beats",
                                           @"02 - Knowing me",
                                           @"03 - Test 015",
                                           @"04 - Test 017",
                                           @"05 - Fort Minor",
                                           @"06 - Dancing Queen",
                                           @"07 - SOS",
                                           @"08 - The Cask Of Amontillado",
                                           @"001",@"002",@"003",@"004",@"005",
                                           @"006",@"007",@"008",@"009",@"010",@"011",@"012",nil];
    _originalFile = [NSURL fileURLWithPath:inputSound];
    
    //
    // ====================================================================================
    
    // Wave form setup
//    waveform.alpha = 1.0f;
//    waveform.audioURL = _originalFile;
//    waveform.doesAllowScrubbing = YES;
//    waveform.doesAllowStretchAndScroll = YES;

    self.view.backgroundColor = [UIColor gk_peterRiverColor];
    
    self.tracker = [[UIView alloc] initWithFrame:CGRectMake(lineGraph.frame.origin.x, lineGraph.frame.origin.y, 1, 240)];
    [self.tracker setBackgroundColor:[UIColor gk_alizarinColor]];
    self.tracker.alpha = 0.5;
    [self.view addSubview:self.tracker];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self _startAnalizing];
}

- (void)_startAnalizing {
    // Default value
    _step = 5;
    
    // Audio reader
	EAFRead *reader = [[EAFRead alloc] init];
    [reader openFileForRead:_originalFile];
    
    // Allocate original data
    float frames = reader.fileNumFrames;
    _originalData = AllocateAudioBuffer(2, (int)reader.fileNumFrames);
    [reader readFloatsConsecutive:frames
                        intoArray:_originalData];
    
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
        int nFrames = [bank6 getFrames];
        float *sum = new float[nFrames];
        
        float* bank6Data = [bank6 getAutocorrData];
        float* bank5Data = [bank5 getAutocorrData];
        float* bank4Data = [bank4 getAutocorrData];
        float* bank3Data = [bank3 getAutocorrData];
        float* bank2Data = [bank2 getAutocorrData];
        float* bank1Data = [bank1 getAutocorrData];
        
        int firstLowIndex = 0;
        int secondLowIndex = 0;
        int secondPeakIndex = 0;
        for (int i = 0; i<nFrames; i++) {
            sum[i] = bank6Data[i]+bank5Data[i]+bank4Data[i]+bank3Data[i]+bank2Data[i]+bank1Data[i];
            if (firstLowIndex == 0) {
                if (i>=1 && sum[i] > sum[i-1]) {
                    firstLowIndex = i;
                }
                
            } else if (secondPeakIndex == 0 && i > firstLowIndex) {
                if (sum[i] < sum[i-1]) {
                    secondPeakIndex = i;
                }
            } else if (secondLowIndex == 0) {
                if (sum[i] > sum[i-1]) {
                    secondLowIndex = i;
                }
            }
        }
        for (int i = 0; i<(secondPeakIndex+firstLowIndex)*0.5; i++) {
            sum[i] = sum[secondLowIndex];
        }
  
        [self writeFileName:@"bank1.txt" fromData:bank1Data frames:nFrames];
        [self writeFileName:@"bank2.txt" fromData:bank2Data frames:nFrames];
        [self writeFileName:@"bank3.txt" fromData:bank3Data frames:nFrames];
        [self writeFileName:@"bank4.txt" fromData:bank4Data frames:nFrames];
        [self writeFileName:@"bank5.txt" fromData:bank5Data frames:nFrames];
        [self writeFileName:@"bank6.txt" fromData:bank6Data frames:nFrames];
        [self writeFileName:@"banks.txt" fromData:sum frames:nFrames];
        
        float *peaks = [self computePeak:sum frames:nFrames];
        [lineGraph setData:sum peaks:peaks frames:nFrames];
        //delete []sum;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showSuccessWithStatus:@"Finished Analyzing"];
            [lineGraph draw];
        });
    }
}

- (float)slope:(float*)data frames:(int)frames {
    float slope = 0.0;
    float A = 0.0, B = 0.0, C = 0.0, D = 0.0;
    
    for(int i=0; i<frames; i++)
    {
        A+=i;
        B+=data[i];
        C+=i*i;
        D+=i*data[i];
    }
    slope=(frames*D-A*B)/(frames*C-A*A);
    return slope;
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

- (float*)computePeak:(float*)data frames:(int)frames {
    float slope = [self slope:data frames:frames];
    NSLog(@"%f",slope);
    
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
    float foo = 0.0;
    if (slope>0) {
        foo = 1.1 * deviation;
    } else {
        foo = 1.4 * deviation;
    }
    
    for (int i = 0; i < frames; i++) {
        float sloped = foo + i*slope;
        if (peaks[i] > 0 && (peaks[i] - mean) <= sloped) {
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
                i = i+window-1;
            }
        } else {
            i++;
        }
    }
    [self writeFileName:@"peaks.txt" fromData:peaks frames:frames];
    
    float meanRemainder = 0.0;
    int countPeak = 0;
    float secondPeak;
    float maxPeak = 0.0;
    for (int i = 0; i < frames; i++) {
        if (peaks[i]>0) {
            countPeak ++;
            
            float peakInSecond = (float)i/AUTOCORR_SAMPLE_RATE;
            
            if (countPeak == 1) {
                secondPeak = peakInSecond;
                maxPeak = data[i];
            } else if (countPeak > 1) {
                //maxPeak = fmaxf(data[i], maxPeak);
                float remainder = fmodf(peakInSecond,secondPeak);
                if(remainder<=0.15 || remainder>=0.85) {
                    meanRemainder += data[i];
                }
            }
        }
        //if (countPeak == 10) break;
    }
    meanRemainder = (meanRemainder / maxPeak) * -0.25;
    
    
    float pulseIndex = expf(meanRemainder);
    NSLog(@"Pulse Index: %.15f", pulseIndex);
    
    return peaks;
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

#pragma mark - Actions
- (void)updateTime:(NSTimer *)timer {
    Float64 dur = self.player.currentTime;
    Float64 durInMiliSec = 1000*dur;
    slider.value = durInMiliSec;
    self.timeLabel.text = [NSString stringWithFormat:@"%.1f",dur];
    CGRect rect = self.tracker.frame;
    rect.origin.x = (dur/SECONDS_TO_ANALYZE)*lineGraph.size.width;
    [self.tracker setFrame:rect];
    if (dur >= SECONDS_TO_ANALYZE) {
        [self.player pause];
        [_timer invalidate];
        _timer = nil;
        [self.playButton setSelected:NO];
        _playing = NO;
        self.timeLabel.text = [NSString stringWithFormat:@"%.1f",0.0];
        [self.player setCurrentTime:0];
        slider.value = 0.0;
    }
}

- (IBAction)exportClicked:(id)sender {
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    
    if (_playing) {
        [self.player pause];
        [self.playButton setSelected:NO];
        _playing = NO;
    } else {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateTime:) userInfo:nil repeats:YES];
        [self.player play];
        [self.playButton setSelected:YES];
        _playing = YES;
        Float64 x  = slider.value/1000.0;
        [self.player setCurrentTime:x];
    }
}

- (IBAction)selectTapped:(id)sender {
    RMPickerViewController *pickerVC = [RMPickerViewController pickerController];
    pickerVC.delegate = self;
    pickerVC.titleLabel.text = @"Select a song to analyze";
    
    //You can enable or disable bouncing and motion effects
    //pickerVC.disableBouncingWhenShowing = YES;
    //pickerVC.disableMotionEffects = YES;
    
    [pickerVC show];
}

- (IBAction)valueChanged:(id)sender {
    if (_playing) {
        [self.player pause];
        [_timer invalidate];
        _timer = nil;
        [self.playButton setSelected:NO];
        _playing = NO;
    }
    UISlider* xslider = sender;
    self.timeLabel.text = [NSString stringWithFormat:@"%.1f",xslider.value/1000.0];
    CGRect rect = self.tracker.frame;
    rect.origin.x = (xslider.value/1000.0/SECONDS_TO_ANALYZE)*lineGraph.size.width;
    [self.tracker setFrame:rect];
}

#pragma mark - RMPickerViewController Delegates
- (void)pickerViewController:(RMPickerViewController *)vc didSelectRows:(NSArray *)selectedRows
{
    NSInteger selectedIndex = [[selectedRows objectAtIndex:0] integerValue];
    NSString *inputSound  = [[NSBundle mainBundle] pathForResource:[songsName objectAtIndex:selectedIndex] ofType:@"wav"];
    self.songNameLabel.text = [songsName objectAtIndex:selectedIndex];
    _originalFile = [NSURL fileURLWithPath:inputSound];
    
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:_originalFile error:nil];
    [self.player prepareToPlay];
    //[self.player seekToTime:CMTimeMake(0, startTime)];
    slider.maximumValue = SECONDS_TO_ANALYZE*1000;
    slider.value = 0;
    _playing = NO;
    
    [self _startAnalizing];
    
    _finishedCount = 0;
    [SVProgressHUD showWithStatus:@"Analyzing" maskType:SVProgressHUDMaskTypeBlack];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [bank1 process];
        [bank2 process];
        [bank3 process];
        [bank4 process];
        [bank5 process];
        [bank6 process];
    });
}

- (void)pickerViewControllerDidCancel:(RMPickerViewController *)vc {
    NSLog(@"Selection was canceled");
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [songsName count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [songsName objectAtIndex:row];
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
