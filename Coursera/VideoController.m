//
//  VideoController.m
//  Coursera
//
//  Created by Alexander on 08.02.14.
//  Copyright (c) 2014 Alexander. All rights reserved.
//

#import "VideoController.h"
@import MediaPlayer;

@interface VideoController ()
{
    MPMoviePlayerController* playerController;
}
@end

@implementation VideoController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSURL* videoUrl = [NSURL URLWithString:self.videoURLStr];
    playerController = [[MPMoviePlayerController alloc] initWithContentURL:videoUrl];
    playerController.view.frame = self.view.bounds;
    playerController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:playerController.view];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [playerController prepareToPlay];
    [playerController play];
    NSLog(@"%@", self.videoURLStr);
}

@end
