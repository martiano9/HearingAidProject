

/*--------------------------------------------------------------------------------
 
 EAFWrite.h
 
 Copyright (C) 2009-2012 The DSP Dimension,
 Stephan M. Bernsee (SMB)
 All rights reserved
 *	Version 3.6
 
 --------------------------------------------------------------------------------*/

#include <AudioToolbox/AudioToolbox.h>

#ifndef __has_feature      // Optional.
#define __has_feature(x) 0 // Compatibility with non-clang compilers.
#endif

@protocol EAFWriterDelegate;

@interface EAFWrite : NSObject 
{
	ExtAudioFileRef mOutputAudioFile;
	
	UInt32	mAudioChannels;
	AudioStreamBasicDescription	mOutputFormat;
	
	AudioStreamBasicDescription	mStreamFormat;
	AudioFileTypeID mType;
	AudioFileID mAfid;
}

@property (nonatomic, weak) id<EAFWriterDelegate> delegate;

-(void)SetupStreamAndFileFormatForType:(AudioFileTypeID)aftid withSR:(float) sampleRate channels:(long) numChannels wordlength:(long)numBits;
- (OSStatus) openFileForWrite:(NSURL*)inPath sr:(Float64)sampleRate channels:(int)numChannels wordLength:(int)numBits type:(AudioFileTypeID)aftid;
- (void) closeFile;
-(OSStatus) writeFloats:(long)numFrames fromArray:(float **)data;
-(OSStatus) writeShorts:(long)numFrames fromArray:(short **)data;

@end

@protocol EAFWriterDelegate <NSObject>
@optional
- (void)writerDidFinish:(BOOL)success;
@end