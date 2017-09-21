//
//  AppDelegate.m
//  Notifications
//
//  Created by Jacob_Liang on 2017/9/19.
//  Copyright © 2017年 Jacob. All rights reserved.
//

#import "AppDelegate.h"


static NSString * const kIGNOREKEY = @"IGNOREKEY";
static NSString * const kOPENACTIONKEY = @"OPENACTIONKEY";
static NSString * const kCATEGORYKEY = @"ALERTCATEGORY";

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
            
            //添加通知的动作
            UIMutableUserNotificationCategory *category = [self addLocalNotificationActions];
            
            UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge | UIUserNotificationTypeAlert | UIUserNotificationTypeSound categories:[NSSet setWithObject:category]];
            [application registerUserNotificationSettings:settings];
            //在请求权限弹出的 Alert 选择中，用户选择 "好"时，会回调 application:didRegisterUserNotificationSettings:方法
        }
    }
    
    /*
     iOS 10 之前点击本地通知，从后台唤醒或启动 App 时在这个方法的 Options里获取 本地通知的 UserInfo;
     */
    UILocalNotification *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    NSLog(@"%s  -- %@", __func__, notification);
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self showInfo:[NSString stringWithFormat:@"%s  -- %@", __func__, notification]];
//    });
    
    //test app teminate 后，响应本地通知的 backgroundmode 的 acton后，再次启动，如果有打印即证明，backgroundmode 的 acton的触发真的没有启动 App，但是会回调 Action 的方法；
    NSString *clickIgnoreActionStr = [[NSUserDefaults standardUserDefaults] objectForKey:kIGNOREKEY];
    if (clickIgnoreActionStr.length) {
        NSLog(@"%@",clickIgnoreActionStr);
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kIGNOREKEY];
    }
    
    
    return YES;
}

#pragma mark - 添加本地通知
- (void)addLocalNotification {
    
    //定义本地通知对象
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    //设置时区
    notification.timeZone = [NSTimeZone defaultTimeZone];
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
    //设定该通知的actions，actions确保已经添加到 category , 每一个 category 表示一种类型的 actions，也就说可以有很多类型的 category。但是 category 需要提前注册到 setting 中。
    notification.category = kCATEGORYKEY;
    
    //调用通知
    [[UIApplication sharedApplication] scheduleLocalNotification:notification]; //scheduleLocalNotification 方法会对 notification 对象进行 copy
    
    //    [[UIApplication sharedApplication] presentLocalNotificationNow:notification]; //立即发送本地通知，无视 notification 的 fireDate 属性值，会调用 application:didReceiveLocalNotification：处理通知
    
}

#pragma mark - 添加通知的动作
//添加通知的动作
- (UIMutableUserNotificationCategory *)addLocalNotificationActions {
    //UIMutableUserNotificationAction用来添加自定义按钮
    UIMutableUserNotificationAction * responseAction = [[UIMutableUserNotificationAction alloc] init];
    responseAction.identifier = kOPENACTIONKEY;
    responseAction.title = @"打开应用";
    responseAction.activationMode = UIUserNotificationActivationModeForeground; //点击的时候启动程序
    
    UIMutableUserNotificationAction *deleteAction = [[UIMutableUserNotificationAction alloc] init];
    deleteAction.identifier = kIGNOREKEY;
    deleteAction.title = @"忽略";
    deleteAction.activationMode = UIUserNotificationActivationModeBackground; //点击的时候不启动程序，后台处理
    deleteAction.authenticationRequired = YES;//需要解锁权限
    deleteAction.destructive = YES; //YES为红色，NO为蓝色
    
    UIMutableUserNotificationCategory *category = [[UIMutableUserNotificationCategory alloc] init];
    category.identifier = kCATEGORYKEY;//用于将该 category 标识的同时，那一个 notification 实例需要使用这个 category 的 actions 也是传入这个值给 notification 的。
    //UIUserNotificationActionContextDefault:默认添加可以添加两个自定义按钮
    //UIUserNotificationActionContextMinimal:四个自定义按钮
    [category setActions:@[responseAction, deleteAction] forContext:UIUserNotificationActionContextDefault];
    
    return category;
}

//iOS 8 ~ 9 ，当点击本地通知自定义的响应按钮(action btn)时，根据按钮的 activeMode 模式，回调以下方法
//1. ActivationModeForeground 的 action , 会启动 App 同时回调方法
//2. ActivationModeBackground 的 action 不启动 App 让 App 在 background 下回调方法
- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)())completionHandler {
    
    if ([identifier isEqualToString:kOPENACTIONKEY]) {
        //ActivationModeForeground 的 action , 启动 App 让 App 在 Foreground 下响应
        
        [self showInfo:[NSString stringWithFormat:@"thread -%@\n identifier -%@", [NSThread currentThread], identifier]];
        
    } else {
        
        //ActivationModeBackground 的 action 不启动 App 让 App 在 background 下响应
        NSLog(@"%s  -- %@  -- identifier %@ --- thread %@", __func__, notification, identifier, [NSThread currentThread]);
        
        //下面代码用于测试，退出 App 后接收到 本地通知时，点击后台action时是否执行了这个响应方法。实测执行了的
        [[NSUserDefaults standardUserDefaults] setObject:@"ActivationModeBackground 的 action 不启动 App 让 App 在 background 下响应" forKey:@"IGNOREKEY"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    }
    
    
    
    completionHandler(); //根据Action btn 的 identifier 处理自定义事件后应该马上调用 completionHandler block,如果调用 completionHandler block 失败的话，App 会立即 terminated。
}

//iOS 9 中带有 response 的方法，如果机器是 iOS 9系统只会调用带 response 的方法，
- (void)application:(UIApplication *)application handleActionWithIdentifier:(nullable NSString *)identifier forLocalNotification:(UILocalNotification *)notification withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void(^)())completionHandler {
    
    if ([identifier isEqualToString:kOPENACTIONKEY]) {
        //ActivationModeForeground 的 action , 启动 App 让 App 在 Foreground 下响应
        
        [self showInfo:[NSString stringWithFormat:@"thread -%@\n identifier -%@", [NSThread currentThread], identifier]];
        
    } else {
        
        //ActivationModeBackground 的 action 不启动 App 让 App 在 background 下响应
        NSLog(@"%s  -- %@  -- identifier %@ --- thread %@", __func__, notification, identifier, [NSThread currentThread]);
        
        //下面代码用于测试，退出 App 后接收到 本地通知时，点击后台action时是否执行了这个响应方法。实测执行了的
        [[NSUserDefaults standardUserDefaults] setObject:@"ActivationModeBackground 的 action 不启动 App 让 App 在 background 下响应" forKey:@"IGNOREKEY"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    }
    
    
    
    completionHandler();
    
}


// APP在前台运行中收到 本地通知 时调用, 以及App 处于后台挂起（suspended）状态，但未 terminated 时，点击通知启动都是这个方法进行响应
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
