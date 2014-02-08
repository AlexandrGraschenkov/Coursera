//
//  CoursesController.m
//  Coursera
//
//  Created by Alexander on 08.02.14.
//  Copyright (c) 2014 Alexander. All rights reserved.
//

#import "CoursesController.h"
#import "NetManager.h"
#import <MBProgressHUD.h>
#import "CourseCell.h"
#import "LecturesController.h"

@interface CoursesController ()
{
    NSArray* coursesArr;
}
@end

@implementation CoursesController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(!coursesArr)
        [self reloadData];
}

- (void)reloadData
{
    MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [[NetManager sharedInstance] getCoursesArr:^(NSArray *courses, NSString *errorStr) {
        if(errorStr){
            hud.detailsLabelText = errorStr;
            [hud hide:YES afterDelay:2.0];
        } else {
            [hud hide:YES];
            coursesArr = courses;
            NSLog(@"%@", coursesArr);
            [self.collectionView reloadData];
        }
    }];
}

- (IBAction)logoutPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"showLectures"]){
        NSIndexPath* indexPath = [self.collectionView indexPathsForSelectedItems][0];
        NSMutableDictionary* course = coursesArr[indexPath.row];
        
        LecturesController* lecturesController = segue.destinationViewController;
        lecturesController.courseHomeLink = course[@"course_link"];
    }
}

#pragma mark - Colleciton

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CourseCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.courseDic = coursesArr[indexPath.row];
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return coursesArr.count;
}

@end
