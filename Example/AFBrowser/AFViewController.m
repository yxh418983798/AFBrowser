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
#import <SDWebImage/SDWebImage.h>

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

/** data */
@property (nonatomic, strong) NSMutableArray            *data;

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
//    NSLog(@"-------------------------- 打：%@--------------------------", arr.allObjects);
    [self.navigationController pushViewController:AFViewController.new animated:YES];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.data = NSMutableArray.new;

    NSString *path = [[NSBundle mainBundle] pathForResource:@"timeline" ofType:@"txt"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSArray *array = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:NULL];

    for (NSDictionary *dic in array) {
        [self.data addObjectsFromArray:[dic valueForKey:@"images"]];
    }
//    for (int i = 0; i < 10; i++) {
//        [self.data addObject:[AFBrowserItem itemWithImage:@"http://alicimg8.mowang.online/snapshot/3C5FAE3A970995D8D5F12C6B8862977C.jpg" coverImage:@"http://alicimg8.mowang.online/snapshot/3C5FAE3A970995D8D5F12C6B8862977C.jpg" width:0 height:0]];
//    }
//    self.obj1 = NSObject.new;
//    arr = [NSPointerArray pointerArrayWithOptions:NSPointerFunctionsWeakMemory];
//    [arr addPointer:(__bridge void *)(self.obj1)];
    
//    NSLog(@"-------------------------- 打：%@--------------------------", arr.allObjects);
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"push" style:(UIBarButtonItemStylePlain) target:self action:@selector(action)];
    
    _tableView = [[UITableView alloc] initWithFrame:(CGRectMake(0, 40, self.view.frame.size.width, self.view.frame.size.height)) style:(UITableViewStylePlain)];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
    [self.tableView reloadData];
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
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.data.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleValue1) reuseIdentifier:@"UITableViewCell"];
        cell.imageView.frame = CGRectMake(15, 15, 100, 100);
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
//    cell.imageView.image = [UIImage imageNamed:@"image"];
    
//    [cell.imageView sd_setImageWithURL:[NSURL URLWithString:@"http://alicimg8.mowang.online/snapshot/3C5FAE3A970995D8D5F12C6B8862977C.jpg"]];
    
    [cell.imageView sd_setImageWithURL:[NSURL URLWithString:[self.data[indexPath.row] valueForKeyPath:@"url"]]];

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
    [AFBrowserViewController.new.makeDelegate(self).makeBrowserType(AFBrowserTypeDefault).makePageControlType(AFPageControlTypeNone).makeInfiniteLoop(YES).makeUseCustomPlayer(NO).makeSelectedIndex(indexPath.row) browse];
}


- (NSInteger)numberOfItemsInBrowser:(AFBrowserViewController *)browser {
    return self.data.count;
}

- (AFBrowserItem *)browser:(AFBrowserViewController *)browser itemForBrowserAtIndex:(NSInteger)index {
    
    return [AFBrowserItem itemWithImage:[self.data[index] valueForKeyPath:@"url"] coverImage:[self.data[index] valueForKeyPath:@"url"] width:0 height:0];

    return self.data[index];
            return [AFBrowserItem itemWithImage:@"http://alicimg8.mowang.online/snapshot/3C5FAE3A970995D8D5F12C6B8862977C.jpg" coverImage:@"http://alicimg8.mowang.online/snapshot/3C5FAE3A970995D8D5F12C6B8862977C.jpg" width:0 height:0];
    if (index > 2) {
        return [AFBrowserItem itemWithImage:@"http://alicimg8.mowang.online/snapshot/3C5FAE3A970995D8D5F12C6B8862977C.jpg" coverImage:@"http://alicimg8.mowang.online/snapshot/3C5FAE3A970995D8D5F12C6B8862977C.jpg" width:0 height:0];
    }
    return [AFBrowserItem itemWithVideo:@"http://alicvid8.mowang.online/vid/C0501F6EA330D2D04F85FF6EA6537349.mp4" coverImage:@"http://alicimg8.mowang.online/snapshot/3C5FAE3A970995D8D5F12C6B8862977C.jpg" duration:2 width:0 height:0];
}

/// 返回转场的View
- (UIView *)browser:(AFBrowserViewController *)browser viewForTransitionAtIndex:(NSInteger)index {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    if (!cell) {
        NSLog(@"-------------------------- 空！！！！ --------------------------");
        [self.tableView layoutIfNeeded];
        cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    }
    return cell.imageView;
    return [cell viewWithTag:100];
}

- (void)browser:(AFBrowserViewController *)browser longPressActionAtIndex:(NSInteger)index {
    NSLog(@"-------------------------- 来了老弟：%ld --------------------------", (long)index);
}


- (void)browser:(AFBrowserViewController *)browser willDisplayCell:(UICollectionViewCell *)cell forItemAtIndex:(NSInteger)index {
    
    UIButton *btn = [[UIButton alloc] initWithFrame:(CGRectMake(10, 200, 100, 50))];
    btn.backgroundColor = UIColor.blueColor;
    [btn setTitle:@"删除" forState:(UIControlStateNormal)];
    [btn setTitleColor:UIColor.whiteColor forState:(UIControlStateNormal)];
    [btn addTarget:browser action:[browser selectorForAction:AFBrowserActionDismiss] forControlEvents:(UIControlEventTouchUpInside)];
    [cell addSubview:btn];
}

- (void)browser:(AFBrowserViewController *)browser deleteActionAtIndex:(NSInteger)index completionDelete:(void (^)(void))completionDelete {
    [self.data removeObjectAtIndex:index];
    [self.tableView reloadData];
    completionDelete();
}

@end
