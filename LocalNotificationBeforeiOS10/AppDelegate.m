//
//  AppDelegate.m
//  Notifications
//
//  Created by Jacob_Liang on 2017/9/19.
//  Copyright © 2017年 Jacob. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    //如果已经获得发送通知的授权则创建本地通知，否则请求授权(注意：如果不请求授权在设置中是没有对应的通知设置项的，也就是说如果从来没有发送过请求，即使通过设置也打不开消息允许设置)
    if ([[UIApplication sharedApplication] currentUserNotificationSettings].types != UIUserNotificationTypeNone) {
        [self addLocalNotification];
    } else {
        //iOS 8 请求用户通知权限
        if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
            UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge | UIUserNotificationTypeAlert | UIUserNotificationTypeSound categories:nil];
            [application registerUserNotificationSettings:settings];
            //在请求权限弹出的 Alert 选择中，用户选择 "好"时，会回调 application:didRegisterUserNotificationSettings:方法
        }
    }
    
    /*
     iOS 10 之前点击本地通知，从后台唤醒或启动 App 时在这个方法的 Options里获取 本地通知的 UserInfo;
     */
    UILocalNotification *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    NSLog(@"%s  -- %@", __func__, notification);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self showInfo:[NSString stringWithFormat:@"%s  -- %@", __func__, notification]];
    });
    
    return YES;
}

#pragma mark - 添加本地通知
- (void)addLocalNotification {
    
    //定义本地通知对象
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    //设置调用时间
    notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:10.0];//通知触发的时间，10s以后
    notification.repeatInterval = 0;//通知重复间隔,其是一个 option 值， 0表示不重复，即 fire 之后就 discard 该 notification,即不会被copy 进scheduledLocalNotifications数组里。
    //notification.repeatCalendar = [NSCalendar currentCalendar];//当前日历，使用前最好设置时区等信息以便能够自动同步时间
    
    //设置通知属性
    notification.alertBody = @"最近添加了诸多有趣的特性，是否立即体验？"; //通知主体
    notification.applicationIconBadgeNumber = 1;//应用程序图标右上角显示的消息数
    notification.alertAction = @"打开应用"; //待机界面的滑动动作提示
    notification.alertLaunchImage = @"Default";//通过点击通知打开应用时的启动图片,这里使用程序启动图片
    //notification.soundName = UILocalNotificationDefaultSoundName;//收到通知时播放的声音，默认消息声音
    notification.soundName = @"msg.caf";//通知声音（需要真机才能听到声音）
    
    //设置用户信息
    notification.userInfo = @{@"id":@1234, @"user":@"Jacob"};//绑定到通知上的其他附加信息
    
    //调用通知
    [[UIApplication sharedApplication] scheduleLocalNotification:notification]; //scheduleLocalNotification 方法会对 notification 对象进行 copy ，所以需要手动 release 该 notification 对象。
    
    //    [[UIApplication sharedApplication] presentLocalNotificationNow:notification]; //立即发送本地通知，会调用 application:didReceiveLocalNotification：处理通知
    
}

//iOS 9 之后，点击本地通知，从后台唤醒 App 或 启动 App会调用如下方法
-(void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)())completionHandler {
    
    if ([identifier isEqualToString:@"打开应用"]) {
        [self showInfo:identifier];
    }
    
    completionHandler();
}

// APP在前台运行中收到 本地通知 时调用
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    // 可根据notification对象的userInfo等属性进行相应判断和处理
    NSLog(@"%s --- %@", __func__, notification);
}

//调用过用户注册通知方法之后执行（也就是调用完registerUserNotificationSettings:方法之后执行）
-(void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    
    if (notificationSettings.types != UIUserNotificationTypeNone) {
        [self addLocalNotification];
    }
}



- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];//进入前台取消应用消息图标
    
    //获取本地通知数组
    NSArray *notifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
    for (int i = 0; i < notifications.count; i++) {
        UILocalNotification *notificaiton = notifications[i];
        NSLog(@"%@ \n", notificaiton);
    }
}



#pragma mark - 移除本地通知，在不需要此通知时记得移除
- (void)removeNotification {
    
    //获取本地通知数组 (该数组会持有需要重复 fired 的 已被 copy 的 notification 对象，用于到达下次间隔时再 fire, 如果不需要重复的 notification，即 notification.repeatInterval = 0 的话，该 notification fire 之后不会被 copy 保留到这个数组里)
    //本地通知最多只能有64个，超过会被系统忽略
    NSArray *notifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
    NSLog(@"%@",notifications);
    
    //删除指定通知
    //    [[UIApplication sharedApplication] cancelLocalNotification:notifications[0]];
    //删除所有通知
    //    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    /*
     执行取消本地通知的场景：
     1. 已经响应过的本地通知，需要取消。
     2. 已经递交到 application 的，但在 fire 之前 确定要取消的通知，需要取消。如提醒任务的取消，或更改提醒时间（此时应该是新的一个本地通知了）
     */
}

- (void)showInfo:(NSString *)infoStr {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:infoStr preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:NULL]];
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
}

@end
