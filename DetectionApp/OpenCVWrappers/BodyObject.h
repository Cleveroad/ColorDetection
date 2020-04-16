//
//  BodyObject.h
//  DetectionApp
//
//  Created by Anton Bal' on 2/13/19.
//  Copyright © 2019 Anton Bal'. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface BodyObject : NSObject

@property (assign, nonatomic) CGRect head;
@property (strong, nonatomic) NSArray<NSValue*>* shoulders;

@end

NS_ASSUME_NONNULL_END
