//
//  abcRenderer.m
//  abConduct_iOS
//
//  Created by Reinhard Sasse on 29.09.18.
//  Copyright © 2018 Reinhard Sasse. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "abcRenderer.h"
#import "abcm2ps.h"


@implementation abcRenderer

- (instancetype) initWithAbcFile: (NSString*) abcFile {

    NSString *filename = [[[abcFile lastPathComponent] substringToIndex:[abcFile lastPathComponent].length-4] stringByAppendingPathExtension:@"svg"];
    NSString *outFile = [NSString stringWithFormat:@"-O %@", filename];
    char *open = strdup([@"-O" UTF8String]);
    char *svg = strdup([@"-X" UTF8String]);
    const char *outPath = strdup([outFile UTF8String]);
    char *duppedOut = strdup(outPath);
    char *duppedSVG = strdup(svg);
    char *inPath = strdup([abcFile UTF8String]);
    char *args[] = {open, duppedOut, duppedSVG, inPath, NULL };
    abcMain(4, args);
    
    NSString *webfolder = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Web"];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *directory = [fileManager contentsOfDirectoryAtPath:webfolder error:nil];
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.svg'"];
    NSArray *files = [directory filteredArrayUsingPredicate:fltr];

    _svgFilePaths = [NSMutableArray array];
    for (NSString *file in files) {
        [_svgFilePaths addObject:[webfolder stringByAppendingPathComponent:file]];
    }
    
    return self;
}
@end
