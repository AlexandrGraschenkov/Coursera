//
//  NetManager.h
//  CourseraTutorial
//
//  Created by Alexander on 07.02.14.
//  Copyright (c) 2014 Alexander. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetManager : NSObject
+ (instancetype)sharedInstance;
@property (nonatomic, strong) NSString* email;
@property (nonatomic, strong) NSString* password;

- (void)autorizeWithComplection:(void(^)(BOOL success, NSString* errorStr))complection;

- (void)getRequestWithURL:(NSURL*)url
              complection:(void(^)(NSData* responseData, NSString* errorStr))complection;

// course = {name, icon?, icon_link, course_link}
- (void)getCoursesArr:(void(^)(NSArray* courses, NSString* errorStr))complection;

// week = {name, lectures}
// lecture = {video_link, subtitle_link, name}
- (void)getLecturesWithClassURLString:(NSString*)classURLString complection:(void(^)(NSArray* weeks, NSString* errMsg))complection;

@end
