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
    
    NSURL *_originalFile;
    NSURL *_filterdFile1;
    NSURL *_filterdFile2;
    
    float **_originalData;
    float **_filteredData1;
    float **_filteredData2;
}

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@end
