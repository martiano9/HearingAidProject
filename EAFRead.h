
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


#ifndef __has_feature      // Optional.
#define __has_feature(x) 0 // Compatibility with non-clang compilers.
#endif

@interface EAFRead : NSObject {
 	ExtAudioFileRef mExtAFRef;
   int mExtAFNumChannels;
	double mExtAFRateRatio;
	Float64 mPlaybackSampleRate;
	Float64 mExtAFSampleRate;
	SInt64 mRpos;
	NSURL *mFileUrl;
	BOOL mReadFromAsset;
	UInt64 mTotalNumFramesInFile;
    BOOL mSeeking;

	
#if (TARGET_OS_IPHONE)
	AVAssetReader *mAssetReader;
	AVAssetReaderOutput *mAssetReaderOutput;
	long mAssetNumSamplesRead, mAssetNumSamplesInBuffer;
	SInt16 *mRawSampleData;
	volatile BOOL mReaderBeingInited;
#endif

	
}
- (OSStatus) openFileForRead:(NSURL*)fileURL sr:(Float64)sampleRate channels:(int)numChannels;
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
- (SInt64) tell;
-(void)dealloc;
-(SInt16*)copyFrames:(SInt64*)numFrames error:(OSStatus*)err;
#if (TARGET_OS_IPHONE)
-(long) pullNewSamplesFromAsset:(AVAssetReaderOutput *)assetOutput;
#endif

@end
