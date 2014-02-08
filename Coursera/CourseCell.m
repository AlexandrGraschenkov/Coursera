//
//  CourseCell.m
//  Coursera
//
//  Created by Alexander on 08.02.14.
//  Copyright (c) 2014 Alexander. All rights reserved.
//

#import "CourseCell.h"
#import "NetManager.h"

@interface CourseCell()
{}
@property (nonatomic, weak) IBOutlet UILabel* title;
@property (nonatomic, weak) IBOutlet UIImageView* imgView;
@end

@implementation CourseCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setCourseDic:(NSMutableDictionary *)courseDic
{
    if(courseDic == _courseDic) return;
    
    _courseDic = courseDic;
    self.title.text = _courseDic[@"name"];
    NSURL* iconURL = [NSURL URLWithString:_courseDic[@"icon_link"]];
    [[NetManager sharedInstance] getRequestWithURL:iconURL
                                       complection:^(NSData *responseData, NSString *errorStr)
     {
         UIImage* img = [UIImage imageWithData:responseData];
         if(!img)
             return;
         
         courseDic[@"icon"] = img;
         if(courseDic != self.courseDic)
             return;
         
         self.imgView.image = img;
     }];
}

@end
