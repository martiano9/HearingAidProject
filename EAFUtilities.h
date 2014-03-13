/*
 *  Utilities.h
 *
 *  Created by Stephan on 21.03.11.
 *  Copyright 2011-2012 The DSP Dimension. All rights reserved.
 *	Version 3.6
 *
 */

#ifndef __has_feature      // Optional.
#define __has_feature(x) 0 // Compatibility with non-clang compilers.
#endif


void checkStatus(int status);
long wrappedDiff(long in1, long in2, long wrap);
void DeallocateAudioBuffer(SInt16 **audio, int numChannels);
void DeallocateAudioBuffer(float **audio, int numChannels);
float **AllocateAudioBuffer(int numChannels, int numFrames);
SInt16 **AllocateAudioBufferSInt16(int numChannels, int numFrames);
void ClearAudioBuffer(float **audio, long numChannels, long numFrames);
void ClearAudioBuffer(SInt16 **audio, long numChannels, long numFrames);

void arc_release(id a);
id arc_retain(id a);

