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
//#import "RegularVC.h"

#import "RegularTabVC.h"
@interface WindowVC ()
@property (weak) IBOutlet NSButton *atlasPathBtn;
@property (weak) IBOutlet NSButton *stopBtn;
@property (weak) IBOutlet NSButton *atlasLogBtn;
@property (weak) IBOutlet NSButton *mixLogBtn;
@property (weak) IBOutlet NSButton *startBtn;

@property (weak) IBOutlet NSImageView *isMixReadyImage;

@property (strong,nonatomic)CatchFwVc *catchFwVc;
@property (strong,nonatomic)AtlasScritVC *atlasScritVC;
@property (strong,nonatomic)AtlasLogVC *atlasCsvLogVC;
//@property (strong,nonatomic)RegularVC *regularVC;


@end

@implementation WindowVC


- (IBAction)atlas2Path:(id)sender {
    
    NSString *user_path = [NSString cw_getUserPath];
    
    [Task cw_openFileWithPath:[NSString stringWithFormat:@"%@/Library/Atlas2/Assets/",user_path]];
}
- (IBAction)mixPath:(NSButton *)sender {
//    NSString *user_path = [NSString cw_getUserPath];
    
    [Task cw_openFileWithPath:[NSString stringWithFormat:@"/vault/Atlas/FixtureLog/SunCode/"]];
}
- (IBAction)atlasLog:(id)sender {
    NSString *user_path = [NSString cw_getUserPath];
    
    [Task cw_openFileWithPath:[NSString stringWithFormat:@"%@/Library/Logs/Atlas/",user_path]];
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
        NSString *path = [[NSBundle mainBundle] pathForResource:@"2_off.command" ofType:nil];
        
        [Task cw_openFileWithPath:path];
    } else {
//        return nil;
    }
    

}

- (IBAction)start:(NSButton *)sender {
    NSAlert *alert = [[NSAlert alloc]init];
    [alert setInformativeText:@"Are you sure start atlas2."];
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
        NSString *path = [[NSBundle mainBundle] pathForResource:@"1_on.command" ofType:nil];
        
        [Task cw_openFileWithPath:path];
    } else {
        //        return nil;
    }
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"1_on.command" ofType:nil];
//    
//    [Task cw_openFileWithPath:path];
}
- (IBAction)converter:(NSButton *)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"CSV_Converter.app" ofType:nil];
    
    [Task cw_openFileWithPath:path];
}

- (IBAction)sublime:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"SublimeText.app" ofType:nil];

    [Task cw_openFileWithPath:path];

    
}

- (IBAction)debugSn:(NSButton *)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"sn.txt" ofType:nil];
    
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
    
//    NSString *s1 =@"Regular";
//    NSString *s2 =@"2021-09-22 09:47:46";
//    
    RegularTabVC *regularVC =  [[RegularTabVC alloc] init];
    regularVC.title = @"Regular";
    
    _atlasCsvLogVC =  [[AtlasLogVC alloc] init];
    _atlasCsvLogVC.title = @"AtlasLog";
    
    _atlasScritVC =  [[AtlasScritVC alloc] init];
    _atlasScritVC.title = @"AtlasScript";

    [self cw_addViewControllers:@[_atlasCsvLogVC,_atlasScritVC,regularVC]];
//    FailOnlyItems *item =  [[FailOnlyItems alloc] init];
//    item.title = @"AtlasLog";
//
//    [self cw_addViewControllers:@[item]];
   
//    [self getMixSate];
    
    self.startBtn.toolTip = @"1_on.command";
    self.stopBtn.toolTip = @"2_off.command";
    self.atlasPathBtn.toolTip = @"/Users/gdlocal/Library/Atlas2/Assets/";
    self.atlasLogBtn.toolTip = @"/Users/gdlocal/Library/Logs/Atlas/";
    self.mixLogBtn.toolTip = @"/vault/Atlas/FixtureLog/";
    
    
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
