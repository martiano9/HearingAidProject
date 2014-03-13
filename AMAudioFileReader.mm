//
//  AMAudioFileReader.m
//  HearingAid
//
//  Created by Hai Le on 12/3/14.
//  Copyright (c) 2014 Hai Le. All rights reserved.
//

#import "AMAudioFileReader.h"
#import <Accelerate/Accelerate.h>

const Float64 kGraphSampleRate = 44100.0;

@implementation AMAudioFileReader

- (BOOL)openFile:(NSString*)mPath {
    
    // create the URLs we'll use for source A and B
	CFURLRef mURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)mPath, kCFURLPOSIXPathStyle, false);
    
    ExtAudioFileRef xafref = 0;
	
	// open one of the two source files
    OSStatus result = ExtAudioFileOpenURL(mURL, &xafref);
    if (result || !xafref) {
        printf("ExtAudioFileOpenURL result %ld %08lX %4.4s\n", result, result, (char*)&result);
        return NO;
    }
	
	// get the file data format, this represents the file's actual data format
    CAStreamBasicDescription clientFormat;
    UInt32 propSize = sizeof(clientFormat);
    
    result = ExtAudioFileGetProperty(xafref, kExtAudioFileProperty_FileDataFormat, &propSize, &clientFormat);
    if (result) {
        printf("ExtAudioFileGetProperty kExtAudioFileProperty_FileDataFormat result %ld %08lX %4.4s\n", result, result, (char*)&result);
        return NO;
    }
    clientFormat.Print();
    
    // set the client format to be what we want back
    self.samplerate = kGraphSampleRate;
    
    double rateRatio = kGraphSampleRate / clientFormat.mSampleRate;
    clientFormat.mSampleRate = kGraphSampleRate;
    clientFormat.SetAUCanonical(1, true);
    printf("Audio File Client Format (format we want back from ExtAudioFile):\n");
    clientFormat.Print();
    
    propSize = sizeof(clientFormat);
    result = ExtAudioFileSetProperty(xafref, kExtAudioFileProperty_ClientDataFormat, propSize, &clientFormat);
    if (result) {
        printf("ExtAudioFileSetProperty kExtAudioFileProperty_ClientDataFormat %ld %08lX %4.4s\n", result, result, (char*)&result);
        return NO;
    }
    
    // get the file's length in sample frames
    UInt64 numFrames = 0;
    propSize = sizeof(numFrames);
    result = ExtAudioFileGetProperty(xafref, kExtAudioFileProperty_FileLengthFrames, &propSize, &numFrames);
    if (result) {
        printf("ExtAudioFileGetProperty kExtAudioFileProperty_FileLengthFrames result %ld %08lX %4.4s\n", result, result, (char*)&result);
        return NO;
    }
    printf("Number of Sample Frames: %lld\n", numFrames);
    
    numFrames = (UInt32)(numFrames * rateRatio); // account for any sample rate conversion
    printf("Number of Sample Frames after rate conversion (if any): %lld\n", numFrames);
	
    UInt32 outputBufferSize = (UInt32)numFrames; // Set this to something meaningful to you!!
    UInt8 *outputBuffer = (UInt8 *)malloc(sizeof(UInt8 *) * outputBufferSize);
    UInt32 sizePerPacket = clientFormat.mBytesPerPacket;
    
    UInt32 packetsPerBuffer = outputBufferSize / sizePerPacket;
    AudioBufferList audioData;
    
    audioData.mNumberBuffers = 1;
    audioData.mBuffers [ 0 ].mNumberChannels = clientFormat.mChannelsPerFrame;
    audioData.mBuffers [ 0 ].mDataByteSize = outputBufferSize;
    audioData.mBuffers [ 0 ].mData = outputBuffer;
    UInt32 frameCount = packetsPerBuffer;
    
    checkError(ExtAudioFileRead(xafref, &frameCount, &audioData), "ExtAudioFileRead failed");
    
    AudioBuffer audioBuffer = audioData.mBuffers [0];
    self.frames = audioBuffer.mDataByteSize / sizeof(Float32);
    SInt32 *frame = (SInt32 *)audioBuffer.mData;
    self.data  = (float *)calloc(self.frames, sizeof(float));
    
    fixedPointToFloat(frame,self.data,self.frames);
    
    // close the file and dispose the ExtAudioFileRef
    ExtAudioFileDispose(xafref);
    
	return YES;
}
/**
 * Handle errors.
 */
static void checkError(OSStatus error, const char *operation)
{
    if ( error == noErr )
        return;
    
    char errorString [ 20 ];
    *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(error);
    
    if ( isprint(errorString [ 1 ]) && isprint(errorString [ 2 ]) &&
        isprint(errorString [ 3 ]) && isprint(errorString [ 4 ]) )
    {
        errorString [ 0 ] = errorString [ 5 ] = '\'';
        errorString [ 6 ] = '\0';
    }
    else
    {
        sprintf(errorString, "%d", (int)error);
    }
    
    fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
    exit(1);
}

////////////////////////////////////////////////////////
// convert sample vector from fixed point 8.24 to Float
static void fixedPointToFloat ( SInt32 * source, float * target, int length ) {
    int i;
    for(i = 0;i < length; i++ ) {
        target[i] =  (SInt32) source[i]/ 32768.0;
    }
}


@end
