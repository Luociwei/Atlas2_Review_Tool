//
//  TabViewController.m
//  CwGeneralManagerFrameWork
//
//  Created by ciwei luo on 2021/2/28.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import "TabViewController.h"

@implementation TabViewController

-(void)viewDidLoad{
    [super viewDidLoad];
//    self.view.frame = CGRectMake(0, 0, 668, 694);
}

-(void)addViewControllers:(NSArray<NSViewController *> *)viewControllerArr{
    for (NSViewController *vc in viewControllerArr) {
        [self addChildViewController:vc];
    }
}

@end
