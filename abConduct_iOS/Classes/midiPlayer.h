//
//  midiPlayer.h
//  abConduct_iOS
//
//  Created by Reinhard Sasse on 01.11.18.
//  Copyright © 2018 Reinhard Sasse. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/MusicPlayer.h>

NS_ASSUME_NONNULL_BEGIN
@class midiPlayer;
@protocol midiPlayerDelegate

- (void) midiPlayerReachedEnd: (midiPlayer*) player;

@end
@interface midiPlayer : NSObject {
}

@property (nonatomic, weak) id  delegate;
@property MusicPlayer player;
- (instancetype) initWithMidiFile: (NSString*) midiFilePath;
- (void) loadMidiFileFromUrl: (NSURL*) midiFileURL;
- (void) startMidiPlayer;
- (void) stopMidiPlayer;

@end

NS_ASSUME_NONNULL_END