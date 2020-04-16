//
//  BodyDetector.m
//  DetectionApp
//
//  Created by Anton Bal' on 1/17/19.
//  Copyright © 2019 Anton Bal'. All rights reserved.
//

#import "BodyDetector.h"
#import "UIImage+OpenCV.h"

using namespace cv;
using namespace std;

typedef cv::Point CVPoint;

@interface BodyDetector()
{
    CascadeClassifier bodyCascade;
    dispatch_queue_global_t background;
}

@end

@implementation BodyDetector

- (instancetype)initWithType:(BodyDetectorType)type {
    self = [super init];
    
    if (self) {
        
        NSString* resource;
        
        switch (type) {
            case BodyDetectorTypeUpperBody:
                resource = @"haarcascade_upperbody.xml";
                break;
            case BodyDetectorTypeLowerBody:
                resource = @"haarcascade_lowerbody.xml";
                break;
                
            case BodyDetectorTypeFullBody:
                resource = @"haarcascade_fullbody.xml";
                break;
                
            case BodyDetectorTypeFace:
                resource = @"haarcascade_frontalface_alt.xml";
                break;
            default:
                break;
        }
        
        NSString *path = [[NSBundle mainBundle] pathForResource:resource ofType:nil];
        std::string cascade_path = (char *)[path UTF8String];
        if (!bodyCascade.load(cascade_path)) {
            NSLog(@"Couldn't load haar cascade file.");
        }
        
        background = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

- (void) detectImageRef:(CVImageBufferRef) pixelBuffer size:(CGSize) size scale:(NSInteger) scale completed:(CompletedBlock)block {
    
    @autoreleasepool {
        
        OSType format = CVPixelBufferGetPixelFormatType(pixelBuffer);
        CGRect videoRect = CGRectMake(0.0f, 0.0f, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
        cv::Mat mat;
        
        CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
        
        if (format == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
            // For grayscale mode, the luminance channel of the YUV data is used
            void *baseaddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
            
            mat = Mat(videoRect.size.height, videoRect.size.width, CV_8UC1, baseaddress, 0);
        } else if (format == kCVPixelFormatType_32BGRA) {
            // For color mode a 4-channel cv::Mat is created from the BGRA data
            void *baseaddress = CVPixelBufferGetBaseAddress(pixelBuffer);
            
            mat = Mat(videoRect.size.height, videoRect.size.width, CV_8UC4, baseaddress, 0);
        } else {
            NSLog(@"Unsupported video format");
            return;
        }
        
        cv::resize(mat, mat, cvSize(size.height / scale, size.width / scale));
        BodyObject* body = [self detecBodyForMat:mat];
        
        block(body);
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    }
}

- (cv::Mat) detect:(cv::Mat) image {
    vector<cv::Rect> objects;
    
    bodyCascade.detectMultiScale(image, objects);
    
    Mat detected;
    
    if (objects.size() > 0) {
        const cv::Rect rect = objects[0];
        rectangle(image, rect, CV_RGB(255, 0, 0));
        detected = image(rect);
    }
    
    return detected;
}

- (BodyObject*)detecBodyForMat:(cv::Mat)img {
    
    vector<cv::Rect> objects;
    
    bodyCascade.detectMultiScale(img, objects);
    
    BodyObject* body;
    
    if (objects.size() > 0) {
        body = [[BodyObject alloc] init];
        const cv::Rect faceRectangle = objects[0];

        body.head = CGRectMake(faceRectangle.x, faceRectangle.y, faceRectangle.width, faceRectangle.height);

        rectangle(img, faceRectangle, CV_RGB(255, 50, 50));
        
        auto y = faceRectangle.y + faceRectangle.height + faceRectangle.width / 2;
      
        Mat drawing;
        
        bool found = false;
        
        NSMutableArray* shoulders = [[NSMutableArray alloc] init];
        
        // Auto find lines
        auto point1 = cvPoint(0, y);
        auto point2 = cvPoint(INT_MAX, y);
        
        LineIterator it(drawing, point1, point2, 8);
        
        //Try to find intersection of a contour and line
        for(int nbPt = 0; nbPt < it.count; nbPt++, ++it) {
            cv::Point pos = it.pos();
            if (drawing.at<uchar>(pos) != 0) {
                [shoulders addObject: [NSValue valueWithCGPoint: CGPointMake(pos.x, pos.y)]];
                found = true;
            }
        }
        
        if (!found) { // If not found to calculate it
            y = MIN(y, img.rows);
            auto middleX = faceRectangle.x + faceRectangle.width / 2;
            auto point1 = cvPoint(MAX(middleX - faceRectangle.height, 0), y);
            auto point2 = cvPoint(MIN(middleX + faceRectangle.height, img.cols), y);
            [shoulders addObject: [NSValue valueWithCGPoint: CGPointMake(point1.x, point1.y)]];
            [shoulders addObject: [NSValue valueWithCGPoint: CGPointMake(point2.x, point2.y)]];
        }
        
        body.shoulders = shoulders;
    }
    
    return body;
}

-(cv::Mat) drawBody: (BodyObject*) body toImage:(cv::Mat)img{
    
    auto color = CV_RGB(255, 50, 50);
    auto head = cv::Rect(CGRectGetMinX(body.head), CGRectGetMinY(body.head), CGRectGetWidth(body.head), CGRectGetHeight(body.head));
    
    rectangle(img, head, color);
    
    for (NSUInteger i = 0; i < [body.shoulders count]; i++) {
        CGPoint value = ((NSValue *)body.shoulders[i]).CGPointValue;
        auto point = cvPoint(value.x, value.y);
        circle(img, point, 8, color);
    }
    
    return img;
}

#pragma mark - Private detection methods

- (Mat) makeHandMaskFor:(Mat&) img {
    
    Mat mask = img;
    cv::Size blurSize(3,3);
    
    cvtColor(img, mask, CV_BGR2GRAY);
    
    blur(mask, mask, blurSize);
    threshold(mask, mask, 90, 255, THRESH_BINARY);
    
    return mask;
}

@end
