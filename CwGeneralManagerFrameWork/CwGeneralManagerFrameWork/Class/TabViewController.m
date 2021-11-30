//
//  TabViewController.m
//  CwGeneralManagerFrameWork
//
//  Created by ciwei luo on 2021/2/28.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import "TabViewController.h"

@interface TabViewController ()
@property (nonatomic,strong)NSViewController *mainVc;

@end

@implementation TabViewController

-(void)viewDidLoad{
    [super viewDidLoad];

    self.title = [NSStringFromClass([self class]) stringByReplacingOccurrencesOfString:@"VC" withString:@""];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(windowWillClose:)
//                                                 name:NSWindowWillCloseNotification
//                                               object:nil];
}

-(void)addViewControllers:(NSArray<NSViewController *> *)viewControllerArr{
    for (NSViewController *vc in viewControllerArr) {
        [self addChildViewController:vc];
    }
}



-(void)removeAllChildViewController{

    for (int i =0; i<self.childViewControllers.count; i++) {
        [self removeChildViewControllerAtIndex:i];
        
    }

}

-(void)viewDidDisappear{
    [super viewDidDisappear];
    self.isActive = NO;
//    [self removeNSWindowWillCloseNotificationObserver];
}


-(void)viewDidAppear{
    [super viewDidAppear];
    self.isActive = YES;
    //    [[NSNotificationCenter defaultCenter] addObserver:self
    //                                             selector:@selector(windowWillClose:)
    //                                                 name:NSWindowWillCloseNotification
    //                                               object:nil];
}

-(void)dismisssViewOnViewController:(NSViewController *)vc{
    [vc dismissViewController:self];
    
    
}
//
-(void)showViewOnViewController:(NSViewController *)vc{
    _mainVc = vc;
    [vc presentViewControllerAsModalWindow:self];
    // [vc presentViewControllerAsSheet:self];

}
-(void)showViewAsSheetOnViewController:(NSViewController *)vc{
    _mainVc = vc;
    [vc presentViewControllerAsSheet:self];
}
//- (void)windowWillClose:(NSNotification *)notification {
//    [self close];
//}
//
-(void)close{
    self.isActive = NO;
    [_mainVc dismissViewController:self];

}
//
//-(void)dealloc{
//    [self removeNSWindowWillCloseNotificationObserver];
//
//}
//
//-(void)removeNSWindowWillCloseNotificationObserver{
//    [[NSNotificationCenter defaultCenter]removeObserver:self name:NSWindowWillCloseNotification object:nil];
//}
//-(NSMutableArray *)viewControllerArr{
//    if (_viewControllerArr == nil) {
//        _viewControllerArr = [[NSMutableArray alloc]init];
//    }
//    return _viewControllerArr;
//}

@end
