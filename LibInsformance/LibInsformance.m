//
//  LibInsformance.m
//  LibInsformance
//
//  Created by null on 15-3-11.
//  Copyright (c) 2015年 nonstriater. All rights reserved.
//

#import "LibInsformance.h"
#import <UIKit/UIKit.h>
#import "JDStatusBarNotification.h"
#import "UIDevice+software.h"

@interface LibInsformance (){
    int frameCounter;
    int maxFrameCounter;
    int tickCounter;//每隔0.5s更新一次
    CFTimeInterval *frameTimeBuffer;
    CFTimeInterval lastFrameStartTime;
    CADisplayLink *timerDisplayLink;
}

@end

@implementation LibInsformance

- (instancetype)init{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appLaunched:) name:UIApplicationDidBecomeActiveNotification object:nil];
        maxFrameCounter = 90;// 90/60=1.5s延迟
        frameTimeBuffer = malloc(sizeof(CFTimeInterval)*maxFrameCounter);
        frameCounter = 0;
        tickCounter = 0;
        lastFrameStartTime = CFAbsoluteTimeGetCurrent();
    }
    return self;
}

- (void)appLaunched:(NSNotification *)notification{

    NSLog(@"======================= libInsformance dylib show ========================");
    
    if (!timerDisplayLink) {
        timerDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update:)];
        [timerDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];//如果使用default mode，table滚动时不会更新s
    }
}

- (void)update:(CADisplayLink *)timer{
    //https://github.com/RolandasRazma/RRFPSBar
    
    
    //shift buffer
    for (int i=frameCounter; i>0; i--) {
        frameTimeBuffer[i]=frameTimeBuffer[i-1];
    }
    
    // store frameTimeBuffer[0]
    frameTimeBuffer[0] = timer.timestamp - lastFrameStartTime;
    
    if (frameCounter<maxFrameCounter-1) {
        frameCounter ++;
    }
    
    tickCounter ++;
    
    lastFrameStartTime = timer.timestamp;
    
   // 计算最低和平均fps,每隔0.5s更新一次
    if(tickCounter%30 == 0){
        tickCounter = 0;
        CFTimeInterval maxFrameTime = CGFLOAT_MIN;
        CFTimeInterval averFrameTime = 0.f;
        for (int i=0; i<frameCounter; i++) {
            maxFrameTime = MAX(maxFrameTime, frameTimeBuffer[i]);
            averFrameTime += frameTimeBuffer[i];
        }
        averFrameTime /= frameCounter;
        
        int averFPS = roundf(1.f/(float)averFrameTime);
        int lowestFPS = roundf(1.f/(float)maxFrameTime);
        NSString *pInfo = [NSString stringWithFormat:@"M:%.2lfM  C:%.2lf%%  FPS:%d/%d",[UIDevice usedMemery],[UIDevice CPUUsage],lowestFPS,averFPS];
        [JDStatusBarNotification showWithStatus:pInfo styleName:JDStatusBarStyleDark];
    }
    
}


static LibInsformance *instance= nil;
static void __attribute__((constructor)) initialize(void){

    NSLog(@"======================= libInsformance dylib initialize ========================");
    if (!instance) {
        instance = [[LibInsformance alloc] init];
    }
    
}




@end
