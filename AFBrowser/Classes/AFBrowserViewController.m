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
#import "AFBrowserLoaderProxy.h"

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

/** 记录转场是否已经完成 */
@property (nonatomic, assign) BOOL            isFinishedTransaction;

@end


@implementation AFBrowserViewController
static const CGFloat lineSpacing = 0.f; //间隔

#pragma mark - 生命周期
- (instancetype)init {
    self = [super init];
    if (self) {
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(finishedTransaction) name:@"AFBrowserFinishedTransaction" object:nil];
//        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationWillEnterForegroundNotification) name:UIApplicationWillEnterForegroundNotification object:nil];
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
    self.transformer.item = [self itemAtIndex:self.selectedIndex];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor blackColor];
    if (@available(iOS 11.0, *)) {
        self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self configSubViews];
    [self loadItems];
    self.browserType = self.browserType;
    self.pageControlType = self.pageControlType;
    NSLog(@"-------------------------- viewDidLoad --------------------------");
}

- (void)viewDidLayoutSubviews {
//    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
//        return;
//    }
    NSLog(@"-------------------------- viewDidLayoutSubviews --------------------------");
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    layout.itemSize = CGSizeMake(UIScreen.mainScreen.bounds.size.width+lineSpacing, UIScreen.mainScreen.bounds.size.height);
    self.collectionView.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width+lineSpacing, UIScreen.mainScreen.bounds.size.height);
    _toolBar.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, [UIApplication sharedApplication].statusBarFrame.size.height + 44.f);
    [self.collectionView reloadData];
    [super viewDidLayoutSubviews];
    
    self.originalIndex = self.selectedIndex;
    self.transformer.item = [self itemAtIndex:self.selectedIndex];
    AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0]];
    cell.player.showToolBar = self.showToolBar;

    //设置偏移量
    self.collectionView.contentOffset = CGPointMake(self.selectedIndex * ([[UIScreen mainScreen] bounds].size.width+lineSpacing), 0);
    self.collectionView.contentSize = CGSizeMake(self.collectionView.frame.size.width * self.numberOfItems + 1, self.collectionView.frame.size.height);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AFBrowserUpdateVideoStatus" object:@(self.selectedIndex)];
    [self.collectionView layoutIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"-------------------------- viewDidAppear --------------------------");
    if ([self itemAtIndex:self.selectedIndex].type == AFBrowserItemTypeVideo) {
        AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0]];
        [cell.player browserCancelDismiss];
    }
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    if (_toolBar.superview && _showToolBar) {
        [self singleTapAction]; // 隐藏toolBar
    }
    AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0]];
    if ([self itemAtIndex:self.selectedIndex].type == AFBrowserItemTypeVideo) [cell.player browserWillDismiss];
    [super dismissViewControllerAnimated:flag completion:^{
        if ([self itemAtIndex:self.selectedIndex].type == AFBrowserItemTypeVideo) {
            [cell.player browserDidDismiss];
        }
        if (completion) completion();
    }];
}

- (void)dealloc {
    if ([self.delegate respondsToSelector:@selector(didDismissBrowser:)]) {
        [self.delegate didDismissBrowser:self];
    }
}

//  进入前台，刷新下布局，避免gif停止
//- (void)applicationWillEnterForegroundNotification {
//    [self viewDidLayoutSubviews];
//}


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

- (AFBrowserViewController * (^)(AFBrowserPlayOption))makePlayOption {
    return ^id(AFBrowserPlayOption playOption) {
        self.playOption = playOption;
        return self;
    };
}

- (AFBrowserViewController * (^)(BOOL))makeUseCustomPlayer {
    return ^id(BOOL useCustomPlayer) {
        self.useCustomPlayer = useCustomPlayer;
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

+ (AFPlayer *)productPlayer {
    return [[AFPlayer alloc] initWithFrame:(CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height))];
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


#pragma mark - 获取对应类型的方法，给外部调用
- (SEL)selectorForAction:(AFBrowserAction)action {
    switch (action) {
        case AFBrowserActionDismiss:
            return @selector(dismissBtnAction);

        case AFBrowserActionDelete:
            return @selector(deleteBtnAction);
            
        default:
            return nil;;
    }
}


#pragma mark - 设置浏览类型
- (void)setBrowserType:(AFBrowserType)browserType {
    _browserType = browserType;
    if (_collectionView) {
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


#pragma mark - 设置页码类型
- (void)setPageControlType:(AFPageControlType)pageControlType {
    _pageControlType = pageControlType;
    // pageControl
    if (_collectionView) {
        switch (self.pageControlType) {
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
        item.useCustomPlayer = self.useCustomPlayer;
        if (self.playOption == AFBrowserPlayOptionDefault) {
            self.playOption = AFBrowserPlayOptionNeverAutoPlay;
            if (index == self.selectedIndex) {
                item.autoPlay = YES;
            }
        } else if (self.playOption == AFBrowserPlayOptionAutoPlay) {
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

/// 获取item的数量
- (NSInteger)numberOfItems {
    if (_numberOfItems == 0) {
        _numberOfItems = [self.delegate numberOfItemsInBrowser:self];
    }
    return _numberOfItems;
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startCurrentPlayer];
    });
    self.numberOfItems = [self.delegate numberOfItemsInBrowser:self];
    _pageControl.numberOfPages = self.numberOfItems;
    if (self.isFinishedTransaction) {
        self.collectionView.contentOffset = CGPointMake(self.selectedIndex * ([[UIScreen mainScreen] bounds].size.width+lineSpacing), 0);
        self.collectionView.contentSize = CGSizeMake(self.collectionView.frame.size.width * self.numberOfItems + 1, self.collectionView.frame.size.height);
    }
    return self.isFinishedTransaction ? 1 : 0;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.numberOfItems;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AFBrowserItem *item = [self itemAtIndex:indexPath.item];
    AFBrowserCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AFBrowserCollectionViewCell" forIndexPath:indexPath];
    cell.delegate = self;
    [cell attachItem:item atIndexPath:indexPath];
    if ([self.delegate respondsToSelector:@selector(browser:willDisplayCell:forItemAtIndex:)]) {
        [cell removeCustomView];
        [self.delegate browser:self willDisplayCell:cell forItemAtIndex:indexPath.item];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [[(AFBrowserCollectionViewCell *)cell scrollView] setZoomScale:1.0];
}


#pragma mark - 监听滚动
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.collectionView) {
        if (!self.isFinishedTransaction) return;
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

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) [self endScroll];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self endScroll];
}

/// 结束滚动
- (void)endScroll {
    [self loadItems];
    AFBrowserItem *item = [self itemAtIndex:self.selectedIndex];
    self.transformer.item = item;
    if (item.type == AFBrowserItemTypeVideo) {
        AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0]];
        cell.player.showToolBar = self.showToolBar;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AFBrowserUpdateVideoStatus" object:@(self.selectedIndex)];
}


#pragma mark - 刚进入时，播放当前的播放器
- (void)startCurrentPlayer {
    AFBrowserItem *item = [self itemAtIndex:self.selectedIndex];
    if (!item) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self startCurrentPlayer];
        });
        return;
    }
    
    if (item.type != AFBrowserItemTypeVideo) return;
    AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0]];
    if (!cell) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self startCurrentPlayer];
        });
    } else {
        [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategorySoloAmbient error:nil];
        cell.player.showToolBar = self.showToolBar;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AFBrowserUpdateVideoStatus" object:@(self.selectedIndex)];
    }
}


#pragma mark - 单击图片 AFBrowserCollectionViewCellDelegate
- (void)singleTapAction {
    AFBrowserItem *item = [self itemAtIndex:self.selectedIndex];
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
            if (self.pageControlType == AFPageControlTypeCircle) self.pageControl.alpha = self.showToolBar ? 1 : 0;
            if (item.type == AFBrowserItemTypeVideo) {
                AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0]];
                cell.player.showToolBar = self.showToolBar;
            }
        }];
    } else {
        if (item.type == AFBrowserItemTypeVideo) {
            if (!item.showVideoControl) [self dismissBtnAction];
        } else {
            [self dismissBtnAction];
        }
    }
}


#pragma mark - 长按事件 AFBrowserCollectionViewCellDelegate
- (void)longPressActionAtCollectionViewCell:(AFBrowserCollectionViewCell *)cell {
    if ([self.delegate respondsToSelector:@selector(browser:longPressActionAtIndex:)]) {
        [self.delegate browser:self longPressActionAtIndex:[self.collectionView indexPathForCell:cell].item];
    }
}


#pragma mark -  dismiss事件
- (void)dismissActionAtCollectionViewCell:(AFBrowserCollectionViewCell *)cell {
    [self dismissViewControllerAnimated:YES completion:nil];
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
    [self.collectionView layoutIfNeeded];
    AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0]];
    AFBrowserItem *item = [self itemAtIndex:self.selectedIndex];
    if (item.type == AFBrowserItemTypeImage) {
        return cell.imageView;
    }
    if (!cell) {
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"转场cell是空的, %@", self.description]];
    } else if (!cell.player) {
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"转场的player是空的, %@", self.description]];
    }
    return cell.player;
}

- (UIView *)transitionViewForSourceController {
    if (![self.delegate respondsToSelector:@selector(browser:viewForTransitionAtIndex:)]) return nil;
    return [self.delegate browser:self viewForTransitionAtIndex:self.selectedIndex];
}

/// 返回父视图，用于添加播放器
- (UIView *)superViewForTransitionView:(UIView *)transitionView {
    AFBrowserCollectionViewCell *cell = (AFBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0]];
    if (!cell) {
        cell = [self collectionView:self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0]];
    }
    cell.player = (AFPlayer *)transitionView;
    return cell;
}


#pragma mark - 弹出浏览器，开始浏览
- (void)browse {
    self.isOtherAudioPlaying = AVAudioSession.sharedInstance.isOtherAudioPlaying;
    AFBrowserItem *item = [self itemAtIndex:self.selectedIndex];
    // 如果url为空，不弹出浏览器
    if (!item.content) {
        NSLog(@"-------------------------- Error：item的Url为空 --------------------------");
        return;
    }
    // 没有加载图片到缓存的情况下，不弹出浏览器
    if (![self imageFromCacheForKey:item.coverImage]) {
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"Error：图片的缩略图没有加载到缓存:%@", item.coverImage]];
        if (![self imageFromCacheForKey:item.content]) {
            [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"Error：图片的高清图也没有加载到缓存:%@", item.content]];
            return;
        }
    }
    UIViewController *currentVc = AFBrowserViewController.currentVc;
    if (currentVc) {
        if (item.type == AFBrowserItemTypeVideo) {
            NSString *url = [item.content isKindOfClass:NSString.class] ? item.content : [(NSURL *)item.content absoluteString];
            if (![url containsString:@"file://"] && ![AFDownloader videoPathWithUrl:item.content]) {
                [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"Error：视频没有加载完成，不展示浏览器:%@", item.content]];
                return;
            }
        }
        [currentVc presentViewController:self animated:YES completion:nil];
    } else {
        [AFBrowserLoaderProxy addLogString:[NSString stringWithFormat:@"Error：找不到CurrentVc，无法跳转:%@", UIApplication.sharedApplication.keyWindow]];
    }
}

/// 查询是否有图片缓存
- (UIImage *)imageFromCacheForKey:(id)key {
    if ([key isKindOfClass:NSString.class] || [key isKindOfClass:NSURL.class]) {
        NSString *keyString = [key isKindOfClass:NSString.class] ? key : [(NSURL *)key absoluteString];
        return [AFBrowserLoaderProxy imageFromCacheForKey:keyString];
    }
    return key;
}


#pragma mark - 获取 currentVc
+ (UIViewController *)currentVc {
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    if ([window.superview isKindOfClass:UIWindow.class]) {
        while (!window.rootViewController && [window.superview isKindOfClass:UIWindow.class]) {
            window = (UIWindow *)window.superview;
        }
    } else {
        for (UIWindow *subWindow in window.subviews) {
            if ([subWindow isKindOfClass:UIWindow.class] && subWindow.rootViewController && !subWindow.hidden && subWindow.alpha > 0) {
                window = subWindow;
            }
        }
    }
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


#pragma mark - 完成转场，刷新UI
- (void)finishedTransaction {
    self.isFinishedTransaction = YES;
    [self.collectionView reloadData];
}



@end




