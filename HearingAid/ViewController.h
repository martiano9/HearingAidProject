//
//  ViewController.h
//  HearingAid
//
//  Created by Hai Le on 12/3/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class FDWaveformView;
@class DataPlot;
@class FilterBank;

@interface ViewController : UIViewController {
    IBOutlet DataPlot *lineGraph;
    IBOutlet UISlider *slider;
    
    FilterBank *bank6;
    FilterBank *bank5;
    FilterBank *bank4;
    FilterBank *bank3;
    FilterBank *bank2;
    FilterBank *bank1;
    
    NSURL *_originalFile;
    
    float **_originalData;
    float startTime;
    float duration;
    
    int _step;
}

@property (strong, nonatomic) IBOutlet UILabel *songNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
@property (strong, nonatomic) IBOutlet UIButton *playButton;
@property (strong, nonatomic) UIView* tracker;
@property (strong, nonatomic) AVAudioPlayer* player;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@end
