//
//  midiPlayer.h
//  abConduct_iOS
//
//  Created by Reinhard Sasse on 01.11.18.
//  Copyright © 2018 Reinhard Sasse. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/MusicPlayer.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class midiPlayer;
@protocol midiPlayerDelegate

- (void) midiPlayerReachedEnd: (midiPlayer*) player;

@end
@interface midiPlayer : NSObject {
}

@property (nonatomic, weak) id  delegate;
@property MusicPlayer player;
- (instancetype) initWithSoundFontURL: (NSURL*) sfURL;
- (void) loadMidiFileFromUrl: (NSURL*) midiFileURL;
- (void) startMidiPlayer;
- (void) stopMidiPlayer;
- (void) skip: (float) foreward;
@property UIProgressView *progressView;

@end

NS_ASSUME_NONNULL_END
