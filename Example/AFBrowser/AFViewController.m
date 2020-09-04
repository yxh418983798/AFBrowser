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
    [AFBrowserViewController.new.makeDelegate(self).makeBrowserType(AFBrowserTypeDefault).makePageControlType(AFPageControlTypeNone).makeInfiniteLoop(YES) browse];
}


- (NSInteger)numberOfItemsInBrowser:(AFBrowserViewController *)browser {
    return 10;
}

- (AFBrowserItem *)browser:(AFBrowserViewController *)browser itemForBrowserAtIndex:(NSInteger)index {
    if (index > 2) {
        return [AFBrowserItem itemWithImage:@"http://alicimg8.mowang.online/snapshot/3C5FAE3A970995D8D5F12C6B8862977C.jpg" coverImage:@"http://alicimg8.mowang.online/snapshot/3C5FAE3A970995D8D5F12C6B8862977C.jpg" width:0 height:0];
    }
    return [AFBrowserItem itemWithVideo:@"http://alicvid8.mowang.online/vid/C0501F6EA330D2D04F85FF6EA6537349.mp4" coverImage:@"http://alicimg8.mowang.online/snapshot/3C5FAE3A970995D8D5F12C6B8862977C.jpg" duration:2 width:0 height:0];
}

/// 返回转场的View
- (UIView *)browser:(AFBrowserViewController *)browser viewForTransitionAtIndex:(NSInteger)index {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    return cell.imageView;
}

- (void)browser:(AFBrowserViewController *)browser longPressActionAtIndex:(NSInteger)index {
    NSLog(@"-------------------------- 来了老弟：%ld --------------------------", (long)index);
}


@end
