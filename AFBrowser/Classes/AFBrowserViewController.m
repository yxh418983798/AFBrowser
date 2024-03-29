//
//  AFBrowserViewController.m
//  AFWorkSpace
//
//  Created by alfie on 2019/7/9.
//  Copyright © 2019 Alfie. All rights reserved.
//

#import "AFBrowserViewController.h"
#import "AFBrowserCollectionViewCell.h"
#import "AFPlayer.h"
#import "AFBrowserTransformer.h"
#import "AFBrowserLoaderProxy.h"

@interface AFBrowserCollectionView : UICollectionView
/** delegate */
@property (nonatomic, weak) id <AFBrowserDelegate> gestureRecognizerDelegate;
/** 浏览器 */
@property (nonatomic, weak) UIViewController            *browserVc;
@end
@implementation AFBrowserCollectionView

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)pan {
    if ([self.gestureRecognizerDelegate respondsToSelector:@selector(browser:gestureRecognizerShouldBegin:)]) {
        return [self.gestureRecognizerDelegate browser:self.browserVc gestureRecognizerShouldBegin:pan];
    }
    return YES;
}
@end


@interface AFBrowserViewController () <UICollectionViewDelegate, UICollectionViewDataSource, AFBrowserCollectionViewCellDelegate, AFBrowserTransformerDelegate>

/** 导航栏，用于开发者自定义导航栏样式 和 添加子视图 */
@property (strong, nonatomic) UIView                    *toolBar;

/** 退出按钮 */
@property (strong, nonatomic) UIButton                  *dismissBtn;

/** 删除按钮 */
@property (strong, nonatomic) UIButton                  *deleteBtn;

/** 选择按钮 */
@property (strong, nonatomic) UIButton                  *selectBtn;

/** 分页计数器 */
@property (nonatomic, strong) UIPageControl             *pageControl;

/** 分页计数（文本） */
@property (nonatomic, strong) UILabel                   *pageLabel;

/** collectionView */
@property (strong, nonatomic) AFBrowserCollectionView   *collectionView;

/** 转场 */
@property (strong, nonatomic) AFBrowserTransformer      *transformer;

/** 记录item数据源 */
@property (strong, nonatomic) NSMutableDictionary <NSString *, AFBrowserItem *>   *items;

/** 显示、隐藏toolBar */
@property (assign, nonatomic) BOOL            showToolBar;

/** 记录最初的index */
@property (assign, nonatomic) NSInteger       originalIndex;

/** 记录item的数量 */
@property (nonatomic, assign) NSInteger       numberOfItems;

/** 记录转场是否已经完成 */
@property (nonatomic, assign) BOOL            didViewAppear;

/** 记录屏幕方向 */
@property (assign, nonatomic) BOOL            originalPortrait;

/** 是否处于layout */
@property (nonatomic, assign) BOOL            isLayoutView;

/** 黑色背景，避免横竖屏切换时，有白边出现 */
@property (nonatomic, strong) UIView          *windowBackgroundView;

/** 停止滚动时刷新 */
@property (nonatomic, assign) BOOL            reloadWhenEndScroll;

/** 记录之前的状态栏状态 */
@property (nonatomic, assign) UIStatusBarStyle       lastStatusBarStyle;

/** deleteImage */
@property (nonatomic, strong) UIImage            *deleteImage;

@end


@implementation AFBrowserViewController
static const CGFloat lineSpacing = 0.f; //间隔


#pragma mark - 生命周期
- (instancetype)init {
    self = [super init];
    if (self) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            if ([AFBrowserViewController.loaderProxy respondsToSelector:@selector(initializeAFBrowserViewController)]) {
                [AFBrowserViewController.loaderProxy initializeAFBrowserViewController];
            }
        });
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidBecomeActiveNotification) name:UIApplicationDidBecomeActiveNotification object:nil];
        _configuration = AFBrowserConfiguration.new;
        self.transformer = [AFBrowserTransformer new];
        self.transformer.delegate = self;
        self.transformer.configuration = self.configuration;
        self.showToolBar = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.lastStatusBarStyle = UIApplication.sharedApplication.statusBarStyle;
    self.originalPortrait = AFBrowserConfiguration.isPortrait;
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = UIColor.blackColor;
    if (@available(iOS 11.0, *)) self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    
//    self.transformer.item = [self itemAtIndex:self.configuration.selectedIndex];
    [self configSubViews];
    [self loadItems];
    [self attachBrowserType:self.configuration.browserType];
    [self attachPageControlType:self.configuration.pageControlType];
    if ([self.configuration.delegate respondsToSelector:@selector(viewDidLoadBrowser:)]) {
        [self.configuration.delegate viewDidLoadBrowser:self];
    }
    [self updateDeleteImage:self.configuration.selectedIndex];
}

- (void)viewDidLayoutSubviews {
//    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
//        return;
//    }
    if (self.didViewAppear) {
        [super viewDidLayoutSubviews];
        return;
    }
    if ([self itemAtIndex:self.configuration.selectedIndex].type != AFBrowserItemTypeVideo) {
        return;
    }
    self.isLayoutView = YES;
//    NSLog(@"-------------------------- viewDidLayoutSubviews:%@ --------------------------", self.collectionView);
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    layout.itemSize = CGSizeMake(UIScreen.mainScreen.bounds.size.width+lineSpacing, UIScreen.mainScreen.bounds.size.height);
    self.collectionView.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width+lineSpacing, UIScreen.mainScreen.bounds.size.height);
    self.collectionView.delaysContentTouches = NO;
    _toolBar.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, [UIApplication sharedApplication].statusBarFrame.size.height + 44.f);
    [self.collectionView reloadData];
    [super viewDidLayoutSubviews];
    
    self.originalIndex = self.configuration.selectedIndex;
//    self.transformer.item = [self itemAtIndex:self.configuration.selectedIndex];
    AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.configuration.selectedIndex inSection:0]];
    cell.player.showVideoControl = [(AFBrowserVideoItem *)[self itemAtIndex:self.configuration.selectedIndex] videoControlEnable];

    //设置偏移量
    self.collectionView.contentOffset = CGPointMake(self.configuration.selectedIndex * ([[UIScreen mainScreen] bounds].size.width+lineSpacing), 0);
    self.collectionView.contentSize = CGSizeMake(self.collectionView.frame.size.width * self.numberOfItems + 1, self.collectionView.frame.size.height);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AFBrowserUpdateVideoStatus" object:@(self.configuration.selectedIndex)];
    [self.collectionView layoutIfNeeded];
    self.isLayoutView = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    UIApplication.sharedApplication.statusBarStyle = UIStatusBarStyleLightContent;
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    self.navigationController.view.frame = UIScreen.mainScreen.bounds;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
//    self.isFinishedTransaction = YES;
//    NSLog(@"-------------------------- 浏览器即将消失--------------------------");
    [self.navigationController setNavigationBarHidden:NO animated:YES];
//    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.didViewAppear) {
        self.didViewAppear = YES;
        [self.collectionView reloadData];
    }
//    [UIApplication.sharedApplication.delegate.window insertSubview:self.windowBackgroundView atIndex:0];
//    NSLog(@"-------------------------- viewDidAppear --------------------------");
    if ([self itemAtIndex:self.configuration.selectedIndex].type == AFBrowserItemTypeVideo) {
        AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.configuration.selectedIndex inSection:0]];
        [cell.player browserCancelDismiss];
    }
    if ([self.configuration.delegate respondsToSelector:@selector(viewDidAppearBrowser:)]) {
        [self.configuration.delegate viewDidAppearBrowser:self];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (_windowBackgroundView) {
        [_windowBackgroundView removeFromSuperview];
        _windowBackgroundView = nil;
    }
    if ([self.configuration.delegate respondsToSelector:@selector(viewDidDisappearBrowser:)]) {
        [self.configuration.delegate viewDidDisappearBrowser:self];
    }
    if ([UIDevice.currentDevice respondsToSelector:@selector(setOrientation:)]) {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = UIInterfaceOrientationPortrait;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    if (_toolBar.superview && _showToolBar) {
        [self singleTapAction]; // 隐藏toolBar
    }
    AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.configuration.selectedIndex inSection:0]];
    if ([self itemAtIndex:self.configuration.selectedIndex].type == AFBrowserItemTypeVideo) [cell.player browserWillDismiss];
    if (UIApplication.sharedApplication.statusBarOrientation != UIInterfaceOrientationPortrait) {
        self.navigationController.transitioningDelegate = nil;
    }
    [super dismissViewControllerAnimated:flag completion:^{
        if ([self itemAtIndex:self.configuration.selectedIndex].type == AFBrowserItemTypeVideo) {
            [cell.player browserDidDismiss];
        }
        if (completion) completion();
    }];
}

- (void)dealloc {
//    NSLog(@"-------------------------- 浏览器释放了 --------------------------");
    UIApplication.sharedApplication.statusBarStyle = self.lastStatusBarStyle;
    if (self.currentItem == AFPlayer.sharePlayer.item) {
        [AFPlayer.sharePlayer stop];
    }
    if ([self.configuration.delegate respondsToSelector:@selector(didDismissBrowser:)]) {
        [self.configuration.delegate didDismissBrowser:self];
    }
}

- (void)applicationDidBecomeActiveNotification {
//    self.configuration.isOtherAudioPlaying = AVAudioSession.sharedInstance.isOtherAudioPlaying;
}


#pragma mark - UI
/// 配置UI
- (void)configSubViews {

    // collectionView
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    layout.itemSize = CGSizeMake([[UIScreen mainScreen] bounds].size.width+lineSpacing, [[UIScreen mainScreen] bounds].size.height);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;

    self.collectionView = [[AFBrowserCollectionView alloc] initWithFrame:(CGRectMake(0, 0, layout.itemSize.width, layout.itemSize.height)) collectionViewLayout:layout];
    self.collectionView.browserVc = self;
    self.collectionView.gestureRecognizerDelegate = self.configuration.delegate;
    self.collectionView.backgroundColor = UIColor.blackColor;
    [self.collectionView registerClass:[AFBrowserCollectionViewCell class] forCellWithReuseIdentifier:@"AFBrowserCollectionViewCell"];
    self.collectionView.bounces = NO;
    self.collectionView.pagingEnabled = YES;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator   = NO;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    if ([self.configuration.delegate respondsToSelector:@selector(browser:configCollectionView:)]) {
        [self.configuration.delegate browser:self configCollectionView:self.collectionView];
    }
    [self.view addSubview:self.collectionView];
}

/// 更新删除图片
- (void)updateDeleteImage:(NSInteger)index {
    if (self.configuration.browserType == AFBrowserTypeDelete) {
        if ([self.configuration.delegate respondsToSelector:@selector(browser:imageForDeleteBtnAtIndex:defaultImage:)]) {
            UIImage *image = [self.configuration.delegate browser:self imageForDeleteBtnAtIndex:index defaultImage:self.deleteImage];
            if (image) {
                self.deleteBtn.hidden = NO;
                [self.deleteBtn setImage:image forState:(UIControlStateNormal)];
            } else {
                _deleteBtn.hidden = YES;
            }
        }
    }
}


#pragma mark - Getter
/// 浏览器的加载器代理
static Class _loaderProxy;
+ (Class<AFBrowserLoaderDelegate>)loaderProxy {
    return _loaderProxy;
}
+ (void)setLoaderProxy:(Class<AFBrowserLoaderDelegate>)loaderProxy {
    _loaderProxy = loaderProxy;
}

/// 存储容器
- (NSMutableDictionary<NSString *,AFBrowserItem *> *)items {
    if (!_items) {
        _items = NSMutableDictionary.new;
    }
    return _items;
}

- (UIView *)windowBackgroundView {
    if (!_windowBackgroundView) {
        _windowBackgroundView = UIView.new;
        _windowBackgroundView.frame = CGRectMake(-500, -500, 2000, 2000);
    //    backgroundView.frame = UIScreen.mainScreen.bounds;
        _windowBackgroundView.backgroundColor = UIColor.blackColor;
    }
    return _windowBackgroundView;
}

- (UIView *)toolBar {
    if (!_toolBar) {
        _toolBar = [[UIView alloc] initWithFrame:(CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, [UIApplication sharedApplication].statusBarFrame.size.height + 44.f))];
        _toolBar.alpha = self.showToolBar ? 1 : 0;
        _toolBar.backgroundColor = UIColor.blackColor;
    }
    return _toolBar;
}

- (UIButton *)dismissBtn {
    if (!_dismissBtn) {
        _dismissBtn = [[UIButton alloc] initWithFrame:(CGRectMake(0, [UIApplication sharedApplication].statusBarFrame.size.height, 50, 44))];
        NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:self.class] URLForResource:@"AFBrowser" withExtension:@"bundle"]];
        [_dismissBtn setImage:[UIImage imageNamed:@"browser_arrow_left" inBundle:bundle compatibleWithTraitCollection:nil] forState:(UIControlStateNormal)];
        [_dismissBtn addTarget:self action:@selector(dismissBtnAction) forControlEvents:(UIControlEventTouchUpInside)];
        [self.toolBar addSubview:_dismissBtn];
    }
    return _dismissBtn;
}

- (UIButton *)deleteBtn {
    if (!_deleteBtn) {
        _deleteBtn = [[UIButton alloc] initWithFrame:(CGRectMake(UIScreen.mainScreen.bounds.size.width - 50, [UIApplication sharedApplication].statusBarFrame.size.height, 50, 44))];
        NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:self.class] URLForResource:@"AFBrowser" withExtension:@"bundle"]];
        [_deleteBtn setImage:[UIImage imageNamed:@"browser_delete" inBundle:bundle compatibleWithTraitCollection:nil] forState:(UIControlStateNormal)];
        [_deleteBtn addTarget:self action:@selector(deleteBtnAction) forControlEvents:(UIControlEventTouchUpInside)];
        [self.toolBar addSubview:_deleteBtn];
    }
    return _deleteBtn;
}

- (UIImage *)deleteImage {
    if (!_deleteImage) {
        NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:self.class] URLForResource:@"AFBrowser" withExtension:@"bundle"]];
        _deleteImage = [UIImage imageNamed:@"browser_delete" inBundle:bundle compatibleWithTraitCollection:nil];
    }
    return _deleteImage;
}

- (UIButton *)selectBtn {
    if (!_selectBtn) {
        _selectBtn = [[UIButton alloc] initWithFrame:(CGRectMake(UIScreen.mainScreen.bounds.size.width - 50, [UIApplication sharedApplication].statusBarFrame.size.height, 50, 44))];
        NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:self.class] URLForResource:@"AFBrowser" withExtension:@"bundle"]];
        [_selectBtn setImage:[UIImage imageNamed:@"browser_delete" inBundle:bundle compatibleWithTraitCollection:nil] forState:(UIControlStateNormal)];
        [_selectBtn addTarget:self action:@selector(selectBtnAction) forControlEvents:(UIControlEventTouchUpInside)];
        [self.toolBar addSubview:_selectBtn];
    }
    return _selectBtn;
}

- (UIPageControl *)pageControl {
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc] initWithFrame:(CGRectMake(0, [[UIScreen mainScreen] bounds].size.height - ([UIApplication sharedApplication].statusBarFrame.size.height == 20 ? 30 : 45), [[UIScreen mainScreen] bounds].size.width, 20))];
        _pageControl.userInteractionEnabled = NO;
        _pageControl.numberOfPages = self.totalNumberOfItems;
        _pageControl.currentPage = (NSInteger)self.configuration.selectedIndex;
        [self.view addSubview:_pageControl];
    }
    return _pageControl;
}

- (UILabel *)pageLabel {
    if (!_pageLabel) {
        _pageLabel = [[UILabel alloc] initWithFrame:(CGRectMake(0, [UIApplication sharedApplication].statusBarFrame.size.height, [[UIScreen mainScreen] bounds].size.width, 44))];
        _pageLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:16];
        _pageLabel.textColor = UIColor.whiteColor;
        _pageLabel.textAlignment = NSTextAlignmentCenter;
        _pageLabel.text = [NSString stringWithFormat:@"%zd/%zd", self.configuration.selectedIndex + 1, self.totalNumberOfItems];
        [self.toolBar addSubview:_pageLabel];
    }
    return _pageLabel;
}

/// 获取对应类型的方法，给外部调用
- (SEL)selectorForAction:(AFBrowserAction)action {
    switch (action) {
        case AFBrowserActionDismiss:
            return @selector(dismissBtnAction);

        case AFBrowserActionDelete:
            return @selector(deleteBtnAction);
            
        case AFBrowserActionReload:
            return @selector(reloadData);

        default:
            return nil;;
    }
}


#pragma mark - Setter
/// 链式调用
- (AFBrowserViewController *(^)(AFBrowserConfiguration *))makeConfiguration {
    return ^id(AFBrowserConfiguration * configuration) {
        self.configuration = configuration;
        self.configuration.browserVc = self;
        return self;
    };
}

- (void)setConfiguration:(AFBrowserConfiguration *)configuration {
    _configuration = configuration;
    self.transformer.configuration = self.configuration;
}


#pragma mark - 数据处理
/// 获取指定index的item
- (AFBrowserVideoItem *)itemAtIndex:(NSInteger)index {
    NSString *key = [NSString stringWithFormat:@"AFPageItemIndex_%ld", index];
    AFBrowserItem *item = [self.items valueForKey:key];
    if (!item) {
        item = [self.configuration.delegate browser:self itemForBrowserAtIndex:index];
        if (self.configuration.playOption == AFBrowserPlayOptionDefault) {
            self.configuration.playOption = AFBrowserPlayOptionNeverAutoPlay;
            if (index == self.configuration.selectedIndex) {
                item.autoPlay = YES;
            }
        } else if (self.configuration.playOption == AFBrowserPlayOptionAutoPlay) {
            item.autoPlay = YES;
        }
        [self.items setValue:item forKey:key];
    }
    return item;
}

/// 删除指定index的item
- (void)deleteItemAtIndex:(NSInteger)index {
    NSString *key = [NSString stringWithFormat:@"AFPageItemIndex_%ld", index];
    if ([self.items.allKeys containsObject:key]) {
        [self.items removeObjectForKey:key];
    }
}

/// 获取当前展示的item
- (AFBrowserItem *)currentItem {
    return [self itemAtIndex:self.configuration.selectedIndex];
}

/// 获取item的数量
- (NSInteger)numberOfItems {
    if (_numberOfItems == 0) {
        _numberOfItems = [self.configuration.delegate numberOfItemsInBrowser:self];
    }
    return _numberOfItems;
}

- (NSInteger)totalNumberOfItems {
    if ([self.configuration.delegate respondsToSelector:@selector(totalNumberOfItemsInBrowser:)]) {
        return [self.configuration.delegate totalNumberOfItemsInBrowser:self];
    }
    return self.numberOfItems;
}

/// 查询图片缓存
- (UIImage *)imageFromCacheForKey:(id)key {
    if ([key isKindOfClass:NSString.class] || [key isKindOfClass:NSURL.class]) {
        NSString *keyString = [key isKindOfClass:NSString.class] ? key : [(NSURL *)key absoluteString];
        if ([self.configuration.delegate respondsToSelector:@selector(browser:hasImageCacheWithKey:atIndex:)]) {
            return [self.configuration.delegate browser:self hasImageCacheWithKey:keyString atIndex:self.configuration.selectedIndex];
        }
        return [AFBrowserLoaderProxy imageFromCacheForKey:keyString];
    } else if ([key isKindOfClass:UIImage.class]) {
        return key;
    }
    return nil;
}

/// 触发加载分页数据
- (void)loadItems {
    if (self.configuration.selectedIndex != 0 && self.configuration.selectedIndex != self.numberOfItems - 1) return;
    if (![self.configuration.delegate respondsToSelector:@selector(browser:loadDataWithDirection:completionReload:)]) return;
    AFBrowserDirection direction = self.configuration.selectedIndex == 0 ? AFBrowserDirectionLeft : AFBrowserDirectionRight;
    [self.configuration.delegate browser:self loadDataWithDirection:direction completionReload:^(BOOL success) {
        if (success) {
            [self.items removeAllObjects];
            [self scrollViewDidScroll:self.collectionView];
//            if (direction == AFBrowserDirectionLeft) {
//                NSInteger currentNumbers = [self.configuration.delegate numberOfItemsInBrowser:self];
//                self.configuration.selectedIndex = MAX((int)(currentNumbers - self.numberOfItems), 0);
//                [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.configuration.selectedIndex inSection:0] atScrollPosition:(UICollectionViewScrollPositionNone) animated:NO];
//            } else {
//                [self.collectionView reloadData];
//            }
            [self.collectionView reloadData];
        }
    }];
}

/// 刷新数据
- (void)reloadData {
    [self.items removeAllObjects];
    [self.collectionView reloadData];
}

- (void)reloadDataWhenEndScroll {
    [self.items removeAllObjects];
    [self scrollViewDidScroll:self.collectionView];
    [self.collectionView reloadData];
    return;
    if (self.collectionView.isTracking || self.self.collectionView.isDecelerating) {
        self.reloadWhenEndScroll = YES;
    } else {
        [self.collectionView reloadData];
    }
}

/// 设置浏览类型
- (void)attachBrowserType:(AFBrowserType)browserType {
    self.configuration.browserType = browserType;
    if (_collectionView) {
        switch (browserType) {
                
            case AFBrowserTypeDelete:
                [self.view addSubview:self.toolBar];
                [self.toolBar addSubview:self.deleteBtn];
                [self.toolBar addSubview:self.dismissBtn];
                break;
                
            default:
                if (_toolBar.superview) [_toolBar removeFromSuperview];
                if (_deleteBtn.superview) [_deleteBtn removeFromSuperview];
                if (_dismissBtn.superview) [_dismissBtn removeFromSuperview];
                break;
        }
    }
}

/// 设置页码类型
- (void)attachPageControlType:(AFPageControlType)pageControlType {
    self.configuration.pageControlType = pageControlType;
    if (_collectionView) {
        switch (pageControlType) {
            case AFPageControlTypeCircle:
                [self.view addSubview:self.toolBar];
                [self.toolBar addSubview:self.dismissBtn];
                [self.toolBar addSubview:self.pageControl];
                if (_pageLabel.superview) {
                    [_pageLabel removeFromSuperview];
                    _pageLabel = nil;
                }
                break;
                
            case AFPageControlTypeText:
                [self.view addSubview:self.toolBar];
                [self.toolBar addSubview:self.dismissBtn];
                [self.toolBar addSubview:self.pageLabel];
                if (_pageControl.superview) {
                    [_pageControl removeFromSuperview];
                    _pageControl = nil;
                }
                break;
                
            default:
                if (_pageLabel.superview) {
                    [_pageLabel removeFromSuperview];
                    _pageLabel = nil;
                }
                if (_pageControl.superview) {
                    [_pageControl removeFromSuperview];
                    _pageControl = nil;
                }
                break;
        }
    }
}


#pragma mark UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (!self.didViewAppear) {
//        NSLog(@"-------------------------- 未完成转场，不显示 --------------------------");
        return 0;
    }
    self.numberOfItems = [self.configuration.delegate numberOfItemsInBrowser:self];
    _pageControl.numberOfPages = self.numberOfItems;
    self.collectionView.contentOffset = CGPointMake(self.configuration.selectedIndex * ([[UIScreen mainScreen] bounds].size.width+lineSpacing), 0);
    self.collectionView.contentSize = CGSizeMake(self.collectionView.frame.size.width * self.numberOfItems + 1, self.collectionView.frame.size.height);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startCurrentPlayer];
    });
    return 1;
//    if (self.isFinishedTransaction) {
//        self.collectionView.contentOffset = CGPointMake(self.configuration.selectedIndex * ([[UIScreen mainScreen] bounds].size.width+lineSpacing), 0);
//        self.collectionView.contentSize = CGSizeMake(self.collectionView.frame.size.width * self.numberOfItems + 1, self.collectionView.frame.size.height);
//    } else {
//        NSLog(@"-------------------------- 未完成转场，刷新无效 --------------------------");
//    }
        //    return self.isFinishedTransaction ? 1 : 0;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.numberOfItems;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AFBrowserItem *item = [self itemAtIndex:indexPath.item];
    AFBrowserCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AFBrowserCollectionViewCell" forIndexPath:indexPath];
    cell.delegate = self;
    [cell attachItem:item configuration:self.configuration atIndexPath:indexPath];
    if ([self.configuration.delegate respondsToSelector:@selector(browser:willDisplayCell:forItemAtIndex:)]) {
        [cell removeCustomView];
        [self.configuration.delegate browser:self willDisplayCell:cell forItemAtIndex:indexPath.item];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [[(AFBrowserCollectionViewCell *)cell scrollView] setZoomScale:1.0];
}

#pragma mark - 监听滚动
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.collectionView) {
        if (!self.didViewAppear) return;
        if (self.isLayoutView) return;
        int currentPageNum = round(scrollView.contentOffset.x / (scrollView.frame.size.width + lineSpacing));
        switch (self.configuration.pageControlType) {
                
            case AFPageControlTypeCircle:
                self.pageControl.currentPage = currentPageNum;
                break;
                
            case AFPageControlTypeText:
                self.pageLabel.text = [NSString stringWithFormat:@"%d/%zd", currentPageNum + 1, self.totalNumberOfItems];
                break;
                
            default:
                break;
        }
        if (self.configuration.selectedIndex != currentPageNum) {
            self.configuration.selectedIndex = currentPageNum;
            AFBrowserItem *item = [self itemAtIndex:currentPageNum];
            if (item.type == AFBrowserItemTypeVideo) {
                AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.configuration.selectedIndex inSection:0]];
                [cell.player stop];
            }
        }
        if ([self.configuration.delegate respondsToSelector:@selector(browser:didScroll:atIndex:)]) {
            [self.configuration.delegate browser:self didScroll:scrollView atIndex:currentPageNum];
        }
        [self updateDeleteImage:currentPageNum];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
//    NSLog(@"-------------------------- 手指离开decelerate:%d  tracking:%d --------------------------", decelerate, scrollView.tracking);
    if (!decelerate) {
        [self endScroll];
        if (self.reloadWhenEndScroll) {
            self.reloadWhenEndScroll = NO;
            [self.collectionView reloadData];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
//    NSLog(@"-------------------------- 结束惯性decelerate:%d  tracking:%d --------------------------", scrollView.isDecelerating, scrollView.tracking);
    [self endScroll];
    if (self.reloadWhenEndScroll) {
        self.reloadWhenEndScroll = NO;
        [self.collectionView reloadData];
    }
}

/// 结束滚动
- (void)endScroll {
    [self loadItems];
    AFBrowserVideoItem *item = [self itemAtIndex:self.configuration.selectedIndex];
    if (item.type == AFBrowserItemTypeVideo) {
        AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.configuration.selectedIndex inSection:0]];
        cell.player.showVideoControl = item.videoControlEnable;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AFBrowserUpdateVideoStatus" object:@(self.configuration.selectedIndex)];
}


#pragma mark - AFBrowserCollectionViewCellDelegate
/// 单击图片
- (void)singleTapAction {
    
    if ([self.configuration.delegate respondsToSelector:@selector(browser:tapActionAtIndex:)]) {
        if (![self.configuration.delegate browser:self tapActionAtIndex:self.configuration.selectedIndex])  return;
    }
    AFBrowserVideoItem *item = [self itemAtIndex:self.configuration.selectedIndex];
    if (_toolBar.superview) {
        //隐藏
        _showToolBar = !_showToolBar;
//            CGRect frame = self.toolBar.frame;
//            frame.origin.y = self.showToolBar ? 0 : -[UIApplication sharedApplication].statusBarFrame.size.height - 44.f;
        [UIView animateWithDuration:0.25 animations:^{
//                self.toolBar.frame = frame;
//                self.pageControl.y = UIScreen.mainScreen.bounds.size.height;
//                [self setNeedsStatusBarAppearanceUpdate];
            self.toolBar.alpha = self.showToolBar ? 1 : 0;
            if (self.configuration.pageControlType == AFPageControlTypeCircle) self.pageControl.alpha = self.showToolBar ? 1 : 0;
            if (item.type == AFBrowserItemTypeVideo) {
                item.videoControlEnable = !item.videoControlEnable;
                AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.configuration.selectedIndex inSection:0]];
                cell.player.showVideoControl = item.videoControlEnable;
            }
        }];
    } else {
        if (item.type == AFBrowserItemTypeVideo) {
            AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.configuration.selectedIndex inSection:0]];
            if (!cell.player.showVideoControl) [self dismissBtnAction];
        } else {
            [self dismissBtnAction];
        }
    }
}

/// 长按事件
- (void)longPressActionAtCollectionViewCell:(AFBrowserCollectionViewCell *)cell {
    if ([self.configuration.delegate respondsToSelector:@selector(browser:longPressActionAtIndex:)]) {
        [self.configuration.delegate browser:self longPressActionAtIndex:[self.collectionView indexPathForCell:cell].item];
    }
}

/// 查询图片缓存
- (UIImage *)browserCell:(AFBrowserCollectionViewCell *)cell hasImageCache:(id)content atIndex:(NSInteger)index {
    
    if ([content isKindOfClass:UIImage.class]) return content;
    if ([content isKindOfClass:NSData.class]) return [UIImage imageWithData:content];
    NSString *key = content;
    if ([content isKindOfClass:NSURL.class]) key = [(NSURL *)content absoluteString];
    UIImage *image;
    if ([self.configuration.delegate respondsToSelector:@selector(browser:hasImageCacheWithKey:atIndex:)]) {
        image = [self.configuration.delegate browser:self hasImageCacheWithKey:key atIndex:index];
        if (image) return image;
    }
    image = [AFBrowserLoaderProxy imageFromCacheForKey:key];
    return image;
}

/// 是否展示原图按钮
- (BOOL)browserCell:(AFBrowserCollectionViewCell *)cell shouldAutoLoadOriginalImageForItemAtIndex:(NSInteger)index {
    if ([self.configuration.delegate respondsToSelector:@selector(browser:shouldAutoLoadOriginalImageForItemAtIndex:)]) {
        return [self.configuration.delegate browser:self shouldAutoLoadOriginalImageForItemAtIndex:index];
    }
    return !self.configuration.autoLoadOriginalImage;
}


#pragma mark -- AFBrowserTransformerDelegate
- (UIView *)transitionViewForPresentedController {
    [self.collectionView layoutIfNeeded];
    AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.configuration.selectedIndex inSection:0]];
    AFBrowserItem *item = [self itemAtIndex:self.configuration.selectedIndex];
    switch (item.type) {
        case AFBrowserItemTypeImage:
            return cell.imageView;

        case AFBrowserItemTypeVideo:
            if (!cell) {
                [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"转场cell是空的, %@", self.description]];
            } else if (!cell.player) {
                [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"转场的player是空的, %@", self.description]];
            }
            return cell.player;
            
        default:
            return nil;
    }
}

- (UIImage *)transitionImageForSourceController {
    if ([self.configuration.delegate respondsToSelector:@selector(browser:imageForTransitionAtIndex:)]) {
        return [self.configuration.delegate browser:self imageForTransitionAtIndex:self.configuration.selectedIndex];
    }
    return nil;
}

- (UIView *)transitionViewForSourceController {
    if (![self.configuration.delegate respondsToSelector:@selector(browser:viewForTransitionAtIndex:)]) return nil;
    return [self.configuration.delegate browser:self viewForTransitionAtIndex:self.configuration.selectedIndex];
}

/// 返回父视图，用于添加播放器
- (UIView *)superViewForTransitionView:(UIView *)transitionView {
    AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.configuration.selectedIndex inSection:0]];
    if (!cell) {
        [self.collectionView layoutIfNeeded];
        cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.configuration.selectedIndex inSection:0]];
    }
    cell.player = (AFPlayerView *)transitionView;
    return cell;
}


#pragma mark - 事件
/// dismiss事件
- (void)dismissActionAtCollectionViewCell:(AFBrowserCollectionViewCell *)cell {
    [self dismissViewControllerAnimated:YES completion:nil];
}

/// 退出
- (void)dismissBtnAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

/// 删除事件
- (void)deleteBtnAction {
    if ([self.configuration.delegate respondsToSelector:@selector(browser:deleteActionAtIndex:completionDelete:)]) {
        [self.configuration.delegate browser:self deleteActionAtIndex:self.configuration.selectedIndex completionDelete:^{
            [self completionDeleteAction];
        }];
    } else {
        [self completionDeleteAction];
    }
}

/// 确认删除
- (void)completionDeleteAction {
    
    AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.configuration.selectedIndex inSection:0]];
    [cell.player stop];
    if (self.numberOfItems == 1) {
        self.configuration.transitionStyle = AFBrowserTransitionStyleSystem;
        [self dismissBtnAction];
        return;
    }
    [self deleteItemAtIndex:self.configuration.selectedIndex];
//    int currentPageNum = round(scrollView.contentOffset.x / (scrollView.frame.size.width + lineSpacing));
//    switch (self.configuration.pageControlType) {
//
//        case AFPageControlTypeCircle:
//            _pageControl.numberOfPages --;
//            self.pageControl.currentPage = currentPageNum;
//            break;
//
//        case AFPageControlTypeText:
//            self.pageLabel.text = [NSString stringWithFormat:@"%d/%zd", currentPageNum + 1, self.totalNumberOfItems];
//            break;
//
//        default:
//            break;
//    }
    [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.configuration.selectedIndex inSection:0]]];
    [self scrollViewDidScroll:self.collectionView];
}
         
/// 选择图片
- (void)selectBtnAction {
    
}


#pragma mark - 弹出浏览器，开始浏览
- (void)browse {
    self.configuration.isOtherAudioPlaying = AVAudioSession.sharedInstance.isOtherAudioPlaying;
    AFBrowserItem *item = [self itemAtIndex:self.configuration.selectedIndex];
    // 如果url为空，不弹出浏览器
    if (!item.validContent) {
        NSLog(@"-------------------------- Error：item的content为空，userInfo：%@ --------------------------", item.userInfo);
    }
    if (!self.configuration.shouldBrowseWhenNoCache) {
        // 没有加载图片到缓存的情况下，不弹出浏览器
        if (![self imageFromCacheForKey:item.coverImage]) {
            [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"Error：图片的缩略图没有加载到缓存:%@", item.coverImage]];
            if (![self imageFromCacheForKey:item.content]) {
                [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"Error：图片的高清图也没有加载到缓存:%@", item.content]];
                return;
            }
        }
        if (item.type == AFBrowserItemTypeVideo) {
            if (![self.configuration videoPathForItem:item]) {
                [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"Error：视频没有加载完成，不展示浏览器:%@", item.content]];
                return;
            }
        }
    }
    UIViewController *currentVc = AFBrowserConfiguration.currentVc;
    if (currentVc) {
        
        UINavigationController *navigationController;
        if ([self.configuration.delegate respondsToSelector:@selector(navigationControllerForBrowser:)]) {
            navigationController = [self.configuration.delegate navigationControllerForBrowser:self];
        } else {
            navigationController = [[UINavigationController alloc] initWithRootViewController:self];
            navigationController.navigationBar.barTintColor = [UIColor whiteColor];
            [navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:(UIBarMetricsDefault)];
            [navigationController.navigationBar setShadowImage:[UIImage new]];
        }
        navigationController.navigationBar.hidden = YES;
        navigationController.transitioningDelegate = self.transformer;
        navigationController.hidesBottomBarWhenPushed = YES;
        navigationController.view.backgroundColor = UIColor.blackColor;
        [currentVc presentViewController:navigationController animated:YES completion:nil];
    } else {
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"Error：找不到CurrentVc，无法跳转:%@", UIApplication.sharedApplication.delegate.window]];
    }
}


#pragma mark - 播放器
/// 刚进入时，播放当前的播放器
- (void)startCurrentPlayer {
    AFBrowserVideoItem *item = [self itemAtIndex:self.configuration.selectedIndex];
    if (!item) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self startCurrentPlayer];
        });
        return;
    }
    
    if (item.type != AFBrowserItemTypeVideo) return;
    AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.configuration.selectedIndex inSection:0]];
    if (!cell) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self startCurrentPlayer];
        });
    } else {
        if (AVAudioSession.sharedInstance.otherAudioPlaying) {
            [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategorySoloAmbient error:nil];
        }
        [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback error:nil];
        [AVAudioSession.sharedInstance setActive:YES error:nil];
        if (self.configuration.transitionStatus == AFTransitionStatusPresented && cell.player.frame.size.width == UIScreen.mainScreen.bounds.size.width) {
            cell.player.showVideoControl = item.videoControlEnable;
        } else {
            NSLog(@"-------------------------- 未完成转场，过滤设置 --------------------------");
        }
        [NSNotificationCenter.defaultCenter postNotificationName:@"AFBrowserUpdateVideoStatus" object:@(self.configuration.selectedIndex)];
    }
}

/// 暂停播放
- (void)pauseCurrentPlayer {
    if ([self itemAtIndex:self.configuration.selectedIndex].type == AFBrowserItemTypeVideo) {
        AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.configuration.selectedIndex inSection:0]];
        [cell.player pause];
        cell.player.resumeOption = AFPlayerResumeOptionBrowserAppeared;
    }
}


#pragma mark -- 屏幕旋转控制
- (BOOL)shouldAutorotate{
//    NSLog(@"-------------------------- shouldAutorotate --------------------------");
    return YES;
}

//[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
//    NSLog(@"-------------------------- supportedInterfaceOrientations --------------------------");
    return UIInterfaceOrientationMaskAll;
}

//- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
//    return UIInterfaceOrientationPortrait;
//}


- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
//    NSLog(@"-------------------------- viewWillTransitionToSize:%@ --------------------------", NSStringFromCGSize(size));
}

//
//- (BOOL)modalPresentationCapturesStatusBarAppearance {
//    
//}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    UIViewController *childVc = self.navigationController.topViewController;
    return childVc == self ? nil : childVc;
}

@end




