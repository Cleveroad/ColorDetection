//
//  NSObject+UIImage_Color.h
//  DetectionApp
//
//  Created by Anton Bal on 3/21/19.
//  Copyright © 2019 Anton Bal'. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Color)

- (NSArray*)getRGBAAtX:(int)x andY:(int)y;
@end

NS_ASSUME_NONNULL_END
