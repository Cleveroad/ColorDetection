//
//  ObjectDetector.m
//  DetectionApp
//
//  Created by Anton Bal on 3/28/19.
//  Copyright © 2019 Anton Bal'. All rights reserved.
//

#import "ObjectDetector.h"
#import "UIImage+OpenCV.h"

using namespace cv;
using namespace std;

struct RGBColor {
    double r;
    double g;
    double b;
};

struct HSVColor {
    double h;
    double s;
    double v;
};

@interface ObjectDetector()

@property (nonatomic, assign) float hRangeValue;
@property (nonatomic, assign) float sRangeValue;
@property (nonatomic, assign) float vRangeValue;
@property (nonatomic, assign) float offsetValue;

@end

@implementation ObjectDetector

#pragma mark - Public

-(void)setOffset:(float) offset {
    self.offsetValue = offset;
}

-(void)setHSVRangeValueWithHValue:(float) h sValue:(float) s vValue:(float) v {
    self.hRangeValue = h;
    self.sRangeValue = s;
    self.vRangeValue = v;
}

- (cv::Mat) fillImg:(cv::Mat&) img withDetectingObject:(DetectingObject) obj {
    
    Mat mask1, mask2, hsv;
    
    //Converting image from BGR to HSV color space.
    cvtColor(img, hsv, COLOR_BGR2HSV);
    
    vector<HSVColor> detectingColors(obj.detectingColors.size());
    Scalar fillingHSVColor = [self bgrScalarToHSVScalar: obj.fillingColor];
   
    for (int i = 0; i < obj.detectingColors.size(); i++)
        detectingColors[i] = [self bgrScalar2HSVColor: obj.detectingColors[i]];
    
    // Generating the final mask
    HSVColor hsvRange = HSVColor();
    hsvRange.h = self.hRangeValue;
    hsvRange.s = self.sRangeValue;
    hsvRange.v = self.vRangeValue;
    
    mask1 = maskForImage(hsv, detectingColors, hsvRange);
    
    cv::Size blurSize(8,8);
    blur(mask1, mask1, blurSize);
    threshold(mask1, mask1, 50, 255, THRESH_BINARY);
    
    Mat kernel = Mat::ones(3,3, CV_32F);
    morphologyEx(mask1, mask1, cv::MORPH_OPEN, kernel);
    morphologyEx(mask1, mask1, cv::MORPH_DILATE, kernel);
    
    Mat background = Mat(hsv.rows, hsv.cols, hsv.type(), Scalar(fillingHSVColor[0], NAN, NAN));
    
    for (int i = 0; i < background.cols; i++) {
        for (int j = 0; j < background.rows; j++) {
            CvPoint point = cvPoint(i, j);
            background.at<Vec3b>(point).val[1] = MIN(hsv.at<Vec3b>(point).val[1] + self.offsetValue, 255);
            background.at<Vec3b>(point).val[2] = MIN(hsv.at<Vec3b>(point).val[2] + self.offsetValue, 255);
        }
    }
    
    cvtColor(background, background, COLOR_HSV2BGR);
    
    // creating an inverted mask to segment out the object from the frame
    bitwise_not(mask1, mask2);
     
    Mat res1, res2, final_output;
     
    // Segmenting the object out of the frame using bitwise and with the inverted mask
    bitwise_and(img, img, res1, mask2);
    
    // creating image showing static background frame pixels only for the masked region
    bitwise_and(background, background, res2, mask1);
    
    // Generating the final augmented output.
    cv::add(res1, res2, final_output);

    return final_output;
}

#pragma mark - Private

cv::Mat maskForImage(Mat image, vector<HSVColor> colors, HSVColor hsv) {

    Mat mask;
    
    // Creating masks to detect the upper and lower red color.
    ///The Hue values are actually distributed over a circle (range between 0-360 degrees) but in OpenCV to fit into 8bit value the range is from 0-180.
    
    for (int i = 0; i < colors.size(); i++)  {
      
        Mat mask1, mask2;
        HSVColor hlsColor = colors[i];
        
        auto h = hlsColor.h;
        auto s = hlsColor.s;
        auto v = hlsColor.v;
        
        auto hMin = h - hsv.h;
        auto hMax = h + hsv.h;
        auto sMin = s - hsv.s;
        auto sMax = s + hsv.s;
        auto vMin = v - hsv.v;
        auto vMax = v + hsv.v;
        
        if (hMin < 0) {
            hMin = 180 + hMin;
        }
        
        if (hMax > 180) {
            hMax = 0;
        }
        
        if (sMin < 0) {
            sMin = hsv.s + sMin;
        }
        
        if (vMin < 0) {
            vMin = hsv.v + vMin;
        }
        
        auto temp = hMin;
        hMin = MIN(hMin, hMax);
        hMax = MAX(temp, hMax);
        
        inRange(image, Scalar(hMin, sMin, vMin), Scalar(hMin + hsv.h, MIN(sMax + hsv.s, 255), MIN(vMax + hsv.v, 255)), mask1);
        inRange(image, Scalar(hMax, sMin, vMin), Scalar(hMax + hsv.h, MIN(sMax + hsv.s, 255), MIN(vMax + hsv.v, 255)), mask2);
        
        // Generating the final mask
        
        if (mask.size().empty()) {
            mask = mask1 + mask2;
        } else {
            mask = mask + mask1 + mask2;
        }
    }
    
    return mask;
}

-(HSVColor)bgrScalar2HSVColor:(Scalar) bgrScalar
{
    ///https://en.wikipedia.org/wiki/HSL_and_HSV#Use_in_image_analysis
    RGBColor bgr = RGBColor();
    bgr.r = bgrScalar[2];
    bgr.g = bgrScalar[1];
    bgr.b = bgrScalar[0];
    
    HSVColor         hsv;
    double      min, max, delta;
    
    bgr.r = bgr.r / 255;
    bgr.b = bgr.b / 255;
    bgr.g = bgr.g / 255;
    
    min = MIN(bgr.b, MIN(bgr.r, bgr.g));
    max = MAX(bgr.b, MAX(bgr.r, bgr.g));
    delta = max - min;
    
    auto percet60in255 = 30;
    
    if (delta < 0.0001) {
        hsv.h = 0;
    } else if (max == bgr.r) {
        hsv.h = percet60in255 * ((bgr.g - bgr.b) / delta);
    } else if (max == bgr.g) {
        hsv.h = percet60in255 * (2 + (bgr.b - bgr.r) / delta);
    } else if (max == bgr.b) {
        hsv.h = percet60in255 * (4 + (bgr.r - bgr.g) / delta);
    }
    
    if (hsv.h < 0) {
        hsv.h += 180;
    }
    
    if (max == 0) {
        hsv.s = 0;
    } else {
        hsv.s = delta / max;
    }
    
    hsv.s *= 255;
    hsv.v = max * 255;
    
    return hsv;
}

-(Scalar)bgrScalarToHSVScalar:(Scalar) bgrScalar {
    Mat hsv;
    Mat bgr(1,1, CV_8UC3, bgrScalar);
    cvtColor(bgr, bgr, COLOR_BGRA2BGR);
    cvtColor(bgr, hsv, CV_BGR2HSV);
    return Scalar(hsv.data[0], hsv.data[1], hsv.data[2]);
}

@end
