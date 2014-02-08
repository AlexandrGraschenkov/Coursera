//
//  LecturesController.m
//  Coursera
//
//  Created by Alexander on 08.02.14.
//  Copyright (c) 2014 Alexander. All rights reserved.
//

#import "LecturesController.h"
#import <MBProgressHUD.h>
#import "NetManager.h"
#import "VideoController.h"

@interface LecturesController ()
{
    NSMutableArray* presentData;
}
@end

@implementation LecturesController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(!presentData)
        [self reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"showVideo"]){
        NSIndexPath* idxPath = [self.tableView indexPathForSelectedRow];
        NSDictionary* lectureDic = presentData[idxPath.row];
        VideoController* vc = segue.destinationViewController;
        vc.videoURLStr = lectureDic[@"video_link"];
    }
}

- (void)reloadData
{
    MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [[NetManager sharedInstance] getLecturesWithClassURLString:self.courseHomeLink complection:^(NSArray *weeks, NSString *errorStr)
    {
        if(errorStr){
            hud.detailsLabelText = errorStr;
            [hud hide:YES afterDelay:2.0];
        } else {
            [hud hide:YES];
            [self lecturesLoaded:weeks];
        }
    }];
}

- (void)lecturesLoaded:(NSArray*)weeks
{
    presentData = [NSMutableArray new];
    for(NSDictionary* weekDic in weeks){
        [presentData addObject:weekDic];
        for(NSDictionary* lectureDic in weekDic[@"lectures"])
            [presentData addObject:lectureDic];
    }
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return presentData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.text = presentData[indexPath.row][@"name"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary* dic = presentData[indexPath.row];
    if(dic[@"lectures"]){
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    [self performSegueWithIdentifier:@"showVideo" sender:self];
}

@end
