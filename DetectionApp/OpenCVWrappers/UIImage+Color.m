//
//  NSObject+UIImage_Color.m
//  DetectionApp
//
//  Created by Anton Bal on 3/21/19.
//  Copyright © 2019 Anton Bal'. All rights reserved.
//

#import "UIImage+Color.h"

@implementation UIImage (Color)

- (NSArray*)getRGBAAtX:(int)x andY:(int)y {

    NSMutableArray *result = [NSMutableArray arrayWithCapacity: 4];
    
    // First get the image into your data buffer
    CGImageRef imageRef = [self CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    // Now your rawData contains the image data in the RGBA8888 pixel format.
    NSUInteger byteIndex = (bytesPerRow * y) + x * bytesPerPixel;
    
    CGFloat alpha = ((double) rawData[byteIndex + 3] ) / 255.0f;
    CGFloat red   = ((double) rawData[byteIndex]     ) / alpha;
    CGFloat green = ((double) rawData[byteIndex + 1] ) / alpha;
    CGFloat blue  = ((double) rawData[byteIndex + 2] ) / alpha;
    
    [result addObject: [NSNumber numberWithDouble: red]];
    [result addObject: [NSNumber numberWithDouble: green]];
    [result addObject: [NSNumber numberWithDouble: blue]];
    [result addObject: [NSNumber numberWithDouble: alpha]];
    
    free(rawData);
    
    return result;
}

@end
