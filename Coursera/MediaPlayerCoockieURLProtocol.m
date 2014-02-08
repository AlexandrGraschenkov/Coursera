//
//  MediaPlayerCoockieURLProtocol.m
//  CourseraTest
//
//  Created by Alexander on 21.01.14.
//  Copyright (c) 2014 Alexander. All rights reserved.
//

#import "MediaPlayerCoockieURLProtocol.h"
//#import "MediaPlayerURL.h"

@interface MediaPlayerCoockieURLProtocol ()
@property (nonatomic, strong) NSURLConnection *connection;
@end

@implementation MediaPlayerCoockieURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
//    BOOL isVideoLink = [request.URL isKindOfClass:[MediaPlayerURL class]];
    BOOL isVideoLink = [request.URL.absoluteString rangeOfString:@"download.mp4"].length > 0;
    BOOL isAlredySetup = [NSURLProtocol propertyForKey:@"CookiesSet" inRequest:request] != nil;
    return isVideoLink && !isAlredySetup;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)startLoading
{
    NSMutableURLRequest* mutReq = [self.request mutableCopy];
    //MYURL => NSURL
    mutReq.URL = [NSURL URLWithString:mutReq.URL.absoluteString];
    
    NSArray* cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:self.request.URL];
    NSDictionary * headers = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
    
    for(NSString* key in headers){
        [mutReq setValue:headers[key] forHTTPHeaderField:key];
    }
    
    [NSURLProtocol setProperty:@YES forKey:@"CookiesSet" inRequest:mutReq];
    self.connection = [NSURLConnection connectionWithRequest:mutReq delegate:self];
}

- (void)stopLoading
{
    [self.connection cancel];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.client URLProtocol:self didLoadData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.client URLProtocol:self didFailWithError:error];
    self.connection = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self.client URLProtocolDidFinishLoading:self];
    self.connection = nil;
}
@end
