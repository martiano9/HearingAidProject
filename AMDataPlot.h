//
//  SCWaveformView.h
//  SCWaveformView
//
//  Created by Simon CORSIN on 24/01/14.
//  Copyright (c) 2014 Simon CORSIN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol AMDataPlotDelegate;

@interface AMDataPlot : UIView

@property (nonatomic)                    float   *data;
@property (nonatomic)                    int samplesCount;
@property (strong, readwrite, nonatomic) UIColor *normalColor;
@property (strong, readwrite, nonatomic) UIColor *progressColor;
@property (assign, readwrite, nonatomic) CGFloat progress;
@property (assign, readwrite, nonatomic) BOOL antialiasingEnabled;

@property (readwrite, nonatomic) UIImage *generatedNormalImage;
@property (readwrite, nonatomic) UIImage *generatedProgressImage;

@property (nonatomic, weak) id<AMDataPlotDelegate> delegate;

// Ask the waveformview to generate the waveform right now
// instead of doing it in the next draw operation
- (void)generateWaveforms;

@end

@protocol AMDataPlotDelegate <NSObject>
@optional
- (void)didFinishLoadData:(BOOL)success;
@end
