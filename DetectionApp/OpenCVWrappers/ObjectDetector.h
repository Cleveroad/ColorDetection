//
//  ObjectDetector.h
//  DetectionApp
//
//  Created by Anton Bal on 3/28/19.
//  Copyright © 2019 Anton Bal'. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
struct DetectingObject {
    std::vector<cv::Scalar> detectingColors;
    cv::Scalar fillingColor;
};
#endif

@interface ObjectDetector : NSObject

#ifdef __cplusplus
-(void)setOffset:(float) offset;
-(void)setHSVRangeValueWithHValue:(float) h sValue:(float) s vValue:(float) v;
- (cv::Mat) fillImg:(cv::Mat&) img withDetectingObject:(DetectingObject) obj;
#endif

@end

NS_ASSUME_NONNULL_END
