//
//  ViewController.h
//  HearingAid
//
//  Created by Hai Le on 12/3/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FDWaveformView;

@interface ViewController : UIViewController {
    IBOutlet FDWaveformView *waveform;
    IBOutlet FDWaveformView *waveform1;
    IBOutlet FDWaveformView *waveform2;
    IBOutlet FDWaveformView *waveform3;
    IBOutlet FDWaveformView *waveform4;
    IBOutlet FDWaveformView *waveform5;
    IBOutlet FDWaveformView *waveform6;
    
    NSURL *_originalFile;
    
    float **_originalData;
}

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@end
