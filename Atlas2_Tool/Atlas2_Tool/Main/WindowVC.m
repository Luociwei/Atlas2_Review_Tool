//
//  WindowVC.m
//  DfuDebugTool
//
//  Created by ciwei luo on 2021/2/28.
//  Copyright © 2021 Suncode. All rights reserved.
//

#import "WindowVC.h"
#import "AtlasLogVC.h"
#import "CatchFwVc.h"
#import "AtlasScritVC.h"

#import "FailOnlyItems.h"

@interface WindowVC ()

@property (weak) IBOutlet NSImageView *isMixReadyImage;

@property (strong,nonatomic)CatchFwVc *catchFwVc;
@property (strong,nonatomic)AtlasScritVC *atlasScritVC;
@property (strong,nonatomic)AtlasLogVC *atlasCsvLogVC;

@end

@implementation WindowVC


- (IBAction)atlasLog:(id)sender {
    
    NSString *user_path = [NSString cw_getUserPath];
    
    [Task cw_openFileWithPath:[NSString stringWithFormat:@"%@/Library/Atlas2/Assets/",user_path]];
}

- (IBAction)stop:(NSButton *)sender {
    
    NSAlert *alert = [[NSAlert alloc]init];
    [alert setInformativeText:@"Are you sure stop atlas2."];
//    [alert setMessageText:prompt];
    [alert addButtonWithTitle:@"YES"];
    [alert addButtonWithTitle:@"NO"];
//    NSSecureTextField *input = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
//    [input setStringValue:defaultValue];
//    [alert setAccessoryView:input];
    NSInteger button = [alert runModal];
    if (button == NSAlertFirstButtonReturn) {
//        [input validateEditing];
//        return [input stringValue];
        NSString *path = [[NSBundle mainBundle] pathForResource:@"stopAtlas2.command" ofType:nil];
        
        [Task cw_openFileWithPath:path];
    } else {
//        return nil;
    }
    

}

- (IBAction)start:(NSButton *)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"startAtlas2.command" ofType:nil];
    
    [Task cw_openFileWithPath:path];
}

- (IBAction)sublime:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"SublimeText.app" ofType:nil];

    [Task cw_openFileWithPath:path];

    
}

- (IBAction)textWranglerClick:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"TextWrangler.app" ofType:nil];
    
    [Task cw_openFileWithPath:path];
}


- (IBAction)CatchFW:(NSButton *)sender {
    
    [self.catchFwVc showViewOnViewController:self.contentViewController];
}


- (void)windowDidLoad {
    [super windowDidLoad];
    
    _atlasCsvLogVC =  [[AtlasLogVC alloc] init];
    _atlasCsvLogVC.title = @"AtlasLog";
    
    _atlasScritVC =  [[AtlasScritVC alloc] init];
    _atlasScritVC.title = @"AtlasScript";

    [self cw_addViewControllers:@[_atlasScritVC,_atlasCsvLogVC]];
//    FailOnlyItems *item =  [[FailOnlyItems alloc] init];
//    item.title = @"AtlasLog";
//
//    [self cw_addViewControllers:@[item]];
   
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
