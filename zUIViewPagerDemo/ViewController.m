//
//  ViewController.m
//  zUIViewPager
//
//  Created by ZhangZhenNan on 16/3/22.
//  Copyright © 2016年 zhennan. All rights reserved.
//

#import "ViewController.h"
@interface ViewController ()<zUIViewPagerControllerDataSource, zUIViewPagerControllerDelegate, UITableViewDataSource, UITableViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.delegate = self;
    self.dataSource = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - delegate / datasource

-(NSUInteger)numberOfTabsForViewPagerController:(zUIViewPagerController *)viewPagerController{
    return 5;
}

-(UIView *)viewPagerController:(zUIViewPagerController *)viewPagerController viewForTabAtIndex:(NSUInteger)index{
    UILabel *label = [UILabel new];
    label.text = [NSString stringWithFormat:@"%ld", index];
    return label;
}

-(UIViewController *)viewPagerController:(zUIViewPagerController *)viewPagerController contentViewControllerForTabAtIndex:(NSUInteger)index{
    UITableViewController *controller = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    controller.tableView.delegate = self;
    controller.tableView.dataSource = self;
    return controller;
}

#pragma mark - delegate / datasource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 99;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if(nil == cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%ld", indexPath.row];
    return cell;
}

@end
