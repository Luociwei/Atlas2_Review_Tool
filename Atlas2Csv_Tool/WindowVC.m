//
//  WindowVC.m
//  DfuDebugTool
//
//  Created by ciwei luo on 2021/2/28.
//  Copyright © 2021 macdev. All rights reserved.
//

#import "WindowVC.h"

#import <CwGeneralManagerFrameWork/TextView.h>
#import <CwGeneralManagerFrameWork/Task.h>
#import <CwGeneralManagerFrameWork/Image.h>
#import <CwGeneralManagerFrameWork/FileManager.h>

#import "AtlasLogVC.h"
#import "CatchFwVc.h"

@interface WindowVC ()

@property (weak) IBOutlet NSImageView *isMixReadyImage;

@property (strong,nonatomic)CatchFwVc *catchFwVc;

@property (strong,nonatomic)AtlasLogVC *atlasCsvLogVC;

@end

@implementation WindowVC

- (IBAction)sublime:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"SublimeText.app" ofType:nil];

    [Task termialWithCmd:[NSString stringWithFormat:@"open %@",path]];

    
}

- (IBAction)textWranglerClick:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"TextWrangler.app" ofType:nil];
    
    [Task termialWithCmd:[NSString stringWithFormat:@"open %@",path]];
}


- (IBAction)CatchFW:(NSButton *)sender {
    
    [self.catchFwVc showViewOnViewController:self.contentViewController];
}


- (void)windowDidLoad {
    [super windowDidLoad];
   
    _atlasCsvLogVC =  [[AtlasLogVC alloc] init];
    _atlasCsvLogVC.title = @"AtlasLog";
    
    
    _catchFwVc =[[CatchFwVc alloc]init];
    _catchFwVc.title = @"DFU_CatchFW";
    [self cw_addViewControllers:@[_atlasCsvLogVC,_catchFwVc]];
    
//    [self getMixSate];
}





-(void)setImageWithImageView:(NSImageView *)imageView icon:(NSString *)icon{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
//        if ([icon containsString:@"off"]) {
//            [imageView setImage:[NSImage imageNamed:@"NSTouchBarCommunicationAudioTemplate"]];
//        }else if([icon containsString:@"error"]){
//            [imageView setImage:[Image cw_getRedCircleImage]];
//        }else{
//            [imageView setImage:[Image cw_getGreenCircleImage]];
//        }
        //        [imageView setImage:[NSImage imageNamed:icon]];
        [self.isMixReadyImage setImage:[NSImage imageNamed:icon]];
        
    });
}



-(PresentViewController *)catchFwVc{
    if (!_catchFwVc) {
        _catchFwVc =[[CatchFwVc alloc]init];
    }
    return _catchFwVc;
}
@end
