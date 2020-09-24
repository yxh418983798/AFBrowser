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

/** av */
@property (nonatomic, strong) AVPlayer            *player;

/** av */
@property (nonatomic, strong) AVPlayerLayer           *playerLayer;

/** aa */
@property (nonatomic, strong) AVPlayerItem            *playerItem;

/** af */
@property (nonatomic, strong) AFPlayer            *afplayer;

/** asd */
@property (nonatomic, strong) NSObject            *obj1;
@end

@implementation AFViewController
static NSPointerArray *arr;
static NSArray *array;
- (void)action {
    if ([arr.allObjects containsObject:self.obj1]) {
        [arr removePointerAtIndex:0];
    }
//    self.obj1 = nil;
//    [arr removePointerAtIndex:0];
    NSLog(@"-------------------------- 打：%@--------------------------", arr.allObjects);
    [self.navigationController pushViewController:AFViewController.new animated:YES];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.obj1 = NSObject.new;
    arr = [NSPointerArray pointerArrayWithOptions:NSPointerFunctionsWeakMemory];
    [arr addPointer:(__bridge void *)(self.obj1)];
    
    NSLog(@"-------------------------- 打：%@--------------------------", arr.allObjects);
    
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"push" style:(UIBarButtonItemStylePlain) target:self action:@selector(action)];
    
//    self.playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:@"http://alicfc1.mowang.online/vid/9E9BE3FCEBB93BBDC1956E666506E493.mp4"]];
//    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
//    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
//    self.playerLayer = playerLayer;
////    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
////        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
////    playerLayer.masksToBounds= YES;
//    playerLayer.frame = CGRectMake(10, 100, 200, 200);
//    [self.view.layer addSublayer:self.playerLayer];
//    [self.player play];
//    return;
    
    
//    AFPlayer *player = [AFBrowserViewController productPlayer];
//    player.frame = CGRectMake(15, 100, 300, 300);
////    player.tag = 100;
//    [self.view addSubview:player];
//    player.item = [AFBrowserItem itemWithVideo:@"http://alicfc1.mowang.online/vid/9E9BE3FCEBB93BBDC1956E666506E493.mp4" coverImage:@"http://alicimg8.mowang.online/snapshot/3C5FAE3A970995D8D5F12C6B8862977C.jpg" duration:2 width:0 height:0];
////z    player.item.useCustomPlayer = YES;
//    [player prepare];
//    [player play];
//    self.afplayer = player;
//    return;
    
    
//    NSString *string = @"12";
//    NSString *string1 = string.copy;
//    NSString *string2 = string.mutableCopy;
//    NSString *string3 = string2.mutableCopy;
//    NSString *string4 = string3.copy;
//    NSLog(@"-------------------------- 来了：%p  %p  %p -%p %p-------------------------", string, string1, string2, string3, string4);
//    return;
    
    
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
    return 5;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
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
//    http://alicvid8.mowang.online/vid/C0501F6EA330D2D04F85FF6EA6537349.mp4
//        AFPlayer *player = [AFBrowserViewController productPlayer];
//        player.frame = CGRectMake(15, 10, 100, 100);
//        player.tag = 100;
//        [cell addSubview:player];
    }
//    AFPlayer *player = [cell viewWithTag:100];
//    player.frame = CGRectMake(15, 10, 100, 100);
//    player.item = [AFBrowserItem itemWithVideo:@"http://alicfc1.mowang.online/vid/9E9BE3FCEBB93BBDC1956E666506E493.mp4" coverImage:@"http://alicimg8.mowang.online/snapshot/3C5FAE3A970995D8D5F12C6B8862977C.jpg" duration:2 width:0 height:0];
//    player.item.infiniteLoop = YES;
//    player.item.useCustomPlayer = YES;
//    [player prepare];
//    [player play];
    cell.imageView.image = [UIImage imageNamed:@"image"];
    cell.textLabel.text = [NSString stringWithFormat:@"第%lu个Cell", indexPath.row];
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 120;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
//    AFPlayer *player = [cell viewWithTag:100];
//    [player play];
    [AFBrowserViewController.new.makeDelegate(self).makeBrowserType(AFBrowserTypeDefault).makePageControlType(AFPageControlTypeNone).makeInfiniteLoop(YES).makeUseCustomPlayer(NO).makeSelectedIndex(indexPath.item) browse];
}


- (NSInteger)numberOfItemsInBrowser:(AFBrowserViewController *)browser {
    return 10;
}

- (AFBrowserItem *)browser:(AFBrowserViewController *)browser itemForBrowserAtIndex:(NSInteger)index {
            return [AFBrowserItem itemWithImage:@"http://alicimg8.mowang.online/snapshot/3C5FAE3A970995D8D5F12C6B8862977C.jpg" coverImage:@"http://alicimg8.mowang.online/snapshot/3C5FAE3A970995D8D5F12C6B8862977C.jpg" width:0 height:0];
    if (index > 2) {
        return [AFBrowserItem itemWithImage:@"http://alicimg8.mowang.online/snapshot/3C5FAE3A970995D8D5F12C6B8862977C.jpg" coverImage:@"http://alicimg8.mowang.online/snapshot/3C5FAE3A970995D8D5F12C6B8862977C.jpg" width:0 height:0];
    }
    return [AFBrowserItem itemWithVideo:@"http://alicvid8.mowang.online/vid/C0501F6EA330D2D04F85FF6EA6537349.mp4" coverImage:@"http://alicimg8.mowang.online/snapshot/3C5FAE3A970995D8D5F12C6B8862977C.jpg" duration:2 width:0 height:0];
}

/// 返回转场的View
- (UIView *)browser:(AFBrowserViewController *)browser viewForTransitionAtIndex:(NSInteger)index {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    return cell.imageView;
    return [cell viewWithTag:100];
}

- (void)browser:(AFBrowserViewController *)browser longPressActionAtIndex:(NSInteger)index {
    NSLog(@"-------------------------- 来了老弟：%ld --------------------------", (long)index);
}


@end
