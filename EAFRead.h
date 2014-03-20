
/*--------------------------------------------------------------------------------
 
 EAFRead.h
 
 Copyright (C) 2009-2012 The DSP Dimension,
 Stephan M. Bernsee (SMB)
 All rights reserved
 *	Version 3.6

 --------------------------------------------------------------------------------*/


#include <AudioToolbox/AudioToolbox.h>

#if (TARGET_OS_IPHONE)
	#import <AVFoundation/AVFoundation.h>
	#import <MediaPlayer/MediaPlayer.h>
#endif

#import "CAStreamBasicDescription.h"
#import "CAXException.h"

#ifndef __has_feature      // Optional.
#define __has_feature(x) 0 // Compatibility with non-clang compilers.
#endif

@interface EAFRead : NSObject {
 	ExtAudioFileRef mExtAFRef;
	double mExtAFRateRatio;
	Float64 mPlaybackSampleRate;
	SInt64 mRpos;
	NSURL *mFileUrl;
	BOOL mReadFromAsset;
	UInt64 mTotalNumFramesInFile;
    BOOL mSeeking;

    UInt32 mExtAFNumChannels;
    Float64 mExtAFSampleRate;

#if (TARGET_OS_IPHONE)
	AVAssetReader *mAssetReader;
	AVAssetReaderOutput *mAssetReaderOutput;
	long mAssetNumSamplesRead, mAssetNumSamplesInBuffer;
	SInt16 *mRawSampleData;
	volatile BOOL mReaderBeingInited;
#endif
}

@property (nonatomic) UInt32 numberOfChannels;
@property (nonatomic) Float64 sampleRate;

- (OSStatus)openFileForRead:(NSURL*)fileURL sr:(Float64)sampleRate channels:(int)numChannels;
- (OSStatus)openFileForRead:(NSURL*)fileURL;

- (OSStatus) readFloatsConsecutive:(SInt64)numFrames intoArray:(float**)audio;
- (OSStatus) readFloatsConsecutive:(SInt64)numFrames intoArray:(float**)audio withOffset:(long)offset;
- (OSStatus) readSInt16Consecutive:(SInt64)numFrames intoArray:(SInt16**)audio;
- (OSStatus) readSInt16Consecutive:(SInt64)numFrames intoArray:(SInt16**)audio withOffset:(long)offset;
- (OSStatus) closeFile;
- (SInt64) fileNumFrames;
- (void) seekToStart;
- (BOOL) isSeeking;
- (OSStatus) seekToPercent:(Float64)percent;
- (Float64) sampleRate;
- (UInt32)numberOfChannels;
- (SInt64) tell;
-(void)dealloc;
-(SInt16*)copyFrames:(SInt64*)numFrames error:(OSStatus*)err;
#if (TARGET_OS_IPHONE)
-(long) pullNewSamplesFromAsset:(AVAssetReaderOutput *)assetOutput;
#endif

@end
