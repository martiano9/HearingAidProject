//
//  AMAudioFileReader.h
//  HearingAid
//
//  Created by Hai Le on 12/3/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>

#import "CAStreamBasicDescription.h"
#import "CAComponentDescription.h"

typedef struct {
    AudioStreamBasicDescription asbd;
    AudioUnitSampleType *data;
	UInt32 numFrames;
	UInt32 sampleNum;
} SoundBuffer, *SoundBufferPtr;

@interface AMAudioFileReader : NSObject {
    SoundBuffer mSoundBuffer[1];
}

@property float* data;
@property int samplerate;
@property int frames;

- (BOOL)openFile:(NSString*)mPath;

@end
