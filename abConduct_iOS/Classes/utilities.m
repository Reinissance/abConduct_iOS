//
//  utilities.m
//
// found here: https://gist.github.com/mopsled/4616532, modified


#include "utilities.h"
#import <Foundation/Foundation.h>


FILE *iosfopenw(const char *filename, const char *mode) {
    NSString *webFolder = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"webDAV"];

    NSString *fileString = [NSString stringWithCString:filename encoding:NSASCIIStringEncoding];
    NSString *path = [webFolder stringByAppendingPathComponent:fileString];
    const char *filePath = [path cStringUsingEncoding:NSASCIIStringEncoding];
    
    return fopen(filePath, mode);
}


FILE *iosfopenr(const char *filename, const char *mode) {
    NSString *path = [NSString stringWithUTF8String:filename];
    const char *filePath = [path cStringUsingEncoding:NSASCIIStringEncoding];
    
    return fopen(filePath, mode);
}
