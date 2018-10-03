//
//  voiceHandler.h
//  abConduct_iOS
//
//  Created by Reinhard Sasse on 02.10.18.
//  Copyright © 2018 Reinhard Sasse. All rights reserved.
//

@interface voiceHandler : NSObject

@property NSMutableArray *voicePaths;
- (void) createVoices:(NSMutableArray *)voices;

@end
