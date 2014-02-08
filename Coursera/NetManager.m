//
//  NetManager.m
//  CourseraTutorial
//
//  Created by Alexander on 07.02.14.
//  Copyright (c) 2014 Alexander. All rights reserved.
//

#import "NetManager.h"
#import "TFHpple.h"

#define APP_SERVICE_LOGIN_PASS  (@"ru.bars-open.CourseraTestLoginPass")

@interface NetManager()
{
    NSOperationQueue* queue;
}
@end

@implementation NetManager
+ (instancetype)sharedInstance
{
    static id _singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _singleton = [[NetManager alloc] init];
    });
    return _singleton;
}

- (id)init
{
    self = [super init];
    if(!self) return nil;
    
    [self loadAutorizationParametrsFromKeychaing];
    queue = [[NSOperationQueue alloc] init];
    return self;
}

- (void)setEmail:(NSString *)email
{
    if([_email isEqualToString:email])
        return;
    
    _email = email;
    [self saveAutriationParametrsToKeychain];
}

- (void)setPassword:(NSString *)password
{
    if([_password isEqualToString:password])
        return;
    
    _password = password;
    [self saveAutriationParametrsToKeychain];
}

- (void)loadAutorizationParametrsFromKeychaing
{
    NSDictionary* preferences = [self.class loadKeychain:APP_SERVICE_LOGIN_PASS];
    _email = preferences[@"email"];
    _password = preferences[@"password"];
}

- (void)saveAutriationParametrsToKeychain
{
    NSMutableDictionary* preferences = [NSMutableDictionary new];
    if(_email)
        preferences[@"email"] = _email;
    if(_password)
        preferences[@"password"] = _password;
    [self.class saveKeychain:APP_SERVICE_LOGIN_PASS data:preferences];
}

#pragma mark - Keychain
+ (NSMutableDictionary *)getKeychainQuery:(NSString *)service
{
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            (__bridge id)kSecClassGenericPassword, (__bridge id)kSecClass,
            service, (__bridge id)kSecAttrService,
            service, (__bridge id)kSecAttrAccount,
            (__bridge id)kSecAttrAccessibleAfterFirstUnlock, (__bridge id)kSecAttrAccessible,
            nil];
}

+ (void)saveKeychain:(NSString *)service data:(id)data
{
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:data] forKey:(__bridge id)kSecValueData];
    SecItemAdd((__bridge CFDictionaryRef)keychainQuery, NULL);
}

+ (id)loadKeychain:(NSString *)service
{
    id ret = nil;
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    [keychainQuery setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [keychainQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    CFDataRef keyData = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr) {
        @try {
            ret = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)keyData];
        }
        @catch (NSException *e) {
            NSLog(@"Unarchive of %@ failed: %@", service, e);
        }
        @finally {}
    }
    if (keyData) CFRelease(keyData);
    return ret;
}

+ (void)deleteKeychain:(NSString *)service
{
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
}

#pragma mark - Requests
NSString * const letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
- (NSString*)generateCsrfToken
{
    int length = arc4random() % 10 + 5;
    NSMutableString* str = [NSMutableString new];
    while (length >= 0) {
        int pos = arc4random() % letters.length;
        NSString* charStr = [letters substringWithRange:NSMakeRange(pos, 1)];
        [str appendString:charStr];
        length--;
    }
    return str;
}

- (void)autorizeWithComplection:(void(^)(BOOL success, NSString* errorStr))complection
{
    NSString* csrfToken = [self generateCsrfToken];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://accounts.coursera.org/api/v1/login"]];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[@"csrftoken=" stringByAppendingString:csrfToken] forHTTPHeaderField:@"Cookie"];
    [request setValue:@"https://accounts.coursera.org/signin" forHTTPHeaderField:@"Referer"];
    [request setValue:csrfToken forHTTPHeaderField:@"X-CSRFToken"];
    [request setHTTPMethod:@"POST"];
    
    
    NSDictionary* parametrs = @{@"email" : self.email, @"password" : self.password};
    NSError* err;
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:parametrs options:0 error:&err];
    if(err){
        if(complection)
            complection(NO, err.localizedDescription);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSHTTPURLResponse* resp;
        NSError* err;
        [NSURLConnection sendSynchronousRequest:request returningResponse:&resp error:&err];
        if(!complection)
            return;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(resp.statusCode == 200){
                complection(YES, nil);
            } else {
                NSLog(@"%d", resp.statusCode);
                complection(NO, err.localizedDescription);
            }
        });
    });
}

- (void)getRequestWithURL:(NSURL*)url
               complection:(void(^)(NSData* responseData, NSString* errorStr))complection
{
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"GET"];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSHTTPURLResponse* resp;
        NSError* err;
        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&resp error:&err];
        if(!complection)
            return;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(resp.statusCode == 200){
                complection(data, nil);
            } else {
                NSLog(@"%d", resp.statusCode);
                if(resp.statusCode == 403)
                    complection(nil, @"Wrong email or password");
                else
                    complection(nil, err.localizedDescription);
            }
        });
    });
}

- (void)getCoursesArr:(void(^)(NSArray* courses, NSString* errorStr))complection
{
    [self getRequestWithURL:[NSURL URLWithString:@"https://www.coursera.org/maestro/api/topic/list_my"]
                complection:^(NSData *responceData, NSString *errorStr)
     {
         if(errorStr){
             if(complection)
                 complection(nil, errorStr);
             return;
         }
         NSArray* loadedArr = [NSJSONSerialization JSONObjectWithData:responceData options:0 error:0];
         NSMutableArray* result = [NSMutableArray new];
         for(NSDictionary* courseGroupDic in loadedArr){
             for(NSDictionary* courseDic in courseGroupDic[@"courses"]){
                 NSMutableDictionary* course = [NSMutableDictionary new];
                 course[@"icon_link"] = courseGroupDic[@"large_icon"];
                 course[@"name"] = courseGroupDic[@"name"];
                 course[@"course_link"] = courseDic[@"home_link"];
                 [result addObject:course];
             }
         }
         complection(result, nil);
     }];
}

#pragma mark - Lectures
- (void)getLecturesWithClassURLString:(NSString*)classURLString complection:(void(^)(NSArray* weeks, NSString* errMsg))complection
{
    classURLString = [classURLString stringByAppendingString:@"lecture/"];
    [self getRequestWithURL:[NSURL URLWithString:classURLString]
                complection:^(NSData *responseData, NSString *errorStr)
     {
         if(!complection)
             return;
         
         if(errorStr)
             complection(nil, errorStr);
         else
             [self getLecturesFromHTMLData:responseData complection:complection];
     }];
}

- (void)getLecturesFromHTMLData:(NSData*)htmlData complection:(void(^)(NSArray* weeks, NSString* errMsg))complection
{
    TFHpple* hpple = [TFHpple hppleWithHTMLData:htmlData];
    NSArray* arr = [hpple searchWithXPathQuery:@"//div[@class='course-item-list']"];
    NSMutableArray* weeksArr = [NSMutableArray new];
    NSMutableDictionary* week;
    for (TFHppleElement* elem in arr) {
        for(TFHppleElement* weekElem in elem.children){
            if([self isElemContainsTitle:weekElem]){//week
                week = [NSMutableDictionary new];
                [weeksArr addObject:week];
                week[@"name"] = [self getWeekName:weekElem];
            } else if([weekElem.tagName isEqualToString:@"ul"] && [weekElem.attributes[@"class"] isEqualToString:@"course-item-list-section-list"]){
                week[@"lectures"] = [self getWeekLectures:weekElem];
            }
        }
    }
    if(complection)
        complection(weeksArr, nil);
}

- (BOOL)isElemContainsTitle:(TFHppleElement*)weekElem
{
    if(![weekElem.tagName isEqualToString:@"div"])
        return NO;
    
    NSArray* allowClasses = @[@"course-item-list-header expanded", @"course-item-list-header contracted"];
    BOOL isAllowClass = NO;
    for(NSString* allowClassName in allowClasses){
        isAllowClass |= [weekElem.attributes[@"class"] isEqualToString:allowClassName];
        if(isAllowClass)
            break;
    }
    return isAllowClass;
}

- (NSString*)getWeekName:(TFHppleElement*)elem
{
    NSArray* arr = [elem searchWithXPathQuery:@"//h3"];
    elem = arr.count == 0? nil : [arr firstObject];
    return [elem.text stringByReplacingOccurrencesOfString:@"\n" withString:@""];
}

- (NSArray*)getWeekLectures:(TFHppleElement*)elem
{
    NSArray* lectureElems = [elem searchWithXPathQuery:@"//li"];
    NSMutableArray* result = [NSMutableArray new];
    for(id obj in lectureElems){
        [result addObject:[self getLecture:obj]];
    }
    return result;
}

- (NSMutableDictionary*)getLecture:(TFHppleElement*)elem
{
    NSMutableDictionary* resultLecture = [NSMutableDictionary new];
    
    //name
    NSArray* nameArr = [elem searchWithXPathQuery:@"//a"];
    TFHppleElement* nameElem = nameArr.count? [nameArr firstObject] : nil;
    resultLecture[@"name"] = [nameElem.text stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    //links
    NSArray* resourcesArr = [elem searchWithXPathQuery:@"//div[@class='course-lecture-item-resource']/a"];
    for(TFHppleElement* resLinkElem in resourcesArr){
        if([self isSubtitleLink:resLinkElem])
            resultLecture[@"subtitles_link"] = resLinkElem.attributes[@"href"];
        else if([self isLectureLink:resLinkElem])
            resultLecture[@"video_link"] = resLinkElem.attributes[@"href"];
    }
    return resultLecture;
}

- (BOOL)isSubtitleLink:(TFHppleElement*)elem
{
    NSString* href = elem.attributes[@"href"];
    return [href rangeOfString:@"format=srt"].length && [href rangeOfString:@"subtitles"].length;
}

- (BOOL)isLectureLink:(TFHppleElement*)elem
{
    NSString* href = elem.attributes[@"href"];
    return [href rangeOfString:@"download.mp4"].length;
}
@end
