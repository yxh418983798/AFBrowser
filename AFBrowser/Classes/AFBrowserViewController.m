//
//  AFBrowserViewController.m
//  AFWorkSpace
//
//  Created by alfie on 2019/7/9.
//  Copyright © 2019 Alfie. All rights reserved.
//

#import "AFBrowserViewController.h"
#import "AFBrowserCollectionViewCell.h"
#import "AFBrowserTransformer.h"

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
@property (strong, nonatomic) UICollectionView          *collectionView;

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

@end


@implementation AFBrowserViewController
static const CGFloat lineSpacing = 0.f; //间隔

#pragma mark - 生命周期
- (instancetype)init {
    self = [super init];
    if (self) {
        
        self.transformer = [AFBrowserTransformer new];
        self.transformer.delegate = self;
        self.selectedIndex = 0;
        self.hideSourceViewWhenTransition = YES;
        self.transitioningDelegate = self.transformer;
        self.showToolBar = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor blackColor];
    if (@available(iOS 11.0, *)) {
        self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self configSubViews];
    [self loadItems];
}

- (void)viewDidLayoutSubviews {
    
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    layout.itemSize = CGSizeMake(UIScreen.mainScreen.bounds.size.width+lineSpacing, UIScreen.mainScreen.bounds.size.height);
    self.collectionView.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width+lineSpacing, UIScreen.mainScreen.bounds.size.height);
    _toolBar.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, [UIApplication sharedApplication].statusBarFrame.size.height + 44.f);
    [self.collectionView reloadData];
    [super viewDidLayoutSubviews];
    
    self.originalIndex = self.selectedIndex;
    self.transformer.type = [self itemAtIndex:self.selectedIndex].type;
    AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0]];
    cell.player.showToolBar = self.showToolBar;

    //设置偏移量
    self.collectionView.contentOffset = CGPointMake(self.selectedIndex * ([[UIScreen mainScreen] bounds].size.width+lineSpacing), 0);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AFBrowserUpdateVideoStatus" object:@(self.selectedIndex)];
    
    // pageControl
    switch (self.pageControlType) {
        case AFPageControlTypeCircle:
            self.pageControl.hidden = NO;
            _pageLabel.hidden = YES;
            break;
            
        case AFPageControlTypeText:
            _pageControl.hidden = YES;
            self.pageLabel.hidden = NO;
            break;
            
        default:
            _pageControl.hidden = YES;
            _pageLabel.hidden   = YES;
            break;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([self itemAtIndex:self.selectedIndex].type == AFBrowserItemTypeVideo) {
        AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0]];
        [cell.player browserCancelDismiss];
    }
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    [super dismissViewControllerAnimated:flag completion:completion];
    if ([self itemAtIndex:self.selectedIndex].type == AFBrowserItemTypeVideo) {
        AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0]];
        [cell.player browserWillDismiss];
    }
}


#pragma mark - 链式调用
- (AFBrowserViewController * (^)(id <AFBrowserDelegate>))makeDelegate {
    return ^id(id <AFBrowserDelegate> delegate) {
        self.delegate = delegate;
        return self;
    };
}

- (AFBrowserViewController * (^)(NSUInteger))makeSelectedIndex {
    return ^id(NSUInteger selectedIndex) {
        self.selectedIndex = selectedIndex;
        return self;
    };
}

- (AFBrowserViewController * (^)(AFBrowserType))makeBrowserType {
    return ^id(AFBrowserType browserType) {
        self.browserType = browserType;
        return self;
    };
}

- (AFBrowserViewController * (^)(AFPageControlType))makePageControlType {
    return ^id(AFPageControlType pageControlType) {
        self.pageControlType = pageControlType;
        return self;
    };
}

- (AFBrowserViewController * (^)(BOOL))makeShowVideoControl {
    return ^id(BOOL showVideoControl) {
        self.showVideoControl = showVideoControl;
        return self;
    };
}

- (AFBrowserViewController * (^)(BOOL))makeInfiniteLoop {
    return ^id(BOOL infiniteLoop) {
        self.infiniteLoop = infiniteLoop;
        return self;
    };
}

- (AFBrowserViewController * (^)(BOOL))makeHideSourceViewWhenTransition {
    return ^id(BOOL hideSourceViewWhenTransition) {
        self.hideSourceViewWhenTransition = hideSourceViewWhenTransition;
        return self;
    };
}

- (AFBrowserViewController * (^)(id))makeUserInfo {
    return ^id(id userInfo) {
        self.userInfo = userInfo;
        return self;
    };
}


#pragma mark - 配置UI
- (void)configSubViews {

    // collectionView
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    layout.itemSize = CGSizeMake([[UIScreen mainScreen] bounds].size.width+lineSpacing, [[UIScreen mainScreen] bounds].size.height);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;

    self.collectionView = [[UICollectionView alloc] initWithFrame:(CGRectMake(0, 0, layout.itemSize.width, layout.itemSize.height)) collectionViewLayout:layout];
    [self.collectionView registerClass:[AFBrowserCollectionViewCell class] forCellWithReuseIdentifier:@"AFBrowserCollectionViewCell"];
    self.collectionView.pagingEnabled = YES;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator   = NO;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.view addSubview:self.collectionView];
}

- (UIView *)toolBar {
    if (!_toolBar) {
//        _toolBar = [[UIView alloc] initWithFrame:(CGRectMake(0, self.showToolBar ? 0 : -[UIApplication sharedApplication].statusBarFrame.size.height - 44.f, UIScreen.mainScreen.bounds.size.width, [UIApplication sharedApplication].statusBarFrame.size.height + 44.f))];
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
        [_dismissBtn setImage:[UIImage imageNamed:@"browser_dismiss" inBundle:bundle compatibleWithTraitCollection:nil] forState:(UIControlStateNormal)];
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
        _pageControl.numberOfPages = self.numberOfItems;
        _pageControl.currentPage = (NSInteger)self.selectedIndex;
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
        _pageLabel.text = [NSString stringWithFormat:@"%zd/%zd", self.selectedIndex + 1, self.numberOfItems];
        [self.toolBar addSubview:_pageLabel];
    }
    return _pageLabel;
}


#pragma mark - 设置浏览类型
- (void)setBrowserType:(AFBrowserType)browserType {
    if (_browserType != browserType) {
        _browserType = browserType;
        switch (_browserType) {
                
            case AFBrowserTypeDelete:
                [self.view addSubview:self.toolBar];
                [self.toolBar addSubview:self.deleteBtn];
                [self.toolBar addSubview:self.dismissBtn];
                break;
                
//            case AFBrowserTypeSelect:
//                [self.view addSubview:self.toolBar];
//                [self.toolBar addSubview:self.selectBtn];
//                [self.toolBar addSubview:self.dismissBtn];
//                break;
                
            default:
                if (_toolBar.superview) [_toolBar removeFromSuperview];
                if (_deleteBtn.superview) [_deleteBtn removeFromSuperview];
                if (_dismissBtn.superview) [_dismissBtn removeFromSuperview];
                break;
        }
    }
}


#pragma mark - 是否隐藏转场原视图
- (void)setHideSourceViewWhenTransition:(BOOL)hideSourceViewWhenTransition {
    _hideSourceViewWhenTransition = hideSourceViewWhenTransition;
    self.transformer.hideSourceViewWhenTransition = hideSourceViewWhenTransition;
}


#pragma mark - item数据的操作
/// 存储容器
- (NSMutableDictionary<NSString *,AFBrowserItem *> *)items {
    if (!_items) {
        _items = NSMutableDictionary.new;
    }
    return _items;
}

/// 获取指定index的item
- (AFBrowserItem *)itemAtIndex:(NSInteger)index {
    NSString *key = [NSString stringWithFormat:@"AFPageItemIndex_%ld", index];
    AFBrowserItem *item = [self.items valueForKey:key];
    if (!item) {
        item = [self.delegate browser:self itemForBrowserAtIndex:index];
        item.showVideoControl = self.showVideoControl;
        item.infiniteLoop = self.infiniteLoop;
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


#pragma mark - 触发加载分页数据
- (void)loadItems {
    if (self.selectedIndex != 0 && self.selectedIndex != self.numberOfItems - 1) return;
    if (![self.delegate respondsToSelector:@selector(loadDataWithDirection:completionReload:)]) return;
    AFBrowserDirection direction = self.selectedIndex == 0 ? AFBrowserDirectionLeft : AFBrowserDirectionRight;
    [self.delegate loadDataWithDirection:direction completionReload:^(BOOL success) {
        if (success) {
            [self.items removeAllObjects];
            if (direction == AFBrowserDirectionLeft) {
                NSInteger currentNumbers = [self.delegate numberOfItemsInBrowser:self];
                self.selectedIndex = MAX((int)(currentNumbers - self.numberOfItems), 0);
                [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0] atScrollPosition:(UICollectionViewScrollPositionNone) animated:NO];
            } else {
                [self.collectionView reloadData];
            }
            [self.collectionView reloadData];
        }
    }];
}

/// 刷新数据
- (void)reloadData {
    [self.items removeAllObjects];
    [self.collectionView reloadData];
}


#pragma mark UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    self.numberOfItems = [self.delegate numberOfItemsInBrowser:self];
    _pageControl.numberOfPages = self.numberOfItems;
    return self.numberOfItems;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AFBrowserItem *item = [self itemAtIndex:indexPath.item];
    AFBrowserCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AFBrowserCollectionViewCell" forIndexPath:indexPath];
    cell.delegate = self;
    [cell attachItem:item atIndexPath:indexPath];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [[(AFBrowserCollectionViewCell *)cell scrollView] setZoomScale:1.0];
}


#pragma mark - 监听滚动
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.collectionView) {
        
        int currentPageNum = round(scrollView.contentOffset.x / (scrollView.frame.size.width + lineSpacing));
        switch (self.pageControlType) {
                
            case AFPageControlTypeCircle:
                self.pageControl.currentPage = currentPageNum;
                break;
                
            case AFPageControlTypeText:
                self.pageLabel.text = [NSString stringWithFormat:@"%d/%zd", currentPageNum + 1, self.numberOfItems];
                break;
                
            default:
                break;
        }
        self.selectedIndex = currentPageNum;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self loadItems];
    AFBrowserItem *item = [self itemAtIndex:self.selectedIndex];
    self.transformer.type = item.type;
    if (item.type == AFBrowserItemTypeVideo) {
        AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0]];
        [UIView animateWithDuration:0.25 animations:^{
            cell.player.showToolBar = self.showToolBar;
        }];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AFBrowserUpdateVideoStatus" object:@(self.selectedIndex)];
}


#pragma mark - 单击图片 AFBrowserCollectionViewCellDelegate
- (void)singleTapAction {
    switch (self.browserType) {
            
        case AFBrowserTypeDefault:
            [self dismissBtnAction];
            break;
            
        default:
            //隐藏
            _showToolBar = !_showToolBar;
//            CGRect frame = self.toolBar.frame;
//            frame.origin.y = self.showToolBar ? 0 : -[UIApplication sharedApplication].statusBarFrame.size.height - 44.f;
            [UIView animateWithDuration:0.25 animations:^{
//                self.toolBar.frame = frame;
//                self.pageControl.y = UIScreen.mainScreen.bounds.size.height;
//                [self setNeedsStatusBarAppearanceUpdate];
                self.toolBar.alpha = self.showToolBar ? 1 : 0;
                if (self.pageControlType == AFPageControlTypeCircle) self.pageControl.alpha = self.showToolBar ? 1 : 0;
                AFBrowserItem *item = [self itemAtIndex:self.selectedIndex];
                if (item.type == AFBrowserItemTypeVideo) {
                    AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0]];
                    cell.player.showToolBar = self.showToolBar;
                }
            }];
            break;
    }
}


#pragma mark - 长按事件 AFBrowserCollectionViewCellDelegate
- (void)longPressActionAtCollectionViewCell:(AFBrowserCollectionViewCell *)cell {
    if ([self.delegate respondsToSelector:@selector(browser:longPressActionAtIndex:)]) {
        [self.delegate browser:self longPressActionAtIndex:[self.collectionView indexPathForCell:cell].item];
    }
}


#pragma mark - 退出
- (void)dismissBtnAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - 删除事件
- (void)deleteBtnAction {
    if ([self.delegate respondsToSelector:@selector(browser:deleteActionAtIndex:completionDelete:)]) {
        [self.delegate browser:self deleteActionAtIndex:self.selectedIndex completionDelete:^{
            [self completionDeleteAction];
        }];
    } else {
        [self completionDeleteAction];
    }
}


#pragma mark - 确认删除
- (void)completionDeleteAction {
    
    AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0]];
    [cell.player stop];
    if (self.numberOfItems == 1) {
        self.transformer.userDefaultAnimation = YES;
        [self dismissBtnAction];
        return;
    }
    [self deleteItemAtIndex:self.selectedIndex];
    _pageControl.numberOfPages --;
    [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.selectedIndex inSection:0]]];
    [self scrollViewDidScroll:self.collectionView];
}
         

#pragma mark - 选择图片
- (void)selectBtnAction {
    
}


#pragma mark -- AFBrowserTransformerDelegate
- (UIView *)transitionViewForPresentedController {
    AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0]];
    AFBrowserItem *item = [self itemAtIndex:self.selectedIndex];
    if (item.type == AFBrowserItemTypeImage) {
        return cell.imageView;
    }
    return cell.player;
}

- (UIView *)transitionViewForSourceController {
    if (![self.delegate respondsToSelector:@selector(browser:viewForTransitionAtIndex:)]) return nil;
    return [self.delegate browser:self viewForTransitionAtIndex:self.selectedIndex];
}


#pragma mark - 弹出浏览器，开始浏览
- (void)browse {
    
    UIViewController *currentVc = AFBrowserViewController.currentVc;
    if (currentVc) {
        [currentVc presentViewController:self animated:YES completion:nil];
    } else {
        NSAssert(currentVc, @"找不到CurrentVc，无法跳转");
    }
}


#pragma mark - 获取 currentVc
+ (UIViewController *)currentVc {
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = UIApplication.sharedApplication.windows;
        for(UIWindow *win in windows) {
            if (win.windowLevel == UIWindowLevelNormal) {
                window = win;
                break;
            }
        }
    }
    UIViewController *result = window.rootViewController;
    if (result.presentedViewController) {
        do {result = result.presentedViewController;} while (result.presentedViewController);
    } else {
        id nextResponder = window.subviews.firstObject.nextResponder;
        if ([nextResponder isKindOfClass:UIViewController.class]) result = nextResponder;
    }
    while ([result isKindOfClass:UITabBarController.class] || [result isKindOfClass:UINavigationController.class]) {
        if ([result isKindOfClass:UITabBarController.class]) {
            UITabBarController *tabBarController = (UITabBarController *)result;
            result = tabBarController.viewControllers[tabBarController.selectedIndex];
            if (result.presentedViewController) {
                do {result = result.presentedViewController;} while (result.presentedViewController);
            }
        } else if ([result isKindOfClass:UINavigationController.class]) {
            result = [(UINavigationController *)result childViewControllers].lastObject;
            if (result.presentedViewController) {
                do {result = result.presentedViewController;} while (result.presentedViewController);
            }
        }
    }
    return result;
}


#pragma mark - 浏览器的加载器代理
static Class _loaderProxy;
+ (void)setLoaderProxy:(Class<AFBrowserLoaderDelegate>)loaderProxy {
    _loaderProxy = loaderProxy;
}

+ (Class<AFBrowserLoaderDelegate>)loaderProxy {
    return _loaderProxy;
}


#pragma mark -- 旋转控制，暂时不支持横屏
- (BOOL)shouldAutorotate{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

//- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
//    return UIInterfaceOrientationPortrait;
//}


@end




