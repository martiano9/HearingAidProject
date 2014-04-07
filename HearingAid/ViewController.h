//
//  ViewController.h
//  HearingAid
//
//  Created by Hai Le on 12/3/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FDWaveformView;
@class AMDataPlot;
@class FilterBank;

@interface ViewController : UIViewController {
    IBOutlet FDWaveformView *waveform;
    IBOutlet AMDataPlot *waveform1;
    IBOutlet AMDataPlot *waveform2;
    IBOutlet AMDataPlot *waveform3;
    IBOutlet AMDataPlot *waveform4;
    IBOutlet AMDataPlot *waveform5;
    IBOutlet AMDataPlot *waveform6;
    IBOutlet AMDataPlot *waveformSum;
    
    FilterBank *bank6;
    FilterBank *bank5;
    FilterBank *bank4;
    FilterBank *bank3;
    FilterBank *bank2;
    FilterBank *bank1;
    
    NSURL *_originalFile;
    
    float **_originalData;
}

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@end
