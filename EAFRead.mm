
/*--------------------------------------------------------------------------------
 
 EAFRead.mm
 
 Copyright (C) 2009-2012 The DSP Dimension,
 Stephan M. Bernsee (SMB)
 All rights reserved
 *	Version 3.6
 
 --------------------------------------------------------------------------------*/


#import "EAFRead.h"
#import "EAFUtilities.h"

#if __has_feature(objc_arc)
#else
#define __bridge
#endif


@implementation EAFRead

@synthesize numberOfChannels = mExtAFNumChannels;

#if (TARGET_OS_IPHONE)

-(OSStatus)createReaderWithStartPosition:(CMTimeRange)time
{
	mReaderBeingInited = YES;
	OSStatus err = noErr;
	
	{
		
		if (mAssetReader)       {
			arc_release(mAssetReader);
			mAssetReader = nil;
		}
		if (mAssetReaderOutput) {
			arc_release(mAssetReaderOutput);
			mAssetReaderOutput = nil;
		}

		mAssetNumSamplesInBuffer=mAssetNumSamplesRead = 0;
		

		NSString *query = [mFileUrl query];
		if (!query) {NSLog(@"!!! iPod URL has no ID query"); err = -1; goto end;}
		
		NSNumber *pid = [NSNumber numberWithLongLong: [[query substringFromIndex:3] longLongValue] ];
		if (!pid) {NSLog(@"!!! Cannot determine PID from URL query"); err = -1; goto end;}
		
		MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:pid forProperty:MPMediaItemPropertyPersistentID];
		MPMediaQuery *songQuery = [[MPMediaQuery alloc] init];
		[songQuery addFilterPredicate: predicate];
		if ([[songQuery items] count] == 0) {
			NSLog(@"!!! ERROR - specified asset not found. Did you try reading a DRM protected song?");
			err = -1; 
			goto end;
		}
		
		MPMediaItem *audioItem = [[songQuery items] objectAtIndex:0];

		AVURLAsset *audioItemAsset = [AVURLAsset URLAssetWithURL:mFileUrl options:nil];
		
		mTotalNumFramesInFile = [[audioItem valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue] * mPlaybackSampleRate;
		
		NSError *assetError = nil;

		mAssetReader = arc_retain([AVAssetReader assetReaderWithAsset:audioItemAsset
													  error:&assetError]);
		if (assetError) {
			NSLog (@"error: %@", assetError);
			err = -1; 
			goto end;
		}
		
		[mAssetReader setTimeRange:time];
		
		NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey, 
										[NSNumber numberWithFloat:mPlaybackSampleRate], AVSampleRateKey,
										[NSNumber numberWithInt:mExtAFNumChannels], AVNumberOfChannelsKey,
										[NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
										[NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
										[NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
										[NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
										nil];
		
		mAssetReaderOutput = arc_retain([AVAssetReaderAudioMixOutput 
							   assetReaderAudioMixOutputWithAudioTracks:audioItemAsset.tracks
							   audioSettings: outputSettings]);
		if (![mAssetReader canAddOutput: mAssetReaderOutput]) {
			NSLog (@"!!! ERROR - unable to add reader output");
			err = -1; 
			goto end;
		}
		
		[mAssetReader addOutput: mAssetReaderOutput];
		BOOL ready = [mAssetReader startReading];
		
		if (!ready) {NSLog(@"Can't start reading"); err = -1; goto end;}
		
		mReadFromAsset = YES;
	
		arc_release(songQuery);
		songQuery = nil;

	}
end:
	mReaderBeingInited = NO;
	
	return err;
}

// ---------------------------------------------------------------------------------------------------------------------------------------------

- (void) createReaderOnMainThread:(id)param
{
	NSNumber *num = (NSNumber*)param;
	[self createReaderWithStartPosition:CMTimeRangeMake(CMTimeMake([num floatValue], mPlaybackSampleRate), kCMTimePositiveInfinity)];
}	

#endif



// ---------------------------------------------------------------------------------------------------------------------------------------------

- (OSStatus)openFileForRead:(NSURL*)fileURL {
    OSStatus err = noErr;
    
    mRpos = 0;
	mReadFromAsset = NO;
	mFileUrl = [fileURL copy];
    
#if (TARGET_OS_IPHONE)
	// First we need to make sure if we're dealing with an item from the iPod library here
	if([[mFileUrl scheme] isEqualToString:@"ipod-library"])
	{
		mPlaybackSampleRate     = 44100;
		mExtAFSampleRate        = 44100;
		mExtAFNumChannels       = 2;
		mExtAFRateRatio         = 1;
        
		if ([self createReaderWithStartPosition:CMTimeRangeMake(CMTimeMake(0, mPlaybackSampleRate), kCMTimePositiveInfinity)] != noErr)
			return -1;
	} else
#endif
	{
        
        UInt32 propSize;
        
		err = ExtAudioFileOpenURL((__bridge CFURLRef)mFileUrl, &mExtAFRef);
        XThrowIfError(err, "Error in ExtAudioFileOpen");
        
        // Read file format
        CAStreamBasicDescription fileFormat;
        propSize = sizeof(fileFormat);
        memset(&fileFormat, 0, sizeof(AudioStreamBasicDescription));
        
        err = ExtAudioFileGetProperty(mExtAFRef, kExtAudioFileProperty_FileDataFormat, &propSize, &fileFormat);
        XThrowIfErr(err);
        
		
		mPlaybackSampleRate     = fileFormat.mSampleRate;
		mExtAFRateRatio         = mPlaybackSampleRate / fileFormat.mSampleRate;
		mExtAFSampleRate        = fileFormat.mSampleRate;
        mExtAFNumChannels       = fileFormat.mChannelsPerFrame;
		
		AudioStreamBasicDescription clientFormat;
		propSize = sizeof(clientFormat);
		memset(&clientFormat, 0, sizeof(AudioStreamBasicDescription));
		clientFormat.mFormatID				= kAudioFormatLinearPCM;
		clientFormat.mSampleRate			= mPlaybackSampleRate;
		clientFormat.mFormatFlags           = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
		clientFormat.mChannelsPerFrame      = fileFormat.mChannelsPerFrame;
		clientFormat.mBitsPerChannel        = sizeof(SInt16) * 8;
		clientFormat.mFramesPerPacket       = 1;
		clientFormat.mBytesPerFrame         = clientFormat.mBitsPerChannel * clientFormat.mChannelsPerFrame / 8;
		clientFormat.mBytesPerPacket        = clientFormat.mFramesPerPacket * clientFormat.mBytesPerFrame;
		clientFormat.mReserved              = 0;
		
		err = ExtAudioFileSetProperty(mExtAFRef, kExtAudioFileProperty_ClientDataFormat, propSize, &clientFormat);
		if (err) {NSLog(@"!!! Error in ExtAudioFileSetProperty, %d", (int)err); return err;}
	}
	return err;
    
}

- (OSStatus) openFileForRead:(NSURL*)fileURL sr:(Float64)sampleRate channels:(int)numChannels
{
	OSStatus err = noErr;
	
	mRpos = 0;
	mReadFromAsset = NO;
	mFileUrl = [fileURL copy];
				
#if (TARGET_OS_IPHONE)
	// First we need to make sure if we're dealing with an item from the iPod library here
	if([[mFileUrl scheme] isEqualToString:@"ipod-library"])
	{
		mPlaybackSampleRate = sampleRate;
		mExtAFSampleRate = sampleRate;
		mExtAFNumChannels = numChannels;
		mExtAFRateRatio = 1;

		if ([self createReaderWithStartPosition:CMTimeRangeMake(CMTimeMake(0, mPlaybackSampleRate), kCMTimePositiveInfinity)] != noErr)
			return -1;		
	} else
#endif
	{
		UInt32 propSize;		
		
		err = ExtAudioFileOpenURL((__bridge CFURLRef)mFileUrl, &mExtAFRef);
        XThrowIfError(err, "Error in ExtAudioFileOpen");
		
		CAStreamBasicDescription fileFormat;
		propSize = sizeof(fileFormat);
		memset(&fileFormat, 0, sizeof(AudioStreamBasicDescription));
		
		err = ExtAudioFileGetProperty(mExtAFRef, kExtAudioFileProperty_FileDataFormat, &propSize, &fileFormat);
		if (err) {NSLog(@"!!! Error in ExtAudioFileGetProperty, %ld", err); return err;}
		fileFormat.Print();
        
		// when we pass -1 we use the file's native sample rate
		if (sampleRate < 0.) mPlaybackSampleRate = fileFormat.mSampleRate;
		else mPlaybackSampleRate = sampleRate;
		
		mExtAFRateRatio = mPlaybackSampleRate / fileFormat.mSampleRate;
		mExtAFSampleRate = fileFormat.mSampleRate;
		
		AudioStreamBasicDescription clientFormat;
		propSize = sizeof(clientFormat);
		memset(&clientFormat, 0, sizeof(AudioStreamBasicDescription));
		clientFormat.mFormatID				= kAudioFormatLinearPCM;
		clientFormat.mSampleRate			= mPlaybackSampleRate;
		clientFormat.mFormatFlags        = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
		clientFormat.mChannelsPerFrame   = numChannels;
		clientFormat.mBitsPerChannel     = sizeof(SInt16) * 8;
		clientFormat.mFramesPerPacket    = 1;
		clientFormat.mBytesPerFrame      = clientFormat.mBitsPerChannel * clientFormat.mChannelsPerFrame / 8;
		clientFormat.mBytesPerPacket     = clientFormat.mFramesPerPacket * clientFormat.mBytesPerFrame;
		clientFormat.mReserved           = 0;
		
		err = ExtAudioFileSetProperty(mExtAFRef, kExtAudioFileProperty_ClientDataFormat, propSize, &clientFormat);
		if (err) {NSLog(@"!!! Error in ExtAudioFileSetProperty, %d", (int)err); return err;}
		
		mExtAFNumChannels = numChannels;		
	}
	return err;
}

// ---------------------------------------------------------------------------------------------------------------------------------------------

- (OSStatus) closeFile
{
	OSStatus err = noErr;
	if (mExtAFRef) {
		ExtAudioFileDispose(mExtAFRef);
		mExtAFRef = nil;
	}
#if (TARGET_OS_IPHONE)
	if (mRawSampleData) {
		free(mRawSampleData);
		mRawSampleData = NULL;
	}
	
	if (mAssetReader) {
		arc_release(mAssetReader);
		mAssetReader = nil;
	}
	if (mAssetReaderOutput) {
        arc_release(mAssetReaderOutput);
		mAssetReaderOutput = nil;
	}
#endif
    arc_release(mFileUrl);
	mFileUrl = nil;
	return err;
}
// ---------------------------------------------------------------------------------------------------------------------------------------------

- (BOOL) isSeeking;
{
    return mSeeking;
}
// ---------------------------------------------------------------------------------------------------------------------------------------------

- (OSStatus) seekToPercent:(Float64)percent
{

	OSStatus err = noErr;
    mSeeking = YES;

	SInt64 numFramesInFile = [self fileNumFrames];
	SInt64 seekPos = 0.01 * percent * numFramesInFile;
	
	if (seekPos > numFramesInFile-1)
		seekPos = numFramesInFile-1;
	
	
#if (TARGET_OS_IPHONE)
	if (mReadFromAsset) {

		mRpos = seekPos;
		seekPos /= mExtAFRateRatio;

		// This is required so the media/asset server demons are not exhausted. Otherwise we'd get a 
		// "The operation couldn’t be completed. (AVFoundationErrorDomain error -11800.)" error
		// Radar bug ID 9557175
		[self performSelectorOnMainThread:@selector(createReaderOnMainThread:) withObject:[NSNumber numberWithFloat:seekPos] waitUntilDone:YES];
		
	} else 
#endif
	{
		if (!mExtAFRef)	goto error;
		
		mRpos = seekPos;
		seekPos /= mExtAFRateRatio;
		
		@synchronized(self) {
			//
			// WORKAROUND for bug in ExtFileAudio
			//	
			SInt64 headerFrames = 0;
			
			AudioConverterRef acRef;
			UInt32 acrsize=sizeof(AudioConverterRef);
			err = ExtAudioFileGetProperty(mExtAFRef, kExtAudioFileProperty_AudioConverter, &acrsize, &acRef);
			if (err) goto error;
			
			AudioConverterPrimeInfo primeInfo;
			memset(&primeInfo, 0, sizeof(AudioConverterPrimeInfo));
			UInt32 piSize=sizeof(AudioConverterPrimeInfo);
			err = AudioConverterGetProperty(acRef, kAudioConverterPrimeInfo, &piSize, &primeInfo);
			if(err != kAudioConverterErr_PropertyNotSupported) // Only if decompressing
			{
				headerFrames=primeInfo.leadingFrames;
			}
			
			err = ExtAudioFileSeek(mExtAFRef, seekPos+headerFrames);
		}
	}
error:
    mSeeking = NO;

    return err;
}
// ---------------------------------------------------------------------------------------------------------------------------------------------

- (Float64)sampleRate
{
	if (!mExtAFRef)	return 0;
	return mPlaybackSampleRate;
}
// ---------------------------------------------------------------------------------------------------------------------------------------------

- (Float64) fileSampleRate
{
	if (!mExtAFRef)	return 0;
	return mExtAFSampleRate;
}
// ---------------------------------------------------------------------------------------------------------------------------------------------

- (SInt64) tell
{
#if (TARGET_OS_IPHONE)
	if (mReadFromAsset)
		return mRpos;
	else
#endif
	if (!mExtAFRef)	return 0;
	return mRpos;
}
// ---------------------------------------------------------------------------------------------------------------------------------------------

- (void) seekToStart
{
	[self seekToPercent:0];	
}

// ---------------------------------------------------------------------------------------------------------------------------------------------
#if (TARGET_OS_IPHONE)

-(long) pullNewSamplesFromAsset:(AVAssetReaderOutput *)assetOutput
{
	if (mReaderBeingInited)
		return -1;

    if (!mAssetReader) {
        mAssetNumSamplesInBuffer = mAssetNumSamplesRead = 0;
		return -1;
    }

    if ([mAssetReader status] != AVAssetReaderStatusReading) {
        mAssetNumSamplesInBuffer = mAssetNumSamplesRead = 0;
		return 0;	// EOF
    }

    if (!assetOutput) {
        mAssetNumSamplesInBuffer = mAssetNumSamplesRead = 0;
		return -1;
    }

	// protect our asset reader from a seek operation that might be carried our in parallel
    @synchronized(assetOutput, mAssetReader) {
		CMSampleBufferRef sampleBuffer = [assetOutput copyNextSampleBuffer];
		if (sampleBuffer) {
			CMBlockBufferRef buffer;
			AudioBufferList abl;
			CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer,
																	NULL,
																	&abl,
																	sizeof(AudioBufferList),
																	NULL,
																	NULL,
																	kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
																	&buffer);
			
			long rawSampleDataBytes = abl.mBuffers[0].mDataByteSize;
			
			if (mRawSampleData) {
				free(mRawSampleData);
				mRawSampleData = NULL;
			}
			mRawSampleData = (SInt16*)malloc(rawSampleDataBytes);
			memmove(mRawSampleData, abl.mBuffers[0].mData, rawSampleDataBytes);
			
			mAssetNumSamplesInBuffer = abl.mBuffers[0].mDataByteSize / sizeof(SInt16);
			mAssetNumSamplesRead = 0;
			
			CFRelease(buffer);
			
			CMSampleBufferInvalidate(sampleBuffer);
			CFRelease(sampleBuffer);
			
			return mAssetNumSamplesInBuffer;
		}
	}
	return 0;
}
// ---------------------------------------------------------------------------------------------------------------------------------------------


- (OSStatus) readSInt16ConsecutiveFromAsset:(UInt32*)numPackets intoArray:(SInt16*)buffer
{
	long numSamplesToRead = *numPackets * mExtAFNumChannels;
	OSStatus err = noErr;
	long samplesObtained = 0;
	
	@synchronized(self)
	{
		// we have a valid buffer
		if (buffer) {			
			// we want numSamplesToRead samples from our asset in this call
			for (long v = 0; v < numSamplesToRead; v++) {
				// if we have exceeded the amount of samples that are still in the buffer get new ones
				if (mAssetNumSamplesRead++ >= mAssetNumSamplesInBuffer-1) {
					// this reads a chunk of data from the asset. We cannot set the size of the chunk that is actually read, so we store the data
					// somewhere. -pullNewSamplesFromAsset does this for us.
					// err tells us how many samples were actually read from the asset, or gives us back an error code < 0. 
					err = [self pullNewSamplesFromAsset:mAssetReaderOutput];
					// break on error (return value < 0) and EOF (return value == 0)
					if (err <= 0) 
						break;
				}
				// if we have samples in our buffer copy them to buffer
				if (mAssetNumSamplesInBuffer) {
					buffer[v] = mRawSampleData[mAssetNumSamplesRead];
					samplesObtained++;
				}
			}
		}
	}
	// we have successfully read samplesObtained samples from our asset
	if (err >= 0)
		*numPackets = samplesObtained / mExtAFNumChannels;
	else {
		// on error, we assume we have read nothing and return the error code in err;
		*numPackets = 0;
		return err;
	}
	// all went well
	return noErr;
}

#endif

// ---------------------------------------------------------------------------------------------------------------------------------------------

- (OSStatus) readFloatsConsecutive:(SInt64)numFrames intoArray:(float**)audio withOffset:(long)offset
{
	
	OSStatus err = noErr;
	
	if (!mExtAFRef && !mReadFromAsset)	return -1;
   	
	SInt16 *data = [self copyFrames:&numFrames error:&err];
	if (!data) {
		NSLog(@"data is nil");
		goto error;
	}
	
	if (audio) {
		for (long c = 0; c < mExtAFNumChannels; c++) {
			if (!audio[c]) continue;
			for (long v = 0; v < numFrames; v++) {
				audio[c][v+offset] = (float)data[v*mExtAFNumChannels+c] / 32768.f;
			}
		}
	}
	
error:
	if (data)
		free(data);
	
	if (err != noErr) return err;
	return numFrames;
	
}
// ---------------------------------------------------------------------------------------------------------------------------------------------

- (OSStatus) readFloatsConsecutive:(SInt64)numFrames intoArray:(float**)audio
{
	return [self readFloatsConsecutive:numFrames intoArray:audio withOffset:0];
}
// ---------------------------------------------------------------------------------------------------------------------------------------------

-(SInt16*)copyFrames:(SInt64*)numFrames error:(OSStatus*)err
{
	*err = noErr;
	
	int kSegmentSize = (int)(*numFrames * mExtAFNumChannels * mExtAFRateRatio + .5);
	if (mExtAFRateRatio < 1.) kSegmentSize = (int)(*numFrames * mExtAFNumChannels / mExtAFRateRatio + .5);
	
	UInt32 numPackets = *numFrames; // Frames to read
	UInt32 samples = numPackets * mExtAFNumChannels;
	UInt32 loadedPackets = numPackets;
	
	SInt16 *data = (SInt16*)malloc(kSegmentSize*sizeof(SInt16));
	if (!data) {
		NSLog(@"data is nil");
		*err = -108; //kAudio_MemFullError;
		goto error;
	}
	memset(data, 0, kSegmentSize*sizeof(SInt16));
	
	@synchronized(self) {
#if (TARGET_OS_IPHONE)
		if (mReadFromAsset)
			*err = [self readSInt16ConsecutiveFromAsset:&loadedPackets intoArray:data];
		else 
#endif
		{
			AudioBufferList bufList;
			bufList.mNumberBuffers = 1;
			bufList.mBuffers[0].mNumberChannels = mExtAFNumChannels;
			bufList.mBuffers[0].mData = data;
			bufList.mBuffers[0].mDataByteSize = samples * sizeof(SInt16);
			
			*err = ExtAudioFileRead(mExtAFRef, &loadedPackets, &bufList);
		}

	}
	
error:
	
	mRpos += loadedPackets;	
	*numFrames = loadedPackets;
	
	return data;
}

// ---------------------------------------------------------------------------------------------------------------------------------------------

- (OSStatus) readSInt16Consecutive:(SInt64)numFrames intoArray:(SInt16**)audio withOffset:(long)offset
{
	OSStatus err = noErr;
	
	if (!mExtAFRef && !mReadFromAsset)	return -1;
   	
	SInt16 *data = [self copyFrames:&numFrames error:&err];
	if (!data) {
		NSLog(@"data is nil");
		goto error;
	}

	if (audio) {
		for (long c = 0; c < mExtAFNumChannels; c++) {
			if (!audio[c]) continue;
			for (long v = 0; v < numFrames; v++) {
				audio[c][v+offset] = data[v*mExtAFNumChannels+c];
			}
		}
	}
	
error:
	if (data)
		free(data);
	
	if (err != noErr) return err;
	return numFrames;
}
// ---------------------------------------------------------------------------------------------------------------------------------------------

- (OSStatus) readSInt16Consecutive:(SInt64)numFrames intoArray:(SInt16**)audio
{
	return [self readSInt16Consecutive:numFrames intoArray:audio withOffset:0];
}

// ---------------------------------------------------------------------------------------------------------------------------------------------

- (id)init;
{
	if (!(self = [super init]))
		return nil;
	
	mExtAFRateRatio = 1.;
	mExtAFRef=nil;
	mExtAFNumChannels = 0;
	mRpos = 0;
    mSeeking = NO;

#if (TARGET_OS_IPHONE)
	mAssetReader = nil;
	mAssetReaderOutput = nil;
	mAssetNumSamplesRead = mAssetNumSamplesInBuffer = 0;
	mRawSampleData = NULL;
	mTotalNumFramesInFile = 0;
	mReaderBeingInited = NO;
#endif
	return self;
}

// ---------------------------------------------------------------------------------------------------------------------------------------------


-(SInt64)fileNumFrames
{
#if (TARGET_OS_IPHONE)
	if (!mReadFromAsset) 
#endif
	{
		if (!mExtAFRef) return 0;
		SInt64 nf=0;
		UInt32 propSize = sizeof(SInt64);
		@synchronized (self) {
			OSStatus err = ExtAudioFileGetProperty(mExtAFRef, kExtAudioFileProperty_FileLengthFrames, &propSize, &nf);
			if (err) {NSLog(@"!!! Error in ExtAudioFileGetProperty kExtAudioFileProperty_FileLengthFrames, %ld", err);}
		}
		mTotalNumFramesInFile = (SInt64)(nf * mExtAFRateRatio+.5);
	}
	return mTotalNumFramesInFile;
}	

// ---------------------------------------------------------------------------------------------------------------------------------------------
-(void)dealloc
{
	[self closeFile];
#if __has_feature(objc_arc)
#else
	[super dealloc];
#endif
}


// ---------------------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------------------------

@end
