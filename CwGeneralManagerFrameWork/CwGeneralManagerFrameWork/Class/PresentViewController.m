//
//  ModalViewController.m
//  CPK_Tool
//
//  Created by Louis Luo on 2021/6/24.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import "PresentViewController.h"

@interface PresentViewController ()
@property (nonatomic,strong)NSViewController *mainVc;
@end

@implementation PresentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    self.title = [NSStringFromClass([self class]) stringByReplacingOccurrencesOfString:@"VC" withString:@""];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(windowWillClose:)
//                                                 name:NSWindowWillCloseNotification
//                                               object:nil];
}


-(void)viewDidAppear{
    [super viewDidAppear];
    self.isActive = YES;
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(windowWillClose:)
//                                                 name:NSWindowWillCloseNotification
//                                               object:nil];
}

-(void)viewDidDisappear{
    [super viewDidDisappear];
    self.isActive = NO;
//    [self removeNSWindowWillCloseNotificationObserver];
}

-(void)dismisssViewOnViewController:(NSViewController *)vc{
    dispatch_async(dispatch_get_main_queue(), ^{
        [vc dismissViewController:self];
        
    });
    
}

-(void)showViewOnViewController:(NSViewController *)vc{
    dispatch_async(dispatch_get_main_queue(), ^{
        _mainVc = vc;
        [vc presentViewControllerAsModalWindow:self];
        
    });

   // [vc presentViewControllerAsSheet:self];

}
-(void)showViewAsSheetOnViewController:(NSViewController *)vc{
    dispatch_async(dispatch_get_main_queue(), ^{
        _mainVc = vc;
        [vc presentViewControllerAsSheet:self];
        
    });
    
    
}
//- (void)windowWillClose:(NSNotification *)notification {
//    [self close];
//}

-(void)close{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.isActive = NO;
        [_mainVc dismissViewController:self];
        
    });
    
}

//-(void)dealloc{
//
//    [self removeNSWindowWillCloseNotificationObserver];
//
//}
//
//-(void)removeNSWindowWillCloseNotificationObserver{
//    [[NSNotificationCenter defaultCenter]removeObserver:self name:NSWindowWillCloseNotification object:nil];
//}


@end
