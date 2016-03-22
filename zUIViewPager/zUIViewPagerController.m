//
//  zUIViewPagerController.m
//  zUIViewPager
//
//  Created by ZhangZhenNan on 16/3/22.
//  Copyright © 2016年 zhennan. All rights reserved.
//

#import "zUIViewPagerController.h"

#pragma mark - Constants and macros
#define kTabViewTag 38
#define kTabContentViewTag 39
#define kContentViewTag 34
#define IOS_VERSION_7 [[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending

#define kTabHeight 44.0
#define kTabOffset 56.0
#define kTabWidth 128.0
#define kTabLocation 1.0
#define kStartFromSecondTab 0.0
#define kCenterCurrentTab 0.0
#define kFixFormerTabsPositions 0.0
#define kFixLatterTabsPositions 0.0

#define kIndicatorColor [UIColor colorWithRed:178.0/255.0 green:203.0/255.0 blue:57.0/255.0 alpha:0.75]
#define kTabsViewBackgroundColor [UIColor colorWithRed:234.0/255.0 green:234.0/255.0 blue:234.0/255.0 alpha:0.75]
#define kContentViewBackgroundColor [UIColor colorWithRed:248.0/255.0 green:248.0/255.0 blue:248.0/255.0 alpha:0.75]

#pragma mark - UIColor+Equality
@interface UIColor (Equality)
- (BOOL)isEqualToColor:(UIColor *)otherColor;
@end

@implementation UIColor (Equality)
// This method checks if two UIColors are the same
// Thanks to @samvermette for this method: http://stackoverflow.com/a/8899384/1931781
- (BOOL)isEqualToColor:(UIColor *)otherColor {
    
    CGColorSpaceRef colorSpaceRGB = CGColorSpaceCreateDeviceRGB();
    
    UIColor *(^convertColorToRGBSpace)(UIColor *) = ^(UIColor *color) {
        if (CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)) == kCGColorSpaceModelMonochrome) {
            const CGFloat *oldComponents = CGColorGetComponents(color.CGColor);
            CGFloat components[4] = {oldComponents[0], oldComponents[0], oldComponents[0], oldComponents[1]};
            return [UIColor colorWithCGColor:CGColorCreate(colorSpaceRGB, components)];
        } else {
            return color;
        }
    };
    
    UIColor *selfColor = convertColorToRGBSpace(self);
    otherColor = convertColorToRGBSpace(otherColor);
    CGColorSpaceRelease(colorSpaceRGB);
    
    return [selfColor isEqual:otherColor];
}
@end

#pragma mark - TabView
@class zUIViewPagerTabView;

@interface zUIViewPagerTabView : UIView
@property (nonatomic, getter = isSelected) BOOL selected;
@property (nonatomic) UIColor *indicatorColor;
@end

@implementation zUIViewPagerTabView
- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}
- (void)setSelected:(BOOL)selected {
    _selected = selected;
    // Update view as state changed
    [self setNeedsDisplay];
}
- (void)drawRect:(CGRect)rect {
    
    UIBezierPath *bezierPath;
    
    // Draw top line
    bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(0.0, 0.0)];
    [bezierPath addLineToPoint:CGPointMake(CGRectGetWidth(rect), 0.0)];
    [[UIColor colorWithWhite:197.0/255.0 alpha:0.75] setStroke];
    [bezierPath setLineWidth:1.0];
    [bezierPath stroke];
    
    // Draw bottom line
    bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(0.0, CGRectGetHeight(rect))];
    [bezierPath addLineToPoint:CGPointMake(CGRectGetWidth(rect), CGRectGetHeight(rect))];
    [[UIColor colorWithWhite:197.0/255.0 alpha:0.75] setStroke];
    [bezierPath setLineWidth:1.0];
    [bezierPath stroke];
    
    // Draw an indicator line if tab is selected
    if (self.selected) {
        
        bezierPath = [UIBezierPath bezierPath];
        
        // Draw the indicator
        [bezierPath moveToPoint:CGPointMake(0.0, CGRectGetHeight(rect) - 1.0)];
        [bezierPath addLineToPoint:CGPointMake(CGRectGetWidth(rect), CGRectGetHeight(rect) - 1.0)];
        [bezierPath setLineWidth:5.0];
        [self.indicatorColor setStroke];
        [bezierPath stroke];
    }
}
@end


@interface zUIViewPagerController ()<UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate>
// Tab and content stuff
@property UIScrollView *tabsView;
@property UIView *contentView;

@property UIPageViewController *pageViewController;
@property (assign) id<UIScrollViewDelegate> actualDelegate;

// Tab and content cache
@property NSMutableArray *tabs;
@property NSMutableArray *contents;
@property NSUInteger tabCount;

@property (nonatomic)  NSNumber *tabHeight;

@property (nonatomic) NSUInteger activeTabIndex;
@property (nonatomic) NSUInteger activeContentIndex;

@property (getter = isAnimatingToTab, assign) BOOL animatingToTab;
@property (getter = isDefaultSetupDone, assign) BOOL defaultSetupDone;
@end

@implementation zUIViewPagerController

-(id)initWithCoder:(NSCoder *)aDecoder{
    if(self = [super initWithCoder:aDecoder]){
        [self defaultSettings];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self defaultSettings];
    }
    return self;
}

#pragma mark - lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if(![self isDefaultSetupDone]){
        [self defaultSetup];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillLayoutSubviews{
    [self layoutSubviews];
}

#pragma mark - Interface rotation
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    // Re-layout sub views
    [self layoutSubviews];
    
    // Re-align tabs if needed
    self.activeTabIndex = self.activeTabIndex;
}

#pragma mark - public method



- (void)setActiveTabIndex:(NSUInteger)activeTabIndex {
    
    zUIViewPagerTabView *activeTabView;
    
    // Set to-be-inactive tab unselected
    activeTabView = [self tabViewAtIndex:self.activeTabIndex];
    activeTabView.selected = NO;
    
    // Set to-be-active tab selected
    activeTabView = [self tabViewAtIndex:activeTabIndex];
    activeTabView.selected = YES;
    
    // Set current activeTabIndex
    _activeTabIndex = activeTabIndex;
    
    // Bring tab to active position
    // Position the tab in center if centerCurrentTab option is provided as YES
    UIView *tabView = [self tabViewAtIndex:self.activeTabIndex];
    CGRect frame = tabView.frame;
    frame.size.width = CGRectGetWidth(self.tabsView.frame);
    
    [self.tabsView scrollRectToVisible:frame animated:YES];
}
- (void)setActiveContentIndex:(NSUInteger)activeContentIndex {
    
    // Get the desired viewController
    UIViewController *viewController = [self viewControllerAtIndex:activeContentIndex];
    
    if (!viewController) {
        viewController = [[UIViewController alloc] init];
        viewController.view = [[UIView alloc] init];
        viewController.view.backgroundColor = [UIColor clearColor];
    }
    
    // __weak pageViewController to be used in blocks to prevent retaining strong reference to self
    __weak UIPageViewController *weakPageViewController = self.pageViewController;
    __weak zUIViewPagerController *weakSelf = self;
    
    if (activeContentIndex == self.activeContentIndex) {
        
        [self.pageViewController setViewControllers:@[viewController]
                                          direction:UIPageViewControllerNavigationDirectionForward
                                           animated:NO
                                         completion:^(BOOL completed) {
                                             weakSelf.animatingToTab = NO;
                                         }];
        
    } else if (!(activeContentIndex + 1 == self.activeContentIndex || activeContentIndex - 1 == self.activeContentIndex)) {
        
        [self.pageViewController setViewControllers:@[viewController]
                                          direction:(activeContentIndex < self.activeContentIndex) ? UIPageViewControllerNavigationDirectionReverse : UIPageViewControllerNavigationDirectionForward
                                           animated:YES
                                         completion:^(BOOL completed) {
                                             
                                             weakSelf.animatingToTab = NO;
                                             
                                             // Set the current page again to obtain synchronisation between tabs and content
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 [weakPageViewController setViewControllers:@[viewController]
                                                                                  direction:(activeContentIndex < weakSelf.activeContentIndex) ? UIPageViewControllerNavigationDirectionReverse : UIPageViewControllerNavigationDirectionForward
                                                                                   animated:NO
                                                                                 completion:nil];
                                             });
                                         }];
        
    } else {
        
        [self.pageViewController setViewControllers:@[viewController]
                                          direction:(activeContentIndex < self.activeContentIndex) ? UIPageViewControllerNavigationDirectionReverse : UIPageViewControllerNavigationDirectionForward
                                           animated:YES
                                         completion:^(BOOL completed) {
                                             weakSelf.animatingToTab = NO;
                                         }];
    }
    
    // Clean out of sight contents
    NSInteger index;
    index = self.activeContentIndex - 1;
    if (index >= 0 &&
        index != activeContentIndex &&
        index != activeContentIndex - 1)
    {
        [self.contents replaceObjectAtIndex:index withObject:[NSNull null]];
    }
    index = self.activeContentIndex;
    if (index != activeContentIndex - 1 &&
        index != activeContentIndex &&
        index != activeContentIndex + 1)
    {
        [self.contents replaceObjectAtIndex:index withObject:[NSNull null]];
    }
    index = self.activeContentIndex + 1;
    if (index < self.contents.count &&
        index != activeContentIndex &&
        index != activeContentIndex + 1)
    {
        [self.contents replaceObjectAtIndex:index withObject:[NSNull null]];
    }
    
    _activeContentIndex = activeContentIndex;
}

-(NSUInteger)selectedIndex{
    return self.activeTabIndex;
}

-(void)selectTabAtIndex:(NSUInteger)index{
    if(index >= self.tabCount){
        return;
    }
    
    NSUInteger fromIndex = self.activeTabIndex;
    
    self.animatingToTab = YES;
    
    // Set activeTabIndex
    self.activeTabIndex = index;
    
    // Set activeContentIndex
    self.activeContentIndex = index;
    
    // Inform delegate about the change
    if ([self.delegate respondsToSelector:@selector(viewPagerController:didChangeTabFromIndex:toIndex:)]) {
        [self.delegate viewPagerController:self didChangeTabFromIndex:fromIndex toIndex:index];
    }
}

-(void)reloadData{
    
    // Empty all options and colors
    // So that, ViewPager will reflect the changes
    // Empty all options
    _tabHeight = nil;
    
    // Call to setup again with the updated data
    [self defaultSetup];
}

-(void)setNeedUpdateTabs{
    if(![self.dataSource respondsToSelector:@selector(viewPagerController:updateTabAppearence:atIndex:)]){
        return;
    }
    
    CGFloat contentSizeWidth = 0;
    for(NSUInteger i = 0; i < self.tabCount; i++){
        UIView *tabView = [self tabViewAtIndex:i];
        UIView *tabContentView = [tabView viewWithTag:kTabContentViewTag];
        [self.dataSource viewPagerController:self updateTabAppearence:tabContentView atIndex:i];
        
        [tabContentView sizeToFit];
        tabContentView.center = tabView.center;
        
        
        CGRect frame = tabView.frame;
        frame.origin.x = contentSizeWidth;
        frame.size.width = CGRectGetWidth([tabContentView frame]);
        tabView.frame = frame;
        
        contentSizeWidth += CGRectGetWidth(tabView.frame);
        
    }
    
    self.tabsView.contentSize = CGSizeMake(contentSizeWidth, [self.tabHeight floatValue]);
    
}

#pragma mark - private method

-(void)handleTapGesture:(id)sender{
    // Get the desired page's index
    UITapGestureRecognizer *tapGestureRecognizer = (UITapGestureRecognizer *)sender;
    UIView *tabView = tapGestureRecognizer.view;
    __block NSUInteger index = [self.tabs indexOfObject:tabView];
    
    //if Tap is not selected Tab(new Tab)
    if (self.activeTabIndex != index) {
        // Select the tab
        [self selectTabAtIndex:index];
    }
}

-(NSNumber *)tabHeight{
    if(nil == _tabHeight){
        CGFloat value = kTabHeight;
        
        if([self.dataSource respondsToSelector:@selector(heightOfTabsForViewPagerController:)]){
            value = [self.dataSource heightOfTabsForViewPagerController:self];
        }
        self.tabHeight = [NSNumber numberWithFloat:value];
    }
    return _tabHeight;
}



-(void)layoutSubviews{
    id<UILayoutSupport> topLayoutGuide = self.topLayoutGuide;
    id<UILayoutSupport> bottomLayoutGuide = self.bottomLayoutGuide;
    
    CGRect frame = [self.tabsView frame];
    frame.origin.x = 0.0;
    frame.origin.y = [topLayoutGuide length];
    frame.size.width = CGRectGetWidth(self.view.frame);
    frame.size.height = [self.tabHeight floatValue];
    self.tabsView.frame = frame;
    
    frame = self.contentView.frame;
    frame.origin.x = 0.0;
    frame.origin.y = [topLayoutGuide length] + CGRectGetHeight([self.tabsView frame]);
    frame.size.width = CGRectGetWidth(self.view.frame);
    frame.size.height = CGRectGetHeight(self.view.frame) - ([topLayoutGuide length] + CGRectGetHeight([self.tabsView frame])) - [bottomLayoutGuide length];
    self.contentView.frame = frame;
}

-(void)defaultSettings{
    // pageViewController
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                              navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                            options:nil];
    [self addChildViewController:self.pageViewController];
    
    // Setup some forwarding events to hijack the scrollView
    // Keep a reference to the actual delegate
    self.actualDelegate = ((UIScrollView *)[self.pageViewController.view.subviews objectAtIndex:0]).delegate;
    // Set self as new delegate
    ((UIScrollView *)[self.pageViewController.view.subviews objectAtIndex:0]).delegate = self;
    
    self.pageViewController.dataSource = self;
    self.pageViewController.delegate = self;
    
    self.animatingToTab = NO;
    self.defaultSetupDone = NO;
}

-(void)defaultSetup{
    
    // Empty tabs and contents
    for(UIView *tabView in self.tabs){
        [tabView removeFromSuperview];
    }
    self.tabsView.contentSize = CGSizeZero;
    
    // get tabs count from delegate
    if([self.dataSource respondsToSelector:@selector(numberOfTabsForViewPagerController:)]){
        self.tabCount = [self.dataSource numberOfTabsForViewPagerController:self];
    }
    
    // Clear tabs and contents
    [self.tabs removeAllObjects];
    [self.contents removeAllObjects];
    
    // Populate arrays with [NSNull null];
    self.tabs = [NSMutableArray arrayWithCapacity:self.tabCount];
    self.contents = [NSMutableArray arrayWithCapacity:self.tabCount];
    for(NSUInteger i = 0; i < self.tabCount; i++){
        [self.tabs addObject:[NSNull null]];
        [self.contents addObject:[NSNull null]];
    }
    
    // Add tab view
    self.tabsView = (UIScrollView *)[self.view viewWithTag:kTabViewTag];
    if(!self.tabsView){
        self.tabsView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), kTabHeight)];
        self.tabsView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.tabsView.backgroundColor = kTabsViewBackgroundColor;
        self.tabsView.scrollsToTop = NO;
        self.tabsView.showsHorizontalScrollIndicator = NO;
        self.tabsView.showsVerticalScrollIndicator = NO;
        self.tabsView.tag = kTabViewTag;
        
        [self.view insertSubview:self.tabsView atIndex:0];
    }
    
    // add tab views into tabsview
    CGFloat contentSizeWidth = 0;
    
    for(NSUInteger i = 0; i < self.tabCount; i++){
        UIView *tabView = [self tabViewAtIndex:i];
        
        CGRect frame = tabView.frame;
        frame.origin.x = contentSizeWidth;
        tabView.frame = frame;
        
        [self.tabsView addSubview:tabView];
        
        contentSizeWidth += CGRectGetWidth(tabView.frame);
        
        // to capture tap events
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
        [tabView addGestureRecognizer:tapGestureRecognizer];
    }
    

    self.tabsView.contentSize = CGSizeMake(contentSizeWidth, [self.tabHeight floatValue]);
    
    // add contentView
    self.contentView = [self.view viewWithTag:kContentViewTag];
    if(nil == self.contentView){
        self.contentView = self.pageViewController.view;
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.contentView.backgroundColor = kContentViewBackgroundColor;
        
        [self.view insertSubview:self.contentView atIndex:0];
    }
    
    // Select starting tab
    NSUInteger index = 0;
    [self selectTabAtIndex:index];
    
    // set setup done
    self.defaultSetupDone = YES;
}



-(zUIViewPagerTabView *)tabViewAtIndex:(NSUInteger)index{
    if(index >= self.tabCount){
        return nil;
    }
    
    if([[self.tabs objectAtIndex:index] isEqual:[NSNull null]]){
        // get view from data source
        UIView *tabViewContent = [self.dataSource viewPagerController:self viewForTabAtIndex:index];
        tabViewContent.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        tabViewContent.tag = kTabContentViewTag;
        [tabViewContent sizeToFit];
        
        // create tab view and subview the content
        CGFloat tabWidth = kTabWidth;
        if([self.dataSource respondsToSelector:@selector(viewPagerController:widthForTabViewAtIndex:)]){
            tabWidth = [self.dataSource viewPagerController:self widthForTabViewAtIndex:index];
        }
        
        zUIViewPagerTabView *tabView = [[zUIViewPagerTabView alloc] initWithFrame:CGRectMake(0, 0, tabWidth, [self.tabHeight floatValue])];
        [tabView addSubview:tabViewContent];
        [tabView setClipsToBounds:YES];
        
        UIColor *indicatorColor = kIndicatorColor;
        if([self.dataSource respondsToSelector:@selector(colorOfTabIndicatorForViewPagerController:forIndex:)]){
            indicatorColor = [self.dataSource colorOfTabIndicatorForViewPagerController:self forIndex:index];
        }
        
        [tabView setIndicatorColor:indicatorColor];
        tabViewContent.center = tabView.center;
        
        // Replace the null object with tabView
        [self.tabs replaceObjectAtIndex:index withObject:tabView];
    }
    return [self.tabs objectAtIndex:index];
}

-(NSUInteger)indexForTabView:(UIView *)tabView {
    
    return [self.tabs indexOfObject:tabView];
}

-(NSUInteger)indexForViewController:(UIViewController *)contentViewController{
    return [self.contents indexOfObject:contentViewController];
}

-(UIViewController *)viewControllerAtIndex:(NSUInteger)index {
    
    if (index >= self.tabCount) {
        return nil;
    }
    
    if ([[self.contents objectAtIndex:index] isEqual:[NSNull null]]) {
        
        UIViewController *viewController = nil;
        
        if ([self.dataSource respondsToSelector:@selector(viewPagerController:contentViewControllerForTabAtIndex:)]) {
            viewController = [self.dataSource viewPagerController:self contentViewControllerForTabAtIndex:index];
        } else {
            viewController = [[UIViewController alloc] init];
            viewController.view = [[UIView alloc] init];
        }
        
        [self.contents replaceObjectAtIndex:index withObject:viewController];
    }
    
    return [self.contents objectAtIndex:index];
}

#pragma mark - UIPageViewControllerDataSource
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSUInteger index = [self indexForViewController:viewController];
    index++;
    return [self viewControllerAtIndex:index];
}
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger index = [self indexForViewController:viewController];
    index--;
    return [self viewControllerAtIndex:index];
}

#pragma mark - UIPageViewControllerDelegate
- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    
    UIViewController *viewController = self.pageViewController.viewControllers[0];
    
    // Select tab
    NSUInteger index = [self indexForViewController:viewController];
    [self selectTabAtIndex:index];
}

#pragma mark - UIScrollViewDelegate, Responding to Scrolling and Dragging
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if ([self.actualDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [self.actualDelegate scrollViewDidScroll:scrollView];
    }
    
    if (![self isAnimatingToTab]) {
        UIView *tabView = [self tabViewAtIndex:self.activeTabIndex];
        
        // Get the related tab view position
        CGRect frame = tabView.frame;
        
        CGFloat movedRatio = (scrollView.contentOffset.x / CGRectGetWidth(scrollView.frame)) - 1;
        frame.origin.x += movedRatio * CGRectGetWidth(frame);
        frame.size.width = CGRectGetWidth(self.tabsView.frame);
        
        [self.tabsView scrollRectToVisible:frame animated:NO];
    }
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if ([self.actualDelegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
        [self.actualDelegate scrollViewWillBeginDragging:scrollView];
    }
}
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if ([self.actualDelegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)]) {
        [self.actualDelegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
    }
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if ([self.actualDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
        [self.actualDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}
- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView{
    if ([self.actualDelegate respondsToSelector:@selector(scrollViewShouldScrollToTop:)]) {
        return [self.actualDelegate scrollViewShouldScrollToTop:scrollView];
    }
    return NO;
}
- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    if ([self.actualDelegate respondsToSelector:@selector(scrollViewDidScrollToTop:)]) {
        [self.actualDelegate scrollViewDidScrollToTop:scrollView];
    }
}
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    if ([self.actualDelegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)]) {
        [self.actualDelegate scrollViewWillBeginDecelerating:scrollView];
    }
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([self.actualDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [self.actualDelegate scrollViewDidEndDecelerating:scrollView];
    }
}

#pragma mark - UIScrollViewDelegate, Managing Zooming
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if ([self.actualDelegate respondsToSelector:@selector(viewForZoomingInScrollView:)]) {
        return [self.actualDelegate viewForZoomingInScrollView:scrollView];
    }
    return nil;
}
- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    if ([self.actualDelegate respondsToSelector:@selector(scrollViewWillBeginZooming:withView:)]) {
        [self.actualDelegate scrollViewWillBeginZooming:scrollView withView:view];
    }
}
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    if ([self.actualDelegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)]) {
        [self.actualDelegate scrollViewDidEndZooming:scrollView withView:view atScale:scale];
    }
}
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if ([self.actualDelegate respondsToSelector:@selector(scrollViewDidZoom:)]) {
        [self.actualDelegate scrollViewDidZoom:scrollView];
    }
}

#pragma mark - UIScrollViewDelegate, Responding to Scrolling Animations
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if ([self.actualDelegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
        [self.actualDelegate scrollViewDidEndScrollingAnimation:scrollView];
    }
}


@end
