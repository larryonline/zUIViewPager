//
//  zUIViewPagerController.h
//  zUIViewPager
//
//  Created by ZhangZhenNan on 16/3/22.
//  Copyright © 2016年 zhennan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class zUIViewPagerController;
@protocol zUIViewPagerControllerDataSource <NSObject>

/**
 * Asks dataSource how many tabs will there be.
 * 
 * @param viewPagerController the viewPagerContrler that's subject to
 *
 * @return Number of tabs
 **/
-(NSUInteger)numberOfTabsForViewPagerController:(zUIViewPagerController *)viewPagerController;

/**
 * Asks dataSource to give a view to display as a tab item.
 * It is suggested to return a view with a clear Color background.
 * so that un/selected states can be clearly seen.
 *
 * @param viewPagerController The viewPager that's subject to.
 * @param index The index of the tab whose view is asked.
 *
 * @return A view that will be shown as tab at the given index
 *
 **/
-(UIView *)viewPagerController:(zUIViewPagerController *)viewPagerController
             viewForTabAtIndex:(NSUInteger)index;

/**
 * the content for any tab. Return a view controller and ViewPager will use it's view to show as content.
 *
 * @param viewPagerController the viewPagerController that's subject to.
 * @param index the index of the content whose view is asked
 *
 * @return A viewController whose view will be shown as content.
 **/
-(UIViewController *)viewPagerController:(zUIViewPagerController *)viewPagerController
      contentViewControllerForTabAtIndex:(NSUInteger)index;

@optional

/**
 * The tab view background color.
 **/
-(UIColor *)colorOfTabsBackgroundForViewPagerController:(zUIViewPagerController *)viewPagerController;

/**
 * The height of tab view
 **/
-(CGFloat)heightOfTabsForViewPagerController:(zUIViewPagerController *)viewPagerController;

/**
 * the tab indicator color
 **/
-(UIColor *)colorOfTabIndicatorForViewPagerController:(zUIViewPagerController *)viewPagerController
                                             forIndex:(NSUInteger)index;

/**
 * The width of tab view
 **/
-(CGFloat)viewPagerController:(zUIViewPagerController *)viewPagerController
       widthForTabViewAtIndex:(NSUInteger)index;

/**
 * delegate object must implement this method if wants to be change the tab appearance when state changed.
 **/
-(void)viewPagerController:(zUIViewPagerController *)viewPagerController
       updateTabAppearence:(UIView *)tab
                   atIndex:(NSInteger)index;

@end

@protocol zUIViewPagerControllerDelegate <NSObject>

@optional

/**
 * delegate object must implement this method if wants to be informed when a tab changes
 *
 * @param viewPagerController The viewPager that's subject to
 * @param fromIndex The index of the deactive tab
 * @param toIndex The index of the active tab
 */
-(void)viewPagerController:(zUIViewPagerController *)viewPagerController
     didChangeTabFromIndex:(NSUInteger)fromIndex
                   toIndex:(NSInteger)toIndex;

@end

@interface zUIViewPagerController : UIViewController
/**
 * The object that acts as the data source of the receiving viewPagerController
 * @discussion The data source must adopt the zUIViewPagerControllerDataSource protocol. The data source is not retained.
 */
@property (nonatomic, weak) id<zUIViewPagerControllerDataSource> dataSource;

/**
 * The object that acts as the delegate of the receiving viewPagerController
 * @discussion The delegate must adopt the zUIViewPagerControllerDelegate protocol. The delegate is not retained.
 */
@property (nonatomic, weak) id<zUIViewPagerControllerDelegate> delegate;

/**
 * Selected tab index.
 **/
@property (nonatomic, assign, readonly) NSUInteger selectedIndex;

/**
 * Reloads all tabs and contents
 **/
-(void)reloadData;

/**
 * Selects the given tab and shows the content at this index.
 * 
 * @param index The index of the tab that will be selected
 **/
-(void)selectTabAtIndex:(NSUInteger)index;

/**
 * Reload the appearance of the tabs view.
 * 
 * Adjests tabs width. height. stats etc..
 * Without implementing the - viewPagerController: updateTabAppearence: atIndex: delegate method,
 * this method does nothing.
 **/
-(void)setNeedUpdateTabs;
@end
