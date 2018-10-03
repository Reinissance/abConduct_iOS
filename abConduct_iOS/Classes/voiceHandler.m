//
//  voiceHandler.m
//  abConduct_iOS
//
//  Created by Reinhard Sasse on 02.10.18.
//  Copyright © 2018 Reinhard Sasse. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "voiceHandler.h"
#import "abcm2ps.h"

@implementation voiceHandler

- (void) createVoices:(NSMutableArray *)voices {
    if (self) {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSString *tmpDir = NSTemporaryDirectory();
        NSArray *wasDirectory = [fileManager contentsOfDirectoryAtPath:tmpDir error:nil];
        NSError *error;
        for (NSString *file in wasDirectory) {
            if (![fileManager removeItemAtPath:[tmpDir stringByAppendingPathComponent:file] error:&error]) {
                NSLog(@"couldn´t remove file: %@, reason: %@", error.localizedDescription, error.localizedFailureReason);
            }
        }
        NSString *webFolder = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"webDAV"];
        NSArray *wasWebDirectory = [fileManager contentsOfDirectoryAtPath:webFolder error:nil];
        for (NSString *file in wasWebDirectory) {
            if (![fileManager removeItemAtPath:[webFolder stringByAppendingPathComponent:file] error:&error]) {
                NSLog(@"couldn´t remove file: %@, reason: %@", error.localizedDescription, error.localizedFailureReason);
            }
        }
        for (NSArray *voice in voices) {
            if (![voice[1] writeToFile:[[tmpDir stringByAppendingPathComponent:voice[0]] stringByAppendingPathExtension:@"abc"] atomically:YES encoding:NSASCIIStringEncoding error:&error]) {
                NSLog(@"couln't write file: %@, reason: %@", error.localizedDescription, error.localizedFailureReason);
            }
        }
        if (![[NSFileManager defaultManager] fileExistsAtPath:webFolder])
            [[NSFileManager defaultManager] createDirectoryAtPath:webFolder withIntermediateDirectories:NO attributes:nil error:&error];
        if (error) {
            NSLog(@"couldn't create webDAV-folder: %@, reason: %@", error.localizedDescription, error.localizedFailureReason);
            return;
        }
        NSArray *isDirectory = [fileManager contentsOfDirectoryAtPath:tmpDir error:nil];
        NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.abc'"];
        NSArray *voiceAbcFiles = [isDirectory filteredArrayUsingPredicate:fltr];
        _voicePaths = [NSMutableArray arrayWithCapacity:voiceAbcFiles.count];
        for (int i = 0; i < voiceAbcFiles.count; i++) {
            NSString *abcFile = voiceAbcFiles[i];
            [self createSVGFileFromFilePath:abcFile forArrayindex:i inDirectory:tmpDir];
        }
    }
}

- (void) createSVGFileFromFilePath: (NSString*) abcFile forArrayindex: (int) index inDirectory: (NSString*) dir {
    NSString *filename = [[abcFile substringToIndex:[abcFile lastPathComponent].length-4] stringByAppendingPathExtension:@"svg"];
    NSString *outFile = [NSString stringWithFormat:@"-O%@", filename];
    char *open = strdup([@"-O" UTF8String]);
    char *svg = strdup([@"-X" UTF8String]);
    const char *outPath = strdup([outFile UTF8String]);
    char *duppedOut = strdup(outPath);
    char *duppedSVG = strdup(svg);
    char *inPath = strdup([[dir stringByAppendingPathComponent: abcFile] UTF8String]);
    char *args[] = {open, duppedOut, duppedSVG, inPath, NULL };
    abcMain(4, args);
    [_voicePaths addObject: filename];
}

@end
