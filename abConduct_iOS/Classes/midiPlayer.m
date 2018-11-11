//
//  midiPlayer.m
//  abConduct_iOS
//
//  Created by Reinhard Sasse on 01.11.18.
//  Copyright © 2018 Reinhard Sasse. All rights reserved.
//

#import "midiPlayer.h"

@implementation midiPlayer

@synthesize delegate;

MusicSequence seq;
AUGraph   procGraph;
AudioUnit sampler;
AudioUnit io;

- (instancetype) init {
    [self createAudioUnitGraph];
    [self configureAudioProcessingGraphAndStart:procGraph];
    return self;
}

- (instancetype) initWithSoundFontURL: (NSURL*) sfURL {
    [self createAudioUnitGraph];
    [self configureAudioProcessingGraphAndStart:procGraph];
    [self loadSoundFont:sfURL];
    return self;
}

- (void) loadMidiFileFromUrl: (NSURL*) midiFileURL {    
    NewMusicSequence(&seq);
    NewMusicPlayer(&(_player));
    MusicSequenceSetAUGraph(seq, procGraph);
    MusicSequenceFileLoad(seq, (__bridge CFURLRef _Nonnull)(midiFileURL), 0, kMusicSequenceLoadSMF_PreserveTracks);
    MusicPlayerSetSequence(_player, seq);
    MusicPlayerPreroll(_player);
}

- (void) startMidiPlayer {
    
    MusicPlayerStart(_player);
    MusicTrack track;
    MusicTimeStamp length;
    UInt32 size = sizeof(MusicTimeStamp);
    MusicSequenceGetIndTrack(seq, 1, &track);
    MusicTrackGetProperty(track, kSequenceTrackProperty_TrackLength, &length, &size);
    [self performSelector:@selector(stopMidiPlayer) withObject:nil afterDelay:length];
}

- (void) stopMidiPlayer {
    [self.delegate midiPlayerReachedEnd:self];
    MusicPlayerStop(_player);
    DisposeMusicSequence(seq);
    DisposeMusicPlayer(_player);
    
}

- (BOOL) createAudioUnitGraph {
    OSStatus result = noErr;
    AUNode samplerNode, ioNode;
    AudioComponentDescription compD = {};
    compD.componentManufacturer = kAudioUnitManufacturer_Apple;
    result = NewAUGraph (&procGraph);
    NSCAssert (result == noErr, @"Couldn't create an AUGraph: %d '%.4s'", (int) result, (const char *)&result);
    compD.componentType = kAudioUnitType_MusicDevice;
    compD.componentSubType = kAudioUnitSubType_MIDISynth;
    result = AUGraphAddNode (procGraph, &compD, &samplerNode);
    NSCAssert (result == noErr, @"Couldn't add the Sampler unit to the audio processing graph: %d '%.4s'", (int) result, (const char *)&result);
    compD.componentType = kAudioUnitType_Output;
    compD.componentSubType = kAudioUnitSubType_RemoteIO;
    result = AUGraphAddNode (procGraph, &compD, &ioNode);
    NSCAssert (result == noErr, @"Couldn't add the output unit to the audio processing graph: %d '%.4s'", (int) result, (const char *)&result);
    result = AUGraphOpen (procGraph);
    NSCAssert (result == noErr, @"Couldn't open the audio processing graph: %d '%.4s'", (int) result, (const char *)&result);
    result = AUGraphConnectNodeInput (procGraph, samplerNode, 0, ioNode, 0);
    NSCAssert (result == noErr, @"Couldn't connect nodes in the audio processing graph: %d '%.4s'", (int) result, (const char *)&result);
    result = AUGraphNodeInfo (procGraph, samplerNode, 0, &sampler);
    NSCAssert (result == noErr, @"Couldn't obtain reference to the Sampler unit: %d '%.4s'", (int) result, (const char *)&result);
    result = AUGraphNodeInfo (procGraph, ioNode, 0, &io);
    NSCAssert (result == noErr, @"Couldn't obtain a reference to the I/O unit: %d '%.4s'", (int) result, (const char *)&result);
    return YES;
}

- (void) configureAudioProcessingGraphAndStart: (AUGraph) graph {
    OSStatus result = noErr;
    if (graph) {
        result = AUGraphInitialize (graph);
        NSAssert (result == noErr, @"Couldn' initialze AUGraph: %d '%.4s'", (int) result, (const char *)&result);
        result = AUGraphStart (graph);
        NSAssert (result == noErr, @"Couldn't start audio processing graph: %d '%.4s'", (int) result, (const char *)&result);
    }
}

- (OSStatus) loadSoundFont: (NSURL *)bankURL {
    AudioUnitReset(sampler, kMusicDeviceProperty_SoundBankURL, 0);
    OSStatus result = noErr;
    const char *soundBankPath = bankURL.path.UTF8String;
    CFURLRef soundBankURL = CFURLCreateFromFileSystemRepresentation(kCFAllocatorDefault, (const UInt8 *)soundBankPath, strlen(soundBankPath), false);
    result = AudioUnitSetProperty(sampler,
                                           kMusicDeviceProperty_SoundBankURL,
                                           kAudioUnitScope_Global, 0,
                                           &soundBankURL, sizeof(soundBankURL));
    
    if (soundBankURL) CFRelease(soundBankURL);
    if (result) printf("AudioUnitSetProperty failed %d\n", result);
    return result;
}

@end
