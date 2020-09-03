//
//  AFViewController.m
//  AFBrowser
//
//  Created by yxh418983798 on 09/01/2020.
//  Copyright (c) 2020 yxh418983798. All rights reserved.
//

#import "AFViewController.h"
#import "AFBrowserViewController.h"
#import <Masonry.h>
@interface AFViewController () <UITableViewDelegate, UITableViewDataSource, AFBrowserDelegate>
/** i */
@property (nonatomic, strong) UITableView            *tableView;
@end

@implementation AFViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    
    _tableView = [[UITableView alloc] initWithFrame:(CGRectMake(0, 40, self.view.frame.size.width, self.view.frame.size.height)) style:(UITableViewStylePlain)];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
    
}

#pragma mark -- 旋转控制
- (BOOL)shouldAutorotate{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationPortrait;
}


#pragma mark - UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 100;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleValue1) reuseIdentifier:@"UITableViewCell"];
        [cell.imageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.offset(15);
            make.width.height.offset(100);
            make.centerY.offset(0);
        }];
    }
    cell.imageView.image = [UIImage imageNamed:@"image"];
    cell.textLabel.text = [NSString stringWithFormat:@"第%lu个Cell", indexPath.row];
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 120;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AFBrowserViewController *browserVc = AFBrowserViewController.new.makeDelegate(self).makeBrowserType(AFBrowserTypeDelete).makePageControlType(AFPageControlTypeText);
    [browserVc addItem:[AFBrowserItem imageItem:[UIImage imageNamed:@"image"] coverImage:nil identifier:nil]];
    [browserVc addItem:[AFBrowserItem imageItem:[UIImage imageNamed:@"image"] coverImage:nil identifier:nil]];
    [browserVc addItem:[AFBrowserItem imageItem:[UIImage imageNamed:@"image"] coverImage:nil identifier:nil]];
    [browserVc addItem:[AFBrowserItem imageItem:[UIImage imageNamed:@"image"] coverImage:nil identifier:nil]];
    [browserVc addItem:[AFBrowserItem imageItem:[UIImage imageNamed:@"image"] coverImage:nil identifier:nil]];
    [browserVc addItem:[AFBrowserItem imageItem:[UIImage imageNamed:@"image"] coverImage:nil identifier:nil]];
    [browserVc browse];
}


/// 返回转场的View
- (UIView *)browser:(AFBrowserViewController *)browser viewForTransitionAtIndex:(NSInteger)index {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    return cell.imageView;
}




@end
